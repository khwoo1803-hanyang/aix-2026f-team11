# 11주차 활동지 / Week 11 Worksheet

**개발 착수 / Starting development**

- 작성일 / Date: 2026-11-18
- 참여자 / Present: 김현우, 박영욱

---

## ① 착수 점검표 / Start checklist

수업 시작 후 10분 안에 확인합니다. 체크되지 않은 항목이 있으면 그것부터 해결하고 개발을 시작합니다.
*Check within the first 10 minutes. Fix any unchecked item before you start coding.*

- [ ] 초기 파일이 저장소에 올라와 있다 / Initial files are in the repository — Flutter 뼈대는 PR #4로 올렸고 리뷰 대기 중 (`main` 머지 전)
- [ ] 7주차 이슈가 GitHub에 등록되어 있고 담당자가 지정되어 있다 / Week 7 issues are on GitHub with owners — 아직 등록하지 않음
- [ ] 팀원 모두 같은 환경에서 실행된다 / Everyone can run it in the same environment — 김현우 PC는 웹·Android 빌드 성공, 박영욱 PC는 Android SDK 미설치
- [x] 브랜치 규칙을 정했다 / Branch rule agreed — `feature/이슈번호-기능명`, 문서는 `docs/내용` (6주차 참고)

---

## ② 개발 일정 / Development schedule

5주차 **작업 순서**와 7주차 **이슈·마일스톤**을 바탕으로 이슈를 주차별로 배치합니다.
*Place your issues week by week, based on the Week 5 work order and Week 7 issues and milestones.*

- 11주차에 MVP가 동작해야 합니다. / Fill backwards from the deadlines.
- 선행 이슈가 끝나기 전에 뒤 이슈를 넣지 않습니다. / Never schedule an issue before the ones it depends on.
- 한 사람에게 몰리지 않았는지 확인합니다. / Check that no one is overloaded.

이슈 번호는 7주차 활동지 기준입니다.

| 주차 Week | 수업 일정 Class | 끝낼 이슈 # Issues to close | 담당 Owner |
|---|---|---|---|
| 9주차 | 개발 착수 | 주제 변경으로 재설계, 완료한 이슈 없음 | - |
| 10주차 | 막힘 진단 · 데모 시나리오 초안 | 기술 구성 변경(Firebase → Supabase), 개발 환경 구성 | 김현우 |
| 11주차 | **MVP 완료 · 중간 데모** | #1(일부), #2, #3, #4, #8 | 김현우(#2, #3, #4, #8), 박영욱(#1 나머지) |
| 12주차 | 핵심 경로 테스트 | #5, #6, #7, #11 | 박영욱(#5, #7, #11), 김현우(#6) |
| 13주차 | **배포 · 실행 패키지** | #12 | 김현우 |

> 일정이 맞지 않으면 기능을 줄입니다. 뺀 기능은 5주차 Won't 목록에 옮깁니다.
> *If it doesn't fit, cut scope and move the feature to your Week 5 Won't list.*

- 11주차 MVP는 로그인, 여행방, 초대 코드, 채팅, 여행지 투표까지로 줄였다. AI 조건 추출과 추천(#5~#7)은 API 키 준비가 필요해 12주차로 옮겼다.
- 구글 장소 검색(#9)과 공동 일정표(#10)는 Google Maps 결제 계정이 필요해 MVP 포함 여부를 정하지 못했다. 빼기로 하면 5주차 Won't 목록에 옮긴다.

---

## ③ 이번 주 목표 이슈 / This week's issues

| # | 제목 Title | 담당 Owner | 완료 Done |
|---|---|---|---|
| #1 | 데이터 스키마와 보안 규칙 | 김현우, 박영욱 | [ ] 프로필·여행방·멤버·메시지 테이블과 권한 완료, 조건·투표·일정 테이블 남음 |
| #2 | 로그인과 여행방 생성 | 김현우 | [ ] 구현 완료, PR #5 리뷰 대기 |
| #3 | 초대 코드로 참여 | 김현우 | [ ] 구현 완료, PR #5 리뷰 대기 |
| #4 | 실시간 채팅과 오버레이 | 김현우 | [ ] 구현 완료, PR #6 리뷰 대기, 기기 2대 확인 전 |
| #8 | 여행지 투표와 확정 | 김현우 | [ ] 시작 전 |

완료 표시는 PR이 `main`에 머지되고 완료 조건을 앱에서 확인한 뒤에 체크한다.

---

## ④ 오늘 진행한 것 / Progress today

- **개발 환경:** Flutter SDK를 OneDrive 밖(`%USERPROFILE%\develop\flutter`)으로 옮기고 Android NDK 28.2를 설치해 Android 디버그 빌드에 성공함
- **Flutter 뼈대 (PR #4):** Android·iOS·웹 프로젝트 생성, Supabase 연결 설정, `env.json` 설정 파일 구성
- **회원가입·로그인, 여행방 생성, 초대 코드 입장 (PR #5):** 6자리 초대 코드 발급, 초대 코드로 입장, 여행방 화면에 초대 코드와 멤버 목록 표시
- **실시간 채팅 (PR #6):** 여행방 화면 오른쪽 아래 채팅 버튼과 채팅창
- **DB:** Supabase에 `profiles`, `travel_rooms`, `room_members`, `messages` 테이블과 RLS 정책 적용
- **확인 결과:**
  - 테스트 계정 3개로 확인함. 멤버가 아닌 계정은 여행방·멤버·메시지를 볼 수 없었고, 방장이 아니면 여행방을 수정할 수 없었음
  - 채팅 메시지는 다른 멤버에게 약 0.4초 만에 실시간으로 도착함
  - 코드 분석 문제 없음, 자동 테스트 11개 통과
  - 앱 화면을 직접 조작하는 확인과 기기 2대 동시 확인은 아직 하지 않음
- **문서:** `travel_app_context.md`에 진행 상황을 반영함

- [ ] 이번 활동에서 AI를 사용했다면 `PROMPTS.md`에 기록했습니다 / Logged any AI use in `PROMPTS.md` — Claude Code로 개발함, PR #1 충돌 해결 후 기록 예정

---

> 수업 종료 시 커밋하세요 / Commit this at the end of class
> `git add docs/week-11.md && git commit -m "docs: 11주차 활동지 작성"`
