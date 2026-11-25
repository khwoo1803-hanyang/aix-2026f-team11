-- AI 여행지 추천 (활동지 #7)
-- recommend-destinations Edge Function이 저장된 여행 조건과 투표 현황을 Claude로 읽고,
-- 국내 여행지 3곳과 추천 이유를 요청한 멤버 권한으로 여기에 저장한다.
-- 한 번 추천할 때마다 같은 batch_id로 3줄을 넣고, 앱은 가장 최근 batch만 보여준다.

create table public.destination_recommendations (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  batch_id uuid not null,
  rank smallint not null check (rank between 1 and 3),
  name text not null check (char_length(trim(name)) between 1 and 40),
  region text check (region is null or char_length(region) <= 40),
  reason text not null check (char_length(trim(reason)) between 1 and 300),
  -- 조건별 일치 여부: [{"field": "budget", "status": "match", "note": "..."}]
  matches jsonb not null default '[]'::jsonb check (jsonb_typeof(matches) = 'array'),
  -- 실제 거리·가격·운영 시간처럼 따로 확인해야 하는 점
  caution text check (caution is null or char_length(caution) <= 200),
  requested_by uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (batch_id, rank)
);

create index destination_recommendations_room_created_idx
  on public.destination_recommendations (room_id, created_at desc);

alter table public.destination_recommendations enable row level security;

create policy "멤버만 추천 조회"
  on public.destination_recommendations for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 추천 저장"
  on public.destination_recommendations for insert to authenticated
  with check (requested_by = (select auth.uid()) and public.is_room_member(room_id));

revoke all on public.destination_recommendations from anon;
grant select, insert on public.destination_recommendations to authenticated;

-- 누가 추천을 받든 다른 멤버 화면에도 바로 보인다.
alter publication supabase_realtime add table public.destination_recommendations;
