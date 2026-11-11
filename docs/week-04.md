# 4주차 활동지 / Week 4 Worksheet

**주제 선택과 요구 명세 / Choosing a problem & writing the spec**

- 작성일 / Date: 2026-09-23
- 수정일 / Revised: 2026-11-11 (9주차 주제 변경에 따라 여행 계획 앱 기준으로 재작성, 백엔드를 Supabase로 변경)
- 참여자 / Present: 김현우, 박영욱

---

## ① 주제 선택 / Choosing one problem

| 항목 Item | 내용 |
|---|---|
| 선택한 주제 Chosen | 친구들과 채팅하면 대화 속 조건으로 여행지를 추천하고 일정을 함께 결정하게 돕는 여행 계획 앱 |
| 선택 근거 Why | 단체 채팅방에서 여행 조건과 의견이 흩어져 결정이 늦어지고 정리 부담이 한 사람에게 몰린다고 판단함 (인터뷰로 확인 예정) |

## ② 성공 기준 가져오기 / Success criteria from Week 3

| 3주차 성공 기준 원문 Original (Week 3) | 모호한 표현 Vague words |
|---|---|
| 여러 사람의 의견을 한곳에 모아 더 빠르게 여행지와 일정을 함께 결정하도록 돕는다 | "한곳에", "더 빠르게", "함께 결정" |
|  |  |

## ③ Acceptance Criteria

최소 정상 경로 2개 + 실패 경로 1개. **판정 방법** 칸이 비면 아직 명세가 아닙니다.
At least two normal paths + one failure path. If "How to check" is empty, it is not yet a spec.

| # | 경로 Path | EARS 문장 Sentence | 판정 방법 How to check |
|---|---|---|---|
| *예시* | *정상* | *WHEN 학생이 과제 목록을 열면 THE 시스템은 SHALL 과목별 미제출 과제를 마감일 순으로 표시한다* | *미제출 과제 3건을 만든 뒤 목록을 열어 마감일 순으로 나오는지 확인* |
| AC-1 | 정상 Normal | WHEN 멤버가 여행방 채팅에 여행 조건이 담긴 메시지를 보내면 THE 시스템은 SHALL 인원·날짜·출발지·이동수단·예산·활동 중 해당 조건을 추출해 출처 메시지와 함께 조건 목록에 표시한다. | "8월 둘째 주 2박 3일, 서울 출발, 차 1대, 1인 30만원" 메시지를 보낸 뒤 날짜, 기간, 출발지, 이동수단, 예산이 조건 목록에 출처와 함께 나오는지 확인 |
| AC-2 | 정상 Normal | WHEN 멤버가 조건 확인 화면에서 추천 받기를 누르면 THE 시스템은 SHALL 저장된 조건에 맞는 국내 여행지 3곳을 일치 이유와 함께 표시한다. | 조건 5개를 저장하고 추천 받기를 눌러 여행지 3곳과 각 이유가 표시되는지 확인 |
| AC-3 | 정상 Normal | WHILE 두 명 이상의 멤버가 같은 일정표를 열어 둔 동안 THE 시스템은 SHALL 한 멤버의 장소 추가·순서 변경을 5초 이내에 다른 멤버 화면에 반영한다. | 기기 2대로 같은 일정표를 열고 한쪽에서 장소를 추가한 뒤 다른 쪽에 5초 이내로 나타나는지 스톱워치로 측정 |
| AC-4 | 실패 Failure | IF AI가 조건을 추출하지 못하거나 호출에 실패하면 THEN THE 시스템은 SHALL 조건을 임의로 저장하지 않고 직접 입력 안내를 표시한다. | Edge Function이 오류를 반환하도록 설정하고 메시지를 보낸 뒤 조건이 저장되지 않고 안내가 나오는지 확인 |
| AC-5 | 실패 Failure | IF 여행방 멤버가 아닌 사용자가 여행방 데이터를 요청하면 THEN THE 시스템은 SHALL 접근을 거부한다. | 멤버가 아닌 계정으로 해당 여행방의 채팅을 읽는 요청을 보내 데이터가 반환되지 않는지 Supabase RLS 정책 테스트로 확인 |

> 확인할 동작이 더 있으면 AC-4부터 행을 추가해 쓰십시오.
> If there are more behaviors to check, add rows from AC-4.

- [ ] 이번 활동에서 AI를 사용했다면 `PROMPTS.md`에 기록했습니다 / Logged any AI use in `PROMPTS.md`

---

> 수업 종료 시 커밋하세요 / Commit this at the end of class
> `git add docs/week-04.md && git commit -m "docs: 4주차 활동지 작성"`
