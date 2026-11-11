# 9주차 활동지 / Week 9 Worksheet

**개발 착수 / Starting development**

- 작성일 / Date: 2026-10-28
- 참여자 / Present: 김현우, 박영욱

---

## ① 착수 점검표 / Start checklist

수업 시작 후 10분 안에 확인합니다. 체크되지 않은 항목이 있으면 그것부터 해결하고 개발을 시작합니다.
*Check within the first 10 minutes. Fix any unchecked item before you start coding.*

- [ ] 초기 파일이 저장소에 올라와 있다 / Initial files are in the repository
- [ ] 7주차 이슈가 GitHub에 등록되어 있고 담당자가 지정되어 있다 / Week 7 issues are on GitHub with owners
- [ ] 팀원 모두 같은 환경에서 실행된다 / Everyone can run it in the same environment — VS Code + Flutter, Firebase 에뮬레이터
- [ ] 브랜치 규칙을 정했다 / Branch rule agreed — `<종류>/#<이슈번호>-<짧은-영어-설명>` (예: `feat/#3-chat-sheet`), `main`은 PR로만 합침 (6주차)

---

## ② 개발 일정 / Development schedule

5주차 **작업 순서**와 7주차 **이슈·마일스톤**을 바탕으로 이슈를 주차별로 배치합니다.
*Place your issues week by week, based on the Week 5 work order and Week 7 issues and milestones.*

- 11주차에 MVP가 동작해야 합니다. / Fill backwards from the deadlines.
- 선행 이슈가 끝나기 전에 뒤 이슈를 넣지 않습니다. / Never schedule an issue before the ones it depends on.
- 한 사람에게 몰리지 않았는지 확인합니다. / Check that no one is overloaded.

| 주차 Week | 수업 일정 Class | 끝낼 이슈 # Issues to close | 담당 Owner |
|---|---|---|---|
| 9주차 | 개발 착수 | #1, #2 | 김현우(#1), 박영욱(#2) |
| 10주차 | 막힘 진단 · 데모 시나리오 초안 | #3, #4, #5 | 박영욱(#3), 김현우(#4, #5) |
| 11주차 | **MVP 완료 · 중간 데모** | #6, #7, #8 | 박영욱(#6, #8), 김현우(#7) |
| 12주차 | 핵심 경로 테스트 | #9, #10, #11 | 박영욱(#9), 김현우(#10, #11) |
| 13주차 | **배포 · 실행 패키지** | #12 | 박영욱 |

> 일정이 맞지 않으면 기능을 줄입니다. 뺀 기능은 5주차 Won't 목록에 옮깁니다.
> *If it doesn't fit, cut scope and move the feature to your Week 5 Won't list.*

배치할 때 확인한 것:
- 순서: #1 → #2 → #3, #1 → #4, (#3, #4) → #5 → #6 → #7 → #8 순서를 지켰음. #3과 #4는 서로 의존하지 않아 10주차에 동시에 진행함.
- 몰림: 10주차에 김현우가 #4와 #5를 함께 맡는데, #5는 #3과 #4가 모두 끝나야 시작할 수 있어 10주차에서 가장 위험함. #4를 10주차 초반에 먼저 끝내고, #3이 늦어지면 박영욱이 #3을 끝낸 직후 #5의 화면 쪽(조건 바 표시)을 돕기로 함.

---

## ③ 이번 주 목표 이슈 / This week's issues

| # | 제목 Title | 담당 Owner | 완료 Done |
|---|---|---|---|
| #1 | 데이터 구조와 보안 규칙 | 김현우 | [ ] |
| #2 | 로그인과 여행방 만들기·초대 코드 참여 | 박영욱 | [ ] |
| - | 7주차 이슈를 여행 앱 기준으로 GitHub에 다시 등록 | 김현우, 박영욱 | [ ] |

---

## ④ 오늘 진행한 것 / Progress today

- 주제를 수면 앱(도파민 디톡스·수면 케어)에서 여행 계획 앱으로 바꾸기로 결정함. 비슷한 수면 앱이 이미 많아 차별점을 만들기 어려웠고, 여러 명이 함께 쓰는 여행 계획에서 더 분명한 문제를 찾았기 때문.
- 기존 여행 앱(트리플, Wanderlog 등)을 조사해, 일정 편집은 함께 할 수 있지만 의견 조율은 카카오톡에서 따로 한다는 점을 차별점으로 잡음. 트리플의 동시 편집 문제는 출처가 없어 직접 확인할 항목으로 남김.
- 앱 화면 흐름을 설계함. 처음에는 여행지를 정한 경우/안 정한 경우로 나눈 온보딩 12개 화면을 만들었고, 그다음 채팅을 중심으로 바꿔 "여행방 만들기 → 채팅방 기본 추천 → 채팅 중 조건 찾기 → 조건 확인 → 조건 기반 추천 → 채팅 속 투표·확정" 6개 화면을 만듦. 모든 화면 오른쪽 아래에 채팅 버튼을 두어 채팅을 열고 닫을 수 있게 함.
- 4·5·7주차 문서(요구 명세, 태스크, 이슈)를 여행 앱 기준으로 다시 정리하기로 함.

- [ ] 이번 활동에서 AI를 사용했다면 `PROMPTS.md`에 기록했습니다 / Logged any AI use in `PROMPTS.md`

---

> 수업 종료 시 커밋하세요 / Commit this at the end of class
> `git add docs/week-09.md && git commit -m "docs: 9주차 활동지 작성"`
