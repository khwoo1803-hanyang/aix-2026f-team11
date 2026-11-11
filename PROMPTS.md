## 2026-09-15 · 메모 검색 기능 (2주차 활동)

**지시**

```
[지시]
메모 검색 기능을 추가해줘. 제목과 본문에서 키워드로 검색된다.

[규약]
# 프로젝트 규약

이 문서는 코드를 작성할 때 지켜야 할 규칙입니다.

## 계층 분리

- `routes.js`는 HTTP 요청과 응답만 다룹니다. SQL을 직접 쓰지 않습니다.
- 데이터베이스 접근은 `service.js`에만 둡니다.

## 응답 형식

모든 응답은 다음 두 형태 중 하나입니다.

    { "ok": true,  "data": ... }
    { "ok": false, "error": "ERROR_CODE" }

에러 코드는 대문자와 밑줄로 씁니다. (예: `MEMO_NOT_FOUND`)

## 명명 규칙

- 함수명은 동사로 시작합니다. `list`, `get`, `create`, `update`, `remove`
- 데이터베이스 컬럼은 스네이크 케이스를 씁니다. `user_id`, `created_at`
- 자바스크립트 변수는 카멜 케이스를 씁니다. `userId`, `createdAt`

## 입력 검증

- 사용자 입력은 반드시 검증합니다.
- 검증에 실패하면 400과 함께 `{ ok: false, error }` 를 반환합니다.

## 권한

- 모든 조회와 수정은 **본인 소유 데이터로 한정**합니다.
- 모든 쿼리에 `user_id` 조건을 포함합니다.

[근거]
--- schema.sql ---
-- memo-seed 데이터베이스 스키마

CREATE TABLE users (
  id         INTEGER PRIMARY KEY,
  email      TEXT NOT NULL UNIQUE,
  name       TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE memos (
  id         INTEGER PRIMARY KEY,
  user_id    INTEGER NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_memos_user ON memos(user_id);

--- service.js ---
const db = require('./db');

/**
 * 사용자의 메모 목록을 최신순으로 조회한다.
 */
function listMemos(userId) {
  return db.all(
    `SELECT id, title, created_at
       FROM memos
      WHERE user_id = ?
      ORDER BY created_at DESC`,
    [userId]
  );
}

/**
 * 메모 한 건을 조회한다. 본인 메모가 아니면 null을 반환한다.
 */
function getMemo(userId, memoId) {
  return db.get(
    `SELECT id, title, body, created_at
       FROM memos
      WHERE id = ? AND user_id = ?`,
    [memoId, userId]
  );
}

/**
 * 메모를 생성한다.
 */
function createMemo(userId, title, body) {
  return db.run(
    `INSERT INTO memos (user_id, title, body, created_at)
     VALUES (?, ?, ?, datetime('now'))`,
    [userId, title, body]
  );
}

module.exports = { listMemos, getMemo, createMemo };

--- routes.js ---
const express = require('express');
const service = require('./service');

const router = express.Router();

// 메모 목록 조회
router.get('/memos', async (req, res) => {
  const memos = await service.listMemos(req.user.id);
  res.json({ ok: true, data: memos });
});

// 메모 단건 조회
router.get('/memos/:id', async (req, res) => {
  const memo = await service.getMemo(req.user.id, req.params.id);

  if (!memo) {
    return res.status(404).json({ ok: false, error: 'MEMO_NOT_FOUND' });
  }

  res.json({ ok: true, data: memo });
});

// 메모 생성
router.post('/memos', async (req, res) => {
  const { title, body } = req.body;

  if (!title || !body) {
    return res.status(400).json({ ok: false, error: 'TITLE_AND_BODY_REQUIRED' });
  }

  const result = await service.createMemo(req.user.id, title, body);
  res.status(201).json({ ok: true, data: { id: result.lastID } });
});

module.exports = router;

[종료조건]
- GET /memos/search?q=키워드 로 호출된다
- 제목 또는 본문에 키워드가 포함된 메모만 반환한다
- 본인 메모만 반환한다
- q가 비어 있으면 400과 { ok: false, error } 를 반환한다
```

