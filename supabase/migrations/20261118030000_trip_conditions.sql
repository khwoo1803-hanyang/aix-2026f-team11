-- 여행 조건 (활동지 #5 채팅 조건 추출, #6 조건 확인·수정)
-- extract-conditions Edge Function이 채팅을 AI로 읽고, 요청한 멤버 권한으로 여기에 저장한다.
-- 여행방마다 항목(field)별로 한 줄씩 둔다.

-- 1. 조건 -------------------------------------------------------------------

create table public.trip_conditions (
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  field text not null check (field in ('people', 'dates', 'departure', 'transport', 'budget', 'activity')),
  value text not null check (char_length(trim(value)) between 1 and 200),
  source_message_id bigint references public.messages (id) on delete set null,
  inferred boolean not null default false,
  updated_by uuid references public.profiles (id) on delete set null,
  updated_at timestamptz not null default now(),
  primary key (room_id, field)
);

-- 출처 메시지는 같은 여행방의 메시지여야 하고, 수정한 사람과 시간은 서버가 채운다.
create function public.prepare_trip_condition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.source_message_id is not null and not exists (
    select 1 from public.messages
    where id = new.source_message_id and room_id = new.room_id
  ) then
    raise exception 'source_not_in_room';
  end if;
  new.updated_by := (select auth.uid());
  new.updated_at := now();
  return new;
end;
$$;

create trigger trip_conditions_prepare
  before insert or update on public.trip_conditions
  for each row execute function public.prepare_trip_condition();

-- 2. AI 호출 기록 -----------------------------------------------------------
-- 같은 여행방에서 AI를 너무 자주 부르지 못하게 Edge Function이 횟수를 센다.

create table public.ai_requests (
  id bigint generated always as identity primary key,
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  kind text not null check (kind in ('extract_conditions', 'recommend')),
  created_at timestamptz not null default now()
);

create index ai_requests_room_kind_created_idx on public.ai_requests (room_id, kind, created_at);

-- 3. RLS --------------------------------------------------------------------

alter table public.trip_conditions enable row level security;
alter table public.ai_requests enable row level security;

create policy "멤버만 조건 조회"
  on public.trip_conditions for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 조건 추가"
  on public.trip_conditions for insert to authenticated
  with check (public.is_room_member(room_id));

create policy "멤버만 조건 수정"
  on public.trip_conditions for update to authenticated
  using (public.is_room_member(room_id))
  with check (public.is_room_member(room_id));

create policy "멤버만 조건 삭제"
  on public.trip_conditions for delete to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 AI 호출 기록 조회"
  on public.ai_requests for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 AI 호출 기록"
  on public.ai_requests for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_room_member(room_id));

revoke all on public.trip_conditions, public.ai_requests from anon;
grant select, insert, update, delete on public.trip_conditions to authenticated;
grant select, insert on public.ai_requests to authenticated;

-- 조건이 바뀌면 다른 멤버 화면에도 바로 반영한다.
alter publication supabase_realtime add table public.trip_conditions;
