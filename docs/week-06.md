# 6주차 활동지 / Week 6 Worksheet

**저장소와 첫 PR / Repository and first pull request**

- 작성일 / Date: 2026-10-07
- 참여자 / Present: 김현우, 박영욱
- 최종 반영 / Feeds into: 제출물 ① 저장소 / Submission ①

---

## 초기 파일 / Initial files

- [ ] README
- [ ] LICENSE
- [ ] .gitignore

## 팀원 초대 수락 / Invitations accepted

- [ ] 전원 All

## 브랜치 이름 규칙 / Branch naming rule

`<종류>/#<이슈번호>-<짧은-영어-설명>`

- 종류: `feat`(기능), `fix`(버그 수정), `docs`(문서·활동지), `refactor`(동작은 그대로 두고 구조만 정리), `test`(테스트)
- 예: `feat/#3-chat-sheet`, `fix/#5-condition-parse`, `docs/week-06`
- `main`에는 직접 커밋하지 않고, 브랜치에서 작업한 뒤 PR로만 합칩니다.
- 한 브랜치에는 이슈 하나만 담습니다. 합친 브랜치는 삭제합니다.

## 커밋 메시지 규칙 / Commit message rule

`<종류>: #<이슈번호> <무엇을 했는지 한국어로>`

- 종류는 브랜치와 같은 `feat`, `fix`, `docs`, `refactor`, `test`, `chore`(설정·패키지)를 씁니다.
- 예: `feat: #3 여행방 채팅 시트 추가`, `fix: #5 대화에 없는 출발지를 확인 필요로 표시`, `docs: 6주차 활동지 작성`
- 이슈와 관계없는 커밋(활동지 등)은 이슈 번호를 생략합니다.
- AI가 만든 코드를 넣은 커밋은 `PROMPTS.md`에 같은 날짜로 기록하고, PR 설명에 그 항목을 적습니다.

## 각자 PR 번호 / 리뷰어 / Each member's PR / reviewer

| 작성자 | PR 번호 | 내용 | 리뷰어 |
|---|---|---|---|
| 김현우 | #__ | README에 프로젝트 소개와 실행 방법 작성 | 박영욱 |
| 박영욱 | #__ | `.gitignore`(Flutter·Firebase 설정 파일 제외)와 LICENSE 추가 | 김현우 |

## 브랜치 보호 설정 / Branch protection

- [ ] 설정 완료 Done — `main` 브랜치: PR을 거쳐야만 합칠 수 있음, 승인 1명 이상 필요

## 성찰 / Reflection — 리뷰가 형식적이지 않으려면

리뷰어가 코드를 눈으로만 읽고 승인하면 형식적인 리뷰가 됩니다. 그래서 리뷰어는 PR에 연결된 이슈의 완료 조건을 자기 기기에서 직접 실행해 보고, 실행한 결과를 댓글로 남긴 뒤에만 승인하기로 했습니다. 특히 우리 앱은 친구들의 대화가 오가는 앱이라 권한이 가장 중요합니다. 여행방 데이터를 다루는 PR은 반드시 멤버가 아닌 테스트 계정으로도 접근해 보고, 막히는지 확인한 결과를 적습니다(2주차 실험에서 권한 확인이 빠지면 에러 없이 남의 대화가 보인다는 것을 확인했음). AI가 만든 코드가 들어간 PR은 작성자가 직접 이해한 부분과 그대로 쓴 부분을 PR 설명에 나눠 적어, 리뷰어가 어디를 더 봐야 하는지 알 수 있게 합니다.

---

> 수업 종료 시 커밋하세요 / Commit this at the end of class
> `git add docs/week-06.md && git commit -m "docs: 6주차 활동지 작성"`