**채택 여부**

전체 채택 — 생성된 `searchMemos`(service.js)와 `GET /memos/search`(routes.js)를 수정 없이 그대로 사용했거 사람이 직접 고친 부분은 없음(제너레이션 중 발견된 이스케이프 처리 버그는 모델이 자체적으로 수정하였음).

## 2026-09-16 3주차 활동
## 4. AI 사용 기록 / AI use log  → `PROMPTS.md`

> **전부 남기지 않습니다.** AI가 만든 것이 **산출물에 실제로 들어갔을 때만** 남깁니다.
> Log only what actually made it into your work — not every question you asked.

| 상황 | 기록? |
|---|---|
| "EARS가 뭐야?" 같은 개념 질문, 번역, 오타 수정 | 안 함 |
| AI가 뽑아준 인터뷰 질문을 3절에 옮겨 적음 | 함 |
| AI에게 후보 아이디어를 받아 1절에 반영함 | 안 함 |
| 받았지만 안 쓰기로 한 것 중, 판단이 오래 걸린 것 | 함 |

**주당 최대 3건.** 3건을 넘으면 가장 중요한 3건만 고릅니다. 억지로 채우지 마세요.
나머지는 한 줄로 / Summarise the rest in one line:
### 1. 1절 문제 후보 표 작성·재작성
- 무엇을 하려고 썼는가: 내가 가진 문제 아이디어 메모(수면 직전 핸드폰 사용, 실시간 자막, 강의실 위치)를 1절 표 형식(사용자/상황/페인포인트/성공기준)과 한 문장 요약에 맞게 정리하고, 이후 표 전체를 일관되게 다듬으려고 씀
- 넣은 프롬프트 원문 그대로: "내 아이디어와 글을 참고해서 하나의 문장으로 다듬어줘" 
- 나온 것 중 쓴 것/버린 것: 성공 기준(B, C), 세 후보 한 문장 요약, 전체 재작성된 표 문장(페인포인트 원인 추가, C 사용자 "대학"→"대학생" 수정 등)은 그대로 씀
- 버렸다면 왜 버렸는가: AI가 같이 제안한 "청색광 미적용 다크 UI" 해결책 아이디어는 버림 — 문제 정의 단계에서 해결책을 먼저 정하면 안 된다는 규칙 때문

### 2. 3절 확인할 가정·인터뷰 계획 작성
- 무엇을 하려고 썼는가: 3절 "확인할 가정과 확인 계획" 표와, 후보 1(수면 문제)의 인터뷰 질문 예시·관찰 계획을 작성하려고 씀
- 넣은 프롬프트 원문 그대로: "인터뷰를 한다면 해야 하는 필수 질문이 무엇이 있을까" / "후보 1번으로 예시 들어줘"
- 나온 것 중 쓴 것/버린 것: 표의 가정·방법·대상 문장, 인터뷰 질문 예시 / 버린 것 없음

### 3. 2절 표 및 인터뷰 대상자 구체화
- 무엇을 하려고 썼는가: 2절 표를 채우고, 인터뷰 대상을 역할이 아닌 구체적인 사람으로 정하려고 씀
- 넣은 프롬프트 원문 그대로: "a 후보자 대상은 같은 과 동기 선 후배로" / "조용우 교수는 후보자 b에 적어줘"
- 나온 것 중 쓴 것/버린 것: "같은 과 동기·선후배", 조용우 교수님을 후보 B 정보 제공자로 적은 내용은 그대로 씀 / 버린 것 없음
- 버렸다면 왜 버렸는가: 해당 없음 — 버린 것 없음

> 주의 / Caution
> AI가 만들어준 문제 후보에는 **사용자가 없습니다.** 그럴듯한 문장만 있습니다.
> 그대로 1절에 옮기면 '가짜 사용자형'이 됩니다. 사용자는 여러분이 찾아야 합니다.

