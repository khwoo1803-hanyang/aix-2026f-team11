-- 조건 직접 수정 (활동지 #6)
-- 멤버가 직접 입력하거나 고친 조건은 manual = true로 표시하고,
-- extract-conditions가 채팅을 다시 정리해도 이 항목은 덮어쓰지 않는다.

alter table public.trip_conditions
  add column manual boolean not null default false;
