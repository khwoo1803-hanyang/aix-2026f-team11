# 2주차 활동지 — 코딩 에이전트와 컨텍스트

| | |
| :-- | :-- |
| 팀명 | 패트와 매트 |
| 작성일 | 26.11.11 |
| 참여자 | 김현우, 박영욱 |

---

## 0. 준비

 `trip-seed` 저장소를 엽니다. 다음 파일이 있는지 확인하세요.

- [ ] `schema.sql`
- [ ] `service.js`
- [ ] `routes.js`
- [ ] `CONVENTIONS.md`

---

## 1. 조 나누기

팀을 두 조로 나눕니다. (4인 → 2:2 / 3인 → 1:2)

| 조 | 참여자 |
| :-- | :-- |
| A조 | 박영욱 |
| B조 | 김현우 |

**두 조는 같은 과제를 동시에 수행합니다.** 서로의 화면을 보지 마세요.

### 오늘의 과제 (두 조 공통)

> 여행방 채팅 메시지 검색 기능을 추가하라. 메시지 본문에서 키워드로 찾을 수 있어야 한다.

우리 앱은 친구들이 여행방 채팅에서 나눈 대화를 바탕으로 AI가 여행 조건(날짜, 기간, 이동수단, 예산 등)을 정리합니다. 채팅 검색은 사용자가 "그때 누가 예산 얼마라고 했지?"를 다시 찾을 때, 그리고 AI가 조건의 근거가 된 메시지를 찾을 때 쓰입니다.

---

## 2. 에이전트에게 준 것

### A조 — 이것만 붙여넣습니다

```
여행방 채팅 검색 기능 만들어줘. 메시지 내용에서 키워드로 찾을 수 있게.
```

파일은 **하나도 주지 않습니다.**

### B조 — 네 칸을 모두 채웁니다

```
[지시]
여행방 채팅 메시지 검색 기능을 추가해줘. 메시지 본문에서 키워드로 검색된다.

[규약]
(CONVENTIONS.md 내용 전체를 붙여넣기)

[근거]
(schema.sql, service.js, routes.js 내용 전체를 붙여넣기)

[종료조건]
- GET /trips/:tripId/messages/search?q=키워드 로 호출된다
- 메시지 본문에 키워드가 포함된 메시지만 최신순으로 반환한다
- 각 메시지에 보낸 사람 이름(user_name)을 포함한다
- 여행방 멤버만 검색할 수 있다. 멤버가 아니면 403과 { ok: false, error: "NOT_TRIP_MEMBER" } 를 반환한다
- q가 비어 있으면 400과 { ok: false, error } 를 반환한다
```

### 실제로 붙여넣은 것 (원문 그대로, 요약 금지)

