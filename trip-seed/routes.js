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

// 여행방 채팅 메시지 검색
router.get('/trips/:tripId/messages/search', async (req, res) => {
  const { q } = req.query;

  // ?q=a&q=b 처럼 들어오면 배열이 되므로 문자열인지 먼저 확인한다
  if (typeof q !== 'string' || !q.trim()) {
    return res.status(400).json({ ok: false, error: 'QUERY_REQUIRED' });
  }

  const keyword = q.trim();

  if (keyword.length > 100) {
    return res.status(400).json({ ok: false, error: 'QUERY_TOO_LONG' });
  }

  const trip = await service.getTrip(req.user.id, req.params.tripId);

  if (!trip) {
    return res.status(403).json({ ok: false, error: 'NOT_TRIP_MEMBER' });
  }

  const messages = await service.searchMessages(req.user.id, req.params.tripId, keyword);
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
