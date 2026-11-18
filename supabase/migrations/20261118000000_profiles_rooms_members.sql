-- 사용자 프로필, 여행방, 여행방 멤버
-- 여행방 데이터는 멤버만 볼 수 있고, 여행방 생성과 입장은 함수로만 처리한다.

-- 1. 테이블 -------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nickname text not null check (char_length(nickname) between 1 and 30),
  created_at timestamptz not null default now()
);

create table public.travel_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 40),
  invite_code text not null unique check (invite_code ~ '^[A-Z2-9]{6}$'),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  expected_members integer check (expected_members between 1 and 20),
  created_at timestamptz not null default now()
);

create table public.room_members (
  room_id uuid not null references public.travel_rooms (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create index room_members_user_id_idx on public.room_members (user_id);

-- 2. 회원가입 시 프로필 자동 생성 ------------------------------------------

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, nickname)
  values (
    new.id,
    left(coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'nickname'), ''),
      split_part(new.email, '@', 1)
    ), 30)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. 권한 확인 함수 ----------------------------------------------------------
-- RLS 정책 안에서 room_members를 다시 조회할 때 정책이 재귀하지 않도록
-- security definer 함수로 확인한다.

create function public.is_room_member(target_room uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.room_members
    where room_id = target_room and user_id = (select auth.uid())
  );
$$;

create function public.shares_room_with(other_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.room_members mine
    join public.room_members theirs on theirs.room_id = mine.room_id
    where mine.user_id = (select auth.uid()) and theirs.user_id = other_user
  );
$$;

-- 4. 여행방 생성, 초대 코드 입장 -------------------------------------------

create function public.create_room(room_name text, expected integer default null)
returns public.travel_rooms
language plpgsql
security definer
set search_path = ''
as $$
declare
  alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  new_code text;
  new_room public.travel_rooms;
begin
  if (select auth.uid()) is null then
    raise exception 'not_authenticated';
  end if;

  loop
    new_code := '';
    for i in 1..6 loop
      new_code := new_code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
    end loop;
    exit when not exists (select 1 from public.travel_rooms where invite_code = new_code);
  end loop;

  insert into public.travel_rooms (name, invite_code, owner_id, expected_members)
  values (trim(room_name), new_code, (select auth.uid()), expected)
  returning * into new_room;

  insert into public.room_members (room_id, user_id, role)
  values (new_room.id, (select auth.uid()), 'owner');

  return new_room;
end;
$$;

create function public.join_room_by_code(code text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'not_authenticated';
  end if;

  select id into target
  from public.travel_rooms
  where invite_code = upper(trim(code));

  if target is null then
    raise exception 'invalid_invite_code';
  end if;

  insert into public.room_members (room_id, user_id, role)
  values (target, (select auth.uid()), 'member')
  on conflict (room_id, user_id) do nothing;

  return target;
end;
$$;

revoke execute on function public.create_room(text, integer) from public, anon;
revoke execute on function public.join_room_by_code(text) from public, anon;
grant execute on function public.create_room(text, integer) to authenticated;
grant execute on function public.join_room_by_code(text) to authenticated;

-- 5. RLS ---------------------------------------------------------------------

alter table public.profiles enable row level security;
alter table public.travel_rooms enable row level security;
alter table public.room_members enable row level security;

create policy "본인 또는 같은 여행방 멤버의 프로필 조회"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()) or public.shares_room_with(id));

create policy "본인 프로필 수정"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "멤버만 여행방 조회"
  on public.travel_rooms for select to authenticated
  using (public.is_room_member(id));

create policy "방장만 여행방 수정"
  on public.travel_rooms for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "멤버만 멤버 목록 조회"
  on public.room_members for select to authenticated
  using (public.is_room_member(room_id));

-- 여행방과 멤버 추가는 create_room, join_room_by_code 함수로만 한다.

revoke all on public.profiles, public.travel_rooms, public.room_members from anon;
grant select, update on public.profiles to authenticated;
grant select, update on public.travel_rooms to authenticated;
grant select on public.room_members to authenticated;