```
[지시]
여행방 채팅 메시지 검색 기능을 추가해줘. 메시지 본문에서 키워드로 검색된다.

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

에러 코드는 대문자와 밑줄로 씁니다. (예: `NOT_TRIP_MEMBER`)

## 명명 규칙

- 함수명은 동사로 시작합니다. `list`, `get`, `create`, `update`, `remove`, `search`
- 데이터베이스 컬럼은 스네이크 케이스를 씁니다. `trip_id`, `created_at`
- 자바스크립트 변수는 카멜 케이스를 씁니다. `tripId`, `createdAt`

## 입력 검증

- 사용자 입력은 반드시 검증합니다.
- 검증에 실패하면 400과 함께 `{ ok: false, error }` 를 반환합니다.

## 권한

- 여행방과 그 안의 데이터(채팅 메시지, 장소, 투표)는 **그 여행방의 멤버만** 조회하고 수정할 수 있습니다.
- 여행방 데이터를 다루는 모든 쿼리에는 `trip_members`로 요청자가 멤버인지 확인하는 조건을 포함합니다.
- 멤버가 아니면 403과 `{ ok: false, error: "NOT_TRIP_MEMBER" }` 를 반환합니다.
- 존재하지 않는 여행방도 같은 403으로 응답해, 방이 있는지 없는지를 드러내지 않습니다.

[근거]
--- schema.sql ---
-- trip-seed 데이터베이스 스키마 (MySQL)

CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  email      VARCHAR(255) NOT NULL UNIQUE,
  name       VARCHAR(50)  NOT NULL,
  created_at DATETIME     NOT NULL
);

CREATE TABLE trips (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  owner_id    INT          NOT NULL,
  title       VARCHAR(100) NOT NULL,
  region      VARCHAR(50)  NULL,      -- 여행지를 아직 안 정했으면 NULL
  start_date  DATE         NULL,
  end_date    DATE         NULL,
  invite_code CHAR(6)      NOT NULL UNIQUE,
  created_at  DATETIME     NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

CREATE TABLE trip_members (
  trip_id   INT NOT NULL,
  user_id   INT NOT NULL,
  role      ENUM('owner', 'member') NOT NULL DEFAULT 'member',
  joined_at DATETIME NOT NULL,
  PRIMARY KEY (trip_id, user_id),
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE messages (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  trip_id    INT      NOT NULL,
  user_id    INT      NOT NULL,
  body       TEXT     NOT NULL,
  created_at DATETIME NOT NULL,
  FOREIGN KEY (trip_id) REFERENCES trips(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_members_user  ON trip_members(user_id);
CREATE INDEX idx_messages_trip ON messages(trip_id, created_at);

--- service.js ---
const db = require('./db');

/**
 * 사용자가 참여한 여행방 목록을 최신순으로 조회한다.
 */
function listTrips(userId) {
  return db.all(
    `SELECT t.id, t.title, t.region, t.start_date, t.end_date, m.role
       FROM trips t
       JOIN trip_members m ON m.trip_id = t.id
      WHERE m.user_id = ?
      ORDER BY t.created_at DESC`,
    [userId]
  );
}

/**
 * 여행방 한 건을 조회한다. 멤버가 아니면 null을 반환한다.
 */
function getTrip(userId, tripId) {
  return db.get(
    `SELECT t.id, t.title, t.region, t.start_date, t.end_date, t.invite_code
       FROM trips t
       JOIN trip_members m ON m.trip_id = t.id
      WHERE t.id = ? AND m.user_id = ?`,
    [tripId, userId]
  );
}

/**
 * 여행방 채팅 메시지를 오래된 순으로 조회한다. 멤버가 아니면 빈 배열을 반환한다.
 */
function listMessages(userId, tripId) {
  return db.all(
    `SELECT msg.id, msg.body, msg.created_at, u.id AS user_id, u.name AS user_name
       FROM messages msg
       JOIN trip_members m ON m.trip_id = msg.trip_id AND m.user_id = ?
       JOIN users u ON u.id = msg.user_id
      WHERE msg.trip_id = ?
      ORDER BY msg.created_at ASC`,
    [userId, tripId]
  );
}

/**
 * 여행방에 메시지를 보낸다. 멤버가 아니면 아무것도 저장하지 않는다(changes = 0).
 */
function createMessage(userId, tripId, body) {
  return db.run(
    `INSERT INTO messages (trip_id, user_id, body, created_at)
     SELECT trip_id, user_id, ?, NOW()
       FROM trip_members
      WHERE trip_id = ? AND user_id = ?`,
    [body, tripId, userId]
  );
}

module.exports = { listTrips, getTrip, listMessages, createMessage };

--- routes.js ---
const express = require('express');
const service = require('./service');

const router = express.Router();

// 내 여행방 목록 조회
router.get('/trips', async (req, res) => {
  const trips = await service.listTrips(req.user.id);
  res.json({ ok: true, data: trips });
});

// 여행방 단건 조회
router.get('/trips/:tripId', async (req, res) => {
  const trip = await service.getTrip(req.user.id, req.params.tripId);

  if (!trip) {
    return res.status(403).json({ ok: false, error: 'NOT_TRIP_MEMBER' });
  }

  res.json({ ok: true, data: trip });
});

// 여행방 채팅 메시지 목록 조회
router.get('/trips/:tripId/messages', async (req, res) => {
  const trip = await service.getTrip(req.user.id, req.params.tripId);

  if (!trip) {
    return res.status(403).json({ ok: false, error: 'NOT_TRIP_MEMBER' });
  }

  const messages = await service.listMessages(req.user.id, req.params.tripId);
  res.json({ ok: true, data: messages });
});

// 여행방에 메시지 보내기
router.post('/trips/:tripId/messages', async (req, res) => {
  const { body } = req.body;

  if (!body || !body.trim()) {
    return res.status(400).json({ ok: false, error: 'BODY_REQUIRED' });
  }

  const result = await service.createMessage(req.user.id, req.params.tripId, body.trim());

  if (result.changes === 0) {
    return res.status(403).json({ ok: false, error: 'NOT_TRIP_MEMBER' });
  }

  res.status(201).json({ ok: true, data: { id: result.lastID } });
});

module.exports = router;

[종료조건]
- GET /trips/:tripId/messages/search?q=키워드 로 호출된다
- 메시지 본문에 키워드가 포함된 메시지만 최신순으로 반환한다
- 각 메시지에 보낸 사람 이름(user_name)을 포함한다
- 여행방 멤버만 검색할 수 있다. 멤버가 아니면 403과 { ok: false, error: "NOT_TRIP_MEMBER" } 를 반환한다
- q가 비어 있으면 400과 { ok: false, error } 를 반환한다
```

