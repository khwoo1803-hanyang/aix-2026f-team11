-- 장소 후보함과 공동 일정표 (활동지 #10)
-- 멤버가 장소를 후보함에 올리고 '좋아요'로 투표한 뒤, 일차별 일정에 넣고 순서를 바꾼다.
-- 모든 변경은 실시간으로 다른 멤버에게 전달된다.
-- Google 장소 검색(#9)은 나중에 붙인다. 그때 google_place_id, 주소, 좌표를 채운다.

-- 1. 장소 후보 ---------------------------------------------------------------

create table public.places (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  added_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 60),
  category text not null default 'etc' check (category in ('food', 'cafe', 'sight', 'stay', 'etc')),
  address text check (address is null or char_length(address) <= 200),
  memo text check (memo is null or char_length(memo) <= 200),
  google_place_id text,
  lat double precision check (lat is null or lat between -90 and 90),
  lng double precision check (lng is null or lng between -180 and 180),
  created_at timestamptz not null default now()
);

create unique index places_room_name_key on public.places (room_id, lower(trim(name)));
create index places_room_id_idx on public.places (room_id);

-- 2. 장소 좋아요 ------------------------------------------------------------
-- 한 사람이 장소마다 한 번만 누른다. 다시 누르면 지운다. room_id는 장소의 여행방으로 자동 설정한다.

create table public.place_votes (
  place_id uuid not null references public.places (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (place_id, user_id)
);

create index place_votes_room_id_idx on public.place_votes (room_id);

create function public.set_place_vote_room()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select room_id into new.room_id from public.places where id = new.place_id;
  return new;
end;
$$;

create trigger place_votes_set_room
  before insert on public.place_votes
  for each row execute function public.set_place_vote_room();

-- 3. 일차 -------------------------------------------------------------------

create table public.itinerary_days (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  day_number integer not null check (day_number between 1 and 30),
  created_at timestamptz not null default now(),
  unique (room_id, day_number)
);

-- 4. 일정 항목 ---------------------------------------------------------------
-- position은 일차 안의 순서(0부터). 순서 바꾸기는 reorder_itinerary 함수로 한 번에 한다.

create table public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  day_id uuid not null references public.itinerary_days (id) on delete cascade,
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  place_id uuid not null references public.places (id) on delete cascade,
  position integer not null default 0,
  visit_time time,
  memo text check (memo is null or char_length(memo) <= 200),
  created_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);

create index itinerary_items_room_id_idx on public.itinerary_items (room_id);
create index itinerary_items_day_position_idx on public.itinerary_items (day_id, position);

-- room_id는 일차의 여행방으로 채우고, 다른 여행방의 장소는 넣지 못하게 한다.
-- 새 항목은 그 일차의 맨 뒤에 붙인다.
create function public.prepare_itinerary_item()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select room_id into new.room_id from public.itinerary_days where id = new.day_id;
  if not exists (
    select 1 from public.places where id = new.place_id and room_id = new.room_id
  ) then
    raise exception 'place_not_in_room';
  end if;
  if tg_op = 'INSERT' then
    select coalesce(max(position) + 1, 0) into new.position
    from public.itinerary_items where day_id = new.day_id;
  end if;
  return new;
end;
$$;

create trigger itinerary_items_prepare
  before insert or update of day_id, place_id on public.itinerary_items
  for each row execute function public.prepare_itinerary_item();

-- 일차 안의 항목 순서를 ordered_ids 순서대로 한 번에 바꾼다.
create function public.reorder_itinerary(target_day uuid, ordered_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  day_room uuid;
begin
  select room_id into day_room from public.itinerary_days where id = target_day;
  if day_room is null or not public.is_room_member(day_room) then
    raise exception 'not_room_member';
  end if;
  if (
    select count(*) from public.itinerary_items where day_id = target_day
  ) <> coalesce(array_length(ordered_ids, 1), 0)
  or exists (
    select 1 from unnest(ordered_ids) as given(id)
    where not exists (
      select 1 from public.itinerary_items i where i.id = given.id and i.day_id = target_day
    )
  ) then
    raise exception 'order_out_of_date';
  end if;

  update public.itinerary_items i
  set position = given.ordinality - 1
  from unnest(ordered_ids) with ordinality as given(id, ordinality)
  where i.id = given.id and i.position is distinct from given.ordinality - 1;
end;
$$;

revoke execute on function public.reorder_itinerary(uuid, uuid[]) from public, anon;
grant execute on function public.reorder_itinerary(uuid, uuid[]) to authenticated;

-- 5. RLS ---------------------------------------------------------------------

alter table public.places enable row level security;
alter table public.place_votes enable row level security;
alter table public.itinerary_days enable row level security;
alter table public.itinerary_items enable row level security;

create policy "멤버만 장소 조회"
  on public.places for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 장소 등록"
  on public.places for insert to authenticated
  with check (added_by = (select auth.uid()) and public.is_room_member(room_id));

create policy "올린 사람만 장소 수정"
  on public.places for update to authenticated
  using (added_by = (select auth.uid()))
  with check (added_by = (select auth.uid()) and public.is_room_member(room_id));

create policy "올린 사람만 장소 삭제"
  on public.places for delete to authenticated
  using (added_by = (select auth.uid()));

create policy "멤버만 좋아요 조회"
  on public.place_votes for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 좋아요"
  on public.place_votes for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_room_member(room_id));

create policy "본인 좋아요만 취소"
  on public.place_votes for delete to authenticated
  using (user_id = (select auth.uid()));

create policy "멤버만 일차 조회"
  on public.itinerary_days for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 일차 추가"
  on public.itinerary_days for insert to authenticated
  with check (public.is_room_member(room_id));

create policy "멤버만 일차 삭제"
  on public.itinerary_days for delete to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 일정 조회"
  on public.itinerary_items for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 일정 추가"
  on public.itinerary_items for insert to authenticated
  with check (created_by = (select auth.uid()) and public.is_room_member(room_id));

create policy "멤버만 일정 수정"
  on public.itinerary_items for update to authenticated
  using (public.is_room_member(room_id))
  with check (public.is_room_member(room_id));

create policy "멤버만 일정 삭제"
  on public.itinerary_items for delete to authenticated
  using (public.is_room_member(room_id));

-- Supabase는 새 테이블에 모든 권한을 기본으로 주므로 먼저 거두고 필요한 것만 다시 준다.
revoke all on public.places, public.place_votes, public.itinerary_days, public.itinerary_items
  from anon, authenticated;
grant select, insert, update, delete on public.places to authenticated;
grant select, insert, delete on public.place_votes to authenticated;
grant select, insert, delete on public.itinerary_days to authenticated;
grant select, insert, delete on public.itinerary_items to authenticated;
-- 일정은 방문 시간과 메모만 직접 고치고, 순서는 reorder_itinerary로만 바꾼다.
grant update (visit_time, memo) on public.itinerary_items to authenticated;

alter publication supabase_realtime
  add table public.places, public.place_votes, public.itinerary_days, public.itinerary_items;
