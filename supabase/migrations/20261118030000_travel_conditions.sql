-- 여행방마다 멤버가 합의한 여행 조건을 한 곳에 저장한다.
create table public.travel_conditions (
  room_id uuid primary key references public.travel_rooms (id) on delete cascade,
  departure text check (char_length(btrim(departure)) between 1 and 100),
  start_date date check (start_date between date '0001-01-01' and date '9999-12-31'),
  end_date date check (end_date between date '0001-01-01' and date '9999-12-31'),
  traveler_count integer check (traveler_count between 1 and 1000),
  budget_per_person_krw integer check (budget_per_person_krw >= 0),
  transport text check (char_length(btrim(transport)) between 1 and 100),
  preferred_activities text check (char_length(btrim(preferred_activities)) between 1 and 500),
  revision integer not null default 1,
  check (
    (start_date is null and end_date is null)
    or (start_date is not null and end_date is not null and start_date <= end_date)
  )
);

create function public.bump_travel_conditions_revision()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.revision := old.revision + 1;
  return new;
end;
$$;

create trigger travel_conditions_revision
  before update on public.travel_conditions
  for each row execute function public.bump_travel_conditions_revision();

alter table public.travel_conditions enable row level security;

create policy "멤버만 여행 조건 조회"
  on public.travel_conditions for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 여행 조건 등록"
  on public.travel_conditions for insert to authenticated
  with check (public.is_room_member(room_id));

create policy "멤버만 여행 조건 수정"
  on public.travel_conditions for update to authenticated
  using (public.is_room_member(room_id))
  with check (public.is_room_member(room_id));

revoke all on public.travel_conditions from public, anon, authenticated;
grant select on public.travel_conditions to authenticated;
grant insert (
  room_id, departure, start_date, end_date, traveler_count,
  budget_per_person_krw, transport, preferred_activities
) on public.travel_conditions to authenticated;
grant update (
  departure, start_date, end_date, traveler_count,
  budget_per_person_krw, transport, preferred_activities
) on public.travel_conditions to authenticated;
