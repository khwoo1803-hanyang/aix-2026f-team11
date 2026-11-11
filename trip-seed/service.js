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

/**
 * LIKE 패턴에서 특수문자(%, _)와 이스케이프 문자(!)가 일반 글자로 검색되도록 이스케이프한다.
 */
function escapeLike(value) {
  return value.replace(/[!%_]/g, '!$&');
}

/**
 * 여행방 채팅 메시지를 본문 키워드로 검색해 최신순으로 반환한다. 멤버가 아니면 빈 배열을 반환한다.
 */
function searchMessages(userId, tripId, keyword) {
  return db.all(
    `SELECT msg.id, msg.body, msg.created_at, u.id AS user_id, u.name AS user_name
       FROM messages msg
       JOIN trip_members m ON m.trip_id = msg.trip_id AND m.user_id = ?
       JOIN users u ON u.id = msg.user_id
      WHERE msg.trip_id = ?
        AND msg.body LIKE ? ESCAPE '!'
      ORDER BY msg.created_at DESC, msg.id DESC`,
    [userId, tripId, `%${escapeLike(keyword)}%`]
  );
}

module.exports = { listTrips, getTrip, listMessages, createMessage, searchMessages };
