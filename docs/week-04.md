# 4주차 활동지 / Week 4 Worksheet

**주제 선택과 요구 명세 / Choosing a problem & writing the spec**

- 작성일 / Date: 2026-09-23
- 참여자 / Present: 김현우, 박영욱

---

## ① 주제 선택 / Choosing one problem

| 항목 Item | 내용 |
|---|---|
| 선택한 주제 Chosen | 잠들기 쉽게 도와주고 숙면할 수 있게 도와주는 게임 |
| 선택 근거 Why | 현대인들의 잠들기 전 핸드폰 사용으로 인한 수면 부족과 얕은 잠 |

## ② 성공 기준 가져오기 / Success criteria from Week 3

| 3주차 성공 기준 원문 Original (Week 3) | 모호한 표현 Vague words |
|---|---|
| 더 쉽게 잠들고 수면의 질이 좋아지도록 돕는다 | WHEN 사용자가 잠에 들기 전에 핸드폰으로 게임을 실행하면 THE 시스템은 SHALL 사용자가 지정한 시각 이전에 사용자가 잠에 들 경우 더 좋은 보상을 제공한다.  |
|  |  |

## ③ Acceptance Criteria

최소 정상 경로 2개 + 실패 경로 1개. **판정 방법** 칸이 비면 아직 명세가 아닙니다.
At least two normal paths + one failure path. If "How to check" is empty, it is not yet a spec.

| # | 경로 Path | EARS 문장 Sentence | 판정 방법 How to check |
|---|---|---|---|
| *예시* | *정상* | *WHEN 학생이 과제 목록을 열면 THE 시스템은 SHALL 과목별 미제출 과제를 마감일 순으로 표시한다* | *미제출 과제 3건을 만든 뒤 목록을 열어 마감일 순으로 나오는지 확인* |
| AC-1 | 정상 Normal | WHILE 사용자가 게임을 실행 중인 동안  THE 시스템은  SHALL 사용자의 수면 여부를 주기적으로 판단한다. | 전방 카메라를 이용해 사용자의 눈이 감겼는지, 마이크를 이용해 소리가 40db이하로 줄었는지 확인 |
| AC-2 | 정상 Normal | WHEN 사용자가 지정한 시각 이내에 잠에 들었을 경우 THE 시스템은 SHALL 사용자에게 2배의 보상을 제공한다. | 사용자가 지정한 시각보다 더 일찍 잠에 들 경우 기존 보상보다 2배 더 제공함 |
| AC-3 | 실패 Failure | WHILE 사용자가 지정한 시각 이내에 잠에 들지 못하는 동안 THE 시스템은 SHALL 기본 보상보다 더 1~10% 줄어든 보상을 제공한다. | 사용자가 지정한 시각에서 10분경과 할 때 마다 보상이 1~10%씩 감소함 |

> 확인할 동작이 더 있으면 AC-4부터 행을 추가해 쓰십시오.
> If there are more behaviors to check, add rows from AC-4.

- [ ] 이번 활동에서 AI를 사용했다면 `PROMPTS.md`에 기록했습니다 / Logged any AI use in `PROMPTS.md`

---

> 수업 종료 시 커밋하세요 / Commit this at the end of class
> `git add docs/week-04.md && git commit -m "docs: 4주차 활동지 작성"`