> 요약하지 마세요. 나중에 이 기록이 무엇이 결과를 만들었는지 확인하는 근거가 됩니다.

---

## 3. 결과 확인

> 측정 방법: 각 조의 프롬프트를 이 과제 내용을 모르는 새 Claude 대화에 그대로 붙여넣었습니다. 나온 코드를 `trip-seed`에 붙인 뒤 MariaDB 10.11(MySQL 호환)에서 종료조건 테스트 9개(검색 결과, 최신순, 보낸 사람 이름, 다른 방 메시지 미포함, 비멤버 403, 없는 방 403, 빈 q 400, 기존 기능 유지)를 돌려 확인했습니다.

| | 확인 항목 | A조 | B조 |
| :-: | :-- | :-- | :-- |
| ① | 실행 성공까지 걸린 시간 | 실패 (답변은 약 1분 25초 만에 나왔지만 Flutter(Dart) 앱 코드라 Node.js 서버인 `trip-seed`에 붙일 수 없음) | 약 40초 (답변을 받아 붙여넣자마자 테스트 9/9 통과) |
| ② | 없는 함수·컬럼을 지어낸 개수 | 6개 | 0개 |
| | → 지어낸 이름 | `room_id`, `sender_id`, `content` (DB 컬럼), `roomId`, `_messages` (기존 채팅 화면에 있다고 가정한 변수), `MessageBubble` (기존 말풍선 위젯) | 없음 (`escapeLike`는 새로 정의한 보조 함수) |
| ③ | `CONVENTIONS.md` 위반 개수 | 4개 | 0개 |
| | → 무엇을 어겼는가 | 계층 분리(`service.js` 없이 앱에서 직접 필터), 응답 형식(`{ ok, data }` 없음), 입력 검증(빈 검색어를 400이 아니라 빈 결과로 처리), 권한(멤버 확인 없음) | 위반 없음 (검색어 100자 제한 `QUERY_TOO_LONG` 검증을 스스로 추가) |
| ④ | 사람이 직접 고친 지점 | 부분 수정 불가 | 0곳 |
| | → 어디를 어떻게 | 언어(Dart)와 데이터 구조가 달라 서버 코드 전체를 새로 작성해야 함 | 없음 |
| ⑤ | **여행방 멤버만 검색되는가** | 아니오 | 예 |

### ⑤번을 반드시 확인하세요

생성된 SQL에 `trip_members` 조건이 들어 있는지, 또는 검색 전에 `getTrip`으로 멤버인지 확인하는지 보세요.

없다면 **코드는 정상 동작하지만 URL의 `tripId`만 바꿔도 남의 여행방 채팅이 검색됩니다.** 에러도 나지 않습니다. 친구끼리 나눈 날짜, 예산, 출발지 같은 대화가 그대로 노출됩니다.

**확인 결과**
- A조: 서버용으로 제시한 SQL이 `WHERE room_id = ? AND content LIKE ...` 뿐이라 요청자가 누구인지 아예 보지 않습니다. 컬럼명만 실제 스키마로 바꿔 돌려 보니, 여행방 1 멤버가 여행방 2를 검색했을 때 남의 메시지 "부산 예산 비밀 메시지"가 그대로 나왔습니다.
- B조: 같은 요청에 `403 { ok: false, error: "NOT_TRIP_MEMBER" }` 를 반환했습니다. 라우트에서 `getTrip`으로 한 번, 검색 SQL의 `JOIN trip_members ... AND m.user_id = ?`로 한 번, 두 겹으로 막고 있습니다.

---

## 4. 두 조의 결과 비교

작업이 끝나면 두 조가 만든 코드를 나란히 놓고 함께 답하세요.

**4-1. 두 결과의 가장 큰 차이는 무엇입니까?**

```
가장 큰 차이는 A조가 우리 저장소와 아예 다른 것을 만들었다는 점입니다. 백엔드가 무엇인지 몰랐던 A조 에이전트는 서버 API가 아니라 Flutter 앱 안에서 이미 불러온 메시지를 거르는 검색 화면을 만들었고, 서버용으로는 room_id, sender_id, content처럼 우리 스키마에 없는 컬럼으로 SQL 예시를 지어냈습니다. 그래서 trip-seed에 붙일 수 없었고 종료조건 테스트도 돌릴 수 없었습니다. 더 위험한 것은 권한입니다. A조의 SQL에는 요청자 조건이 없어서, 실제로 돌려 보니 다른 여행방의 "부산 예산 비밀 메시지"가 검색됐습니다. 반면 B조는 schema.sql·service.js·routes.js·규약을 그대로 따라 service.js에 searchMessages를, routes.js에 검색 라우트를 추가했고, 한 줄도 고치지 않고 붙여넣었는데 테스트 9개를 모두 통과했습니다. 남의 여행방을 검색하면 403 NOT_TRIP_MEMBER가 반환됐습니다.
```