- [o] 해당 건을 `PROMPTS.md`에 기록했다 / Logged in `PROMPTS.md`
- [o] 산출물에 들어간 AI 결과물이 없다 / Nothing from AI made it into our work


**참고**

- `/memos/search` 라우트는 `/memos/:id`보다 먼저 선언해야 라우팅 충돌이 없음.
- better-sqlite3 기반 테스트 9건(제목 매치, 본문 매치, 타인 메모 차단, 빈 쿼리 400, 공백 쿼리 400, 무매치 결과, 기존 라우트 정상 동작, LIKE 특수문자 `%` 이스케이프)을 실행하여 모두 통과 확인.

## 2026-10-28 · 여행 계획 앱 시장 조사와 차별점 탐색 (Gemini)

**지시**
여행 계획 앱

숙소 예약 중점이 아니라 플랜 짜는 것을 중점으로 하는 앱이 있을까? 항공편이랑 숙소 예약 현황도 볼 수 있는 부가 서비스가 있는 앱으로

트리플이 추천을 해주고 그걸 바탕으로 스케줄표를 짜주는 앱이야?

트리플이랑 비슷한 느낌의 여행 앱을 만들려고 하는데 살짝 다르게 하면 어떤 것을 할 수 있을까

차별점이 한 눈에 보이게 정리해줘

트리플에서 스케줄표를 작성할때 여러명이서  한 스케줄표를 편집할 수 있어?

사람들을 불러 모으고 트리플이 아닌 우리 앱을 쓰게 할 만한 여러 요소들이 뭐가 있을지 나열해줘

너가 그러면 지금 내용들을 기반으로 앱을 어떻게 개발할지 설명해줄래

**채택 여부**
일부 채택
- 채택: 함께 계획하기를 차별점으로 삼는 방향, 장소별 찬반 투표·댓글, AI가 의견 충돌을 조율하는 기능, 역할 배지(Could)
- 미채택: 초대 시 포인트·상품권 지급(학생 프로젝트에서 불가), 숏폼 영상 일정 빌더(영상 데이터 없음), 이동수단별 주차·경사도 동선(데이터 없음), WebSocket·CRDT 직접 구현과 Node.js/Spring 자체 서버(2인 팀 일정에 비해 과함 → Firestore로 대체), 이메일 포워딩·OCR 예약 파싱(서버·유료 서비스 필요)

**참고**
"트리플에서 두 명이 동시에 편집하면 한 사람의 수정이 덮어씌워진다"는 답변은 출처가 없고 같은 답변 안의 설명과도 맞지 않아 사실로 쓰지 않음. 3주차 3절 4번 가정으로 옮겨 직접 확인하기로 함(10주차 기준 아직 미확인).

## 2026-10-28 · 기능 구성과 화면 흐름 설계 (Claude)

**지시**
이식된 내용을 기반으로 앱에 어떤 기능을 구성하고 할지 전체적으로 묶어서 한 번 설명해주고 추가로 세세하게 단계별로 나누어서 설명해줘

첫 번째 사진을 보고 각각의 선택지 다음 단계에 어떤 ui가 나오면 좋을지 두 번째 사진의 내용을 보고 판단해줘

내가 원하는 건 ui에 정확히 어떤 화면이 뜨는지야

내가 원하는건 친구들을 불러 모으고 기본적으로 여행지를 추천해주고 친구들이랑 여행에 대해 채팅을 하면 채팅 내용을 기반으로 여행지 추천해주는거야 여행 일정 차 개수 그런 여행 때 생각해야하는 채팅에 올라온 요소들을 기반으로

기존 방식에서 오른쪽 하단쪽에 채팅방 아이콘을 넣어서 채팅방을 들어갔다 나올 수 있도록 해줘 국민은행이나 그런 앱 보면 채팅봇 그런게 있잖아 그런 것처럼

추가로 저 채팅방 아이콘을 눌렀을때 화면 보여줘

