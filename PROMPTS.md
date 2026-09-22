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
