-- 여행지 후보와 투표
-- 멤버는 후보를 최대 2개 올리고, 후보마다 찬성·보통·반대 중 하나로 투표한다.
-- 찬성이 과반인 후보만 방장이 confirm_destination 함수로 확정할 수 있다.

-- 1. 여행지 후보 -----------------------------------------------------------

create table public.destinations (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  proposed_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 40),
  reason text check (reason is null or char_length(reason) <= 200),
  created_at timestamptz not null default now()
);

create unique index destinations_room_name_key on public.destinations (room_id, lower(trim(name)));
create index destinations_room_id_idx on public.destinations (room_id);

create function public.enforce_destination_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (
    select count(*) from public.destinations
    where room_id = new.room_id and proposed_by = new.proposed_by
  ) >= 2 then
    raise exception 'destination_limit';
  end if;
  return new;
end;
$$;

create trigger destinations_limit
  before insert on public.destinations
  for each row execute function public.enforce_destination_limit();

-- 2. 투표 --------------------------------------------------------------------
-- room_id는 실시간 구독 필터와 권한 확인에 쓰며, 후보의 여행방으로 자동 설정한다.

create table public.destination_votes (
  destination_id uuid not null references public.destinations (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  choice text not null check (choice in ('agree', 'neutral', 'disagree')),
  updated_at timestamptz not null default now(),
  primary key (destination_id, user_id)
);

create index destination_votes_room_id_idx on public.destination_votes (room_id);

create function public.set_vote_room()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  select room_id into new.room_id
  from public.destinations
  where id = new.destination_id;
  new.updated_at := now();
  return new;
end;
$$;

create trigger destination_votes_set_room
  before insert or update on public.destination_votes
  for each row execute function public.set_vote_room();

-- 3. 확정된 여행지 -----------------------------------------------------------

alter table public.travel_rooms
  add column confirmed_destination_id uuid references public.destinations (id) on delete set null;

-- 방장도 확정 여행지를 직접 바꾸지 못하게, 수정 가능한 열을 제한한다.
revoke update on public.travel_rooms from authenticated;
grant update (name, expected_members) on public.travel_rooms to authenticated;

create function public.confirm_destination(target uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_room uuid;
  room_owner uuid;
  agree_count integer;
  member_count integer;
begin
  select d.room_id, r.owner_id into target_room, room_owner
  from public.destinations d
  join public.travel_rooms r on r.id = d.room_id
  where d.id = target;

  if target_room is null then
    raise exception 'destination_not_found';
  end if;
  if room_owner is distinct from (select auth.uid()) then
    raise exception 'not_room_owner';
  end if;

  select count(*) into agree_count
  from public.destination_votes
  where destination_id = target and choice = 'agree';

  select count(*) into member_count
  from public.room_members
  where room_id = target_room;

  if agree_count * 2 <= member_count then
    raise exception 'not_majority';
  end if;

  update public.travel_rooms
  set confirmed_destination_id = target
  where id = target_room;
end;
$$;

revoke execute on function public.confirm_destination(uuid) from public, anon;
grant execute on function public.confirm_destination(uuid) to authenticated;

-- 4. RLS ---------------------------------------------------------------------

alter table public.destinations enable row level security;
alter table public.destination_votes enable row level security;

create policy "멤버만 여행지 후보 조회"
  on public.destinations for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 후보 등록"
  on public.destinations for insert to authenticated
  with check (proposed_by = (select auth.uid()) and public.is_room_member(room_id));

create policy "멤버만 투표 조회"
  on public.destination_votes for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 투표"
  on public.destination_votes for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_room_member(room_id));

create policy "본인 투표만 변경"
  on public.destination_votes for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_room_member(room_id));

revoke all on public.destinations, public.destination_votes from anon;
grant select, insert on public.destinations to authenticated;
grant select, insert, update on public.destination_votes to authenticated;

-- 후보, 투표, 확정 결과를 실시간으로 전달한다.
alter publication supabase_realtime add table public.destinations, public.destination_votes, public.travel_rooms;