**채택 여부**
일부 채택
- 채택: Flutter + Riverpod + Firebase(Auth, Firestore, Cloud Functions) 구성과 Claude API 키를 Cloud Functions에만 두는 구조, 채팅 중심 6개 화면(여행방 만들기 → 기본 추천 → 채팅 중 조건 찾기 → 조건 확인 → 조건 기반 추천 → 채팅 속 투표·확정), 모든 화면 오른쪽 아래 채팅 버튼과 채팅 시트, 후보함·일정표 화면(Should)
- 미채택: 여행지를 정한 경우/안 정한 경우로 나눈 온보딩 흐름 중 "여행지 후보 직접 올리기 → 투표 → AI 조율" 화면(채팅에서 조건을 찾아 추천하는 방식으로 대체), 여행 컨셉 슬라이더·대기실 연출·역할 정하기 화면(MVP에서 제외, Could)

**참고**
화면 설계 결과는 Claude 디자인 캔버스(여행 앱 온보딩 화면)에 있음. 추천 여행지 이름과 이유는 화면 예시 데이터이며 사실 확인을 하지 않음.

## 2026-11-11 · 2주차 활동 재실행: 여행방 채팅 메시지 검색 (Claude)

**지시**
A조: `docs/week-02.md` 2절 "A조 — 이것만 붙여넣습니다" 원문
B조: `docs/week-02.md` 2절 "실제로 붙여넣은 것" 원문 전체
추가 실험: B조 원문에서 [규약]의 "## 권한" 절과 [종료조건]의 "여행방 멤버만 검색할 수 있다…" 줄만 지운 것

(각 조 프롬프트는 이 과제 내용을 모르는 새 Claude 대화에 그대로 넣었음. 실행을 요청한 프롬프트: "결과확인까지 다 해줘")

**채택 여부**
- B조 결과 전체 채택: service.js에 `searchMessages`, routes.js에 `GET /trips/:tripId/messages/search` 추가. 수정 없이 종료조건 테스트 9/9 통과.
- A조 결과 미채택: Flutter 앱 코드라 서버 저장소에 붙일 수 없고, 제시한 SQL에 멤버 확인이 없어 다른 여행방 메시지가 검색됨.
- 추가 실험 결과는 비교용으로만 사용(9/9 통과, 기존 코드 패턴을 따라 멤버 확인이 들어감).

**참고**
테스트는 MariaDB 10.11에서 실행함. 결과는 `docs/week-02.md` 3·4절에 정리함.

## 2026-11-11 · 1~10주차 활동지를 여행 앱 주제로 다시 작성 (Claude)

**지시**
이게 깃허브에서 편집된 파일들인데 전에 수면 앱 기준으로 한거야 오래 걸리고 토큰 많이 잡아 먹어도 되니깐 새로 바꾼 주제인 여행앱 기준으로 내용 싹 다 바꿔주고 안에 실험 내용이나 적어댜 되는거 있으면 너가 알아서 다 채워줘 cli 처럼 오토모드로 싹 다 해주면 돼

**채택 여부**
(팀원 검토 후 기입 — 전체 채택 / 일부 채택: 무엇을 어떻게 고쳤는지 / 미채택)

**참고**
- 1주차는 주제와 관계없는 팀 규칙이라 오타(메주→매주)와 참여자 이름(조영욱→박영욱)만 고침.
- 3주차 후보 B·C는 수면 앱 시기에 쓴 내용을 그대로 둠.
- 저장소를 볼 수 없어서 PR 번호(6주차), 닫힌 이슈 수(10주차), 체크박스(저장소 상태 확인 항목)는 비워 둠.
- 7주차 이슈 담당자는 원래 모두 두 사람이었으나, "담당자를 everyone으로 쓰지 않는다"는 5주차 규칙에 맞춰 한 명씩 나눔(팀 확인 필요).
- 수정 전 수면 앱 버전은 git 기록에 남아 있음.
