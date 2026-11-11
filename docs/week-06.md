# 6주차 활동지 / Week 6 Worksheet

**저장소와 첫 PR / Repository and first pull request**

- 작성일 / Date: 2026-11-11
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

`main`은 보호 브랜치로 두고, 작업은 `feature/이슈번호-기능명`으로 만든다. 버그 수정은 `fix/이슈번호-내용`, 문서는 `docs/내용`을 쓴다.
예: `feature/4-trip-chat`, `fix/10-itinerary-sync`, `docs/week-06`

## 커밋 메시지 규칙 / Commit message rule

기능 작업은 이슈 번호를 앞에 붙인다. 예: `#4 여행방 실시간 채팅 추가`
문서 작업은 `docs:`를 붙인다. 예: `docs: 6주차 활동지 작성`

## 각자 PR 번호 / 리뷰어 / Each member's PR / reviewer

| 작성자 | PR 번호 | 리뷰어 |
|---|---|---|
| 김현우 | #__ | 박영욱 |
| 박영욱 | #__ | 김현우 |

## 브랜치 보호 설정 / Branch protection

- [ ] 설정 완료 Done

## 성찰 / Reflection — 리뷰가 형식적이지 않으려면

2인 팀이라 서로 바쁠 때 내용을 보지 않고 승인하기 쉽다. 리뷰어는 이슈의 완료 조건을 직접 실행해 확인하고, 그 결과를 코멘트로 한 줄 이상 남긴 뒤 승인한다. 여행방 데이터를 다루는 코드는 멤버가 아닌 사용자가 접근할 수 없는지 반드시 확인한다. AI가 작성한 코드도 작성자가 설명할 수 있어야 PR을 올린다.

---

> 수업 종료 시 커밋하세요 / Commit this at the end of class
> `git add docs/week-06.md && git commit -m "docs: 6주차 활동지 작성"`
