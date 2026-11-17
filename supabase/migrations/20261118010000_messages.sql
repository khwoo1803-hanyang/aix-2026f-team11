-- 여행방 채팅 메시지
-- 멤버만 읽고 쓸 수 있고, 다른 사람 이름으로는 보낼 수 없다.

create table public.messages (
  id bigint generated always as identity primary key,
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  content text not null check (char_length(trim(content)) between 1 and 1000),
  created_at timestamptz not null default now()
);

create index messages_room_id_created_at_idx on public.messages (room_id, created_at);

alter table public.messages enable row level security;

create policy "멤버만 메시지 조회"
  on public.messages for select to authenticated
  using (public.is_room_member(room_id));

create policy "멤버만 본인 이름으로 메시지 작성"
  on public.messages for insert to authenticated
  with check (user_id = (select auth.uid()) and public.is_room_member(room_id));

revoke all on public.messages from anon;
grant select, insert on public.messages to authenticated;

-- 새 메시지를 앱에 실시간으로 전달한다. 전달 대상은 위 조회 정책을 따른다.
alter publication supabase_realtime add table public.messages;