**4-2. A조의 실패는 모델 탓입니까, 우리가 주지 않은 탓입니까? 근거를 들어 적으세요.**

```
우리가 주지 않은 탓이라고 생각합니다. 두 조는 같은 모델을 썼고, B조 대화에서는 그 모델이 컬럼명, 응답 형식, 에러 코드 규칙, trip_members 멤버 확인까지 모두 지켜 테스트 9개를 그대로 통과했습니다. A조 결과도 코드 자체는 꼼꼼했습니다. 검색어 강조, 입력 지연 처리, 늦게 온 요청 무시까지 들어 있었습니다. 다만 "백엔드가 Node.js + MySQL이다", "메시지 본문 컬럼은 body다", "여행방 데이터는 멤버만 볼 수 있고 멤버 정보는 trip_members에 있다" 같은 것은 우리 프로젝트만의 약속이라, 프롬프트에 없으면 모델이 알 방법이 없습니다. 실제로 A조 에이전트는 답변 끝에 "지금 쓰는 백엔드를 알려주면 맞춰 주겠다"고 되물었습니다. 모르는 부분을 스스로 인정하고 추측했다는 뜻이므로, A조의 실패는 모델 능력의 한계가 아니라 정보 부족의 결과입니다.
```

**4-3. B조가 준 자료 중 결과를 가장 크게 바꾼 것 하나를 꼽는다면 무엇입니까? 왜 그렇게 생각합니까?**

```
[근거]에 넣은 기존 코드(service.js와 routes.js)라고 생각합니다. 처음에는 권한 조항("모든 쿼리에 trip_members 멤버 확인 조건을 포함한다")이 가장 중요할 거라고 예상했습니다. 그래서 확인하려고, B조 프롬프트에서 권한 조항과 "멤버만 검색할 수 있다"는 종료조건을 둘 다 지운 버전을 새 대화에 한 번 더 넣어 봤습니다. 그런데 결과는 거의 같았습니다. 라우트에서 getTrip으로 확인한 뒤 403 NOT_TRIP_MEMBER를 반환하고, SQL에도 JOIN trip_members를 넣어 테스트 9개를 모두 통과했습니다. 에이전트가 "기존 메시지 목록 조회와 같은 방식"이라고 직접 설명했듯이, listMessages와 getTrip에 이미 들어 있던 패턴을 그대로 따라 한 것입니다. 기존 코드는 언어(Node.js), 계층 구조, 컬럼명, 응답 형식, 권한 확인 방식을 한꺼번에 보여 줍니다. 그래서 이것이 없던 A조는 Flutter 앱을 만들었고, 이것이 있던 B조는 권한 문장이 없어도 안전한 코드를 만들었습니다. 다만 권한 조항이 필요 없다는 뜻은 아닙니다. 기존 코드에 멤버 확인 패턴이 없거나 일부만 있는 기능(예: 장소, 투표)을 새로 만들 때는, 이 조항이 모델이 따라야 할 기준을 문장으로 고정해 주는 안전장치 역할을 한다고 생각합니다.
```

---

## 5. PROMPTS.md 기록

위 2번의 프롬프트 원문을 저장소의 `PROMPTS.md`에 추가하고 커밋하세요.

```markdown
## 2026-11-11 · 여행방 채팅 메시지 검색 기능 (2주차 활동)

**지시**
(위 2번 "실제로 붙여넣은 것" 원문 전체)

**채택 여부**
B조 결과 전체 채택 — service.js에 searchMessages, routes.js에 GET /trips/:tripId/messages/search 추가. 수정 없이 종료조건 테스트 9/9 통과.
A조 결과 미채택 — Flutter 앱 코드라 서버 저장소에 붙일 수 없고, 멤버 확인이 없음.

**참고**
권한 조항과 멤버 종료조건을 뺀 B조 프롬프트로도 실행해 봤고, 기존 코드 패턴을 따라 멤버 확인이 들어가 테스트 9/9 통과.
```

- [ ] `PROMPTS.md`에 추가하고 커밋했습니다

---

## 6. 제출 확인

- [ ] 이 활동지를 저장소에 커밋했습니다
- [ ] `PROMPTS.md`를 커밋했습니다
