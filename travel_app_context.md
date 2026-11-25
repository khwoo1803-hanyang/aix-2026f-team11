# 공동 여행 계획 앱 프로젝트 컨텍스트

> VS Code / Codex 개발 참고 문서  
> 버전: 1.4 (2026-11-25 AI 여행지 추천, 장소 후보함·공동 일정표 반영, Google 장소 검색 보류)  
> 프로젝트 상태: 회원가입·로그인, 여행방, 실시간 채팅, 여행지 투표, 조건 추출·수정, AI 여행지 추천, 장소 후보함·공동 일정표 main 머지. 추천·일정 DB는 Supabase 적용 전, AI는 크레딧 충전 후 확인. Google 장소 검색·지도 보류

---

# 1. 프로젝트 개요

## 1.1 프로젝트 목적

여러 사람이 하나의 여행방에 참여하여 여행 계획을 공동으로 수립할 수 있는 모바일 애플리케이션을 개발한다.

사용자들은 여행방을 생성하고 친구들을 초대하여 실시간으로 대화할 수 있다. AI는 대화 내용을 분석하여 여행 조건을 추출하고, 조건에 맞는 여행지를 추천한다.

여행지를 결정한 이후에는 지도에서 장소를 검색하고, 멤버들과 투표를 통해 방문 장소와 일정을 공동으로 구성할 수 있다.

## 1.2 핵심 기능

1. 여행방 생성 및 친구 초대
2. 실시간 공동 채팅
3. AI를 활용한 여행 조건 분석
4. 여행지 후보 등록 및 투표
5. 여행 컨셉 투표
6. 여행 역할 분담
7. 지도 기반 장소 검색
8. 공동 여행 일정 관리
9. 외부 항공권 및 숙박 서비스 연동
10. 여행 경비 관리 및 정산

## 1.3 서비스의 핵심 특징

- 여러 사용자가 하나의 여행방 데이터를 공유한다.
- 채팅 내용을 AI가 분석하여 여행 조건으로 변환한다.
- AI가 추출한 정보는 사용자가 확인한 후 확정한다.
- 여행지 및 장소는 멤버들의 투표를 통해 결정한다.
- 모든 여행 계획은 실시간으로 동기화한다.

---

# 2. 개발 환경 및 기술 스택

## 2.1 기본 기술 스택

| 구분 | 기술 | 사용 목적 |
|---|---|---|
| 모바일 앱 | Flutter | Android 및 iOS 개발 |
| 프로그래밍 언어 | Dart | 앱 코드 작성 (Edge Functions만 TypeScript) |
| 상태 관리 | Riverpod | 화면 상태와 데이터 구독 관리 |
| 데이터베이스 | PostgreSQL | 여행 관련 데이터 저장 |
| 백엔드 | Supabase | 인증, DB, 서버 기능 |
| 실시간 통신 | Supabase Realtime | 채팅 및 데이터 동기화 |
| AI | OpenAI API, Claude API | 기능별 분담: 채팅 분석은 OpenAI, 여행지 추천은 Claude (제공자는 서버 설정으로 지정, 실패 시 다른 제공자로 대체) |
| 지도 | Google Maps API | 장소 검색 및 지도 |
| 서버 로직 | Supabase Edge Functions | AI 및 주요 비즈니스 로직 |

※ Flutter 프로젝트는 `flutter create`로 생성하고, 패키지는 `pubspec.yaml`에서 관리한 뒤 `flutter pub get`으로 설치한다.

## 2.2 시스템 아키텍처

Flutter 앱이 사용자 인터페이스를 담당하고, Supabase가 데이터베이스와 인증을 담당한다.

AI 분석과 추천은 Supabase Edge Functions의 공통 AI 모듈(`supabase/functions/_shared/ai/`)을 통해 OpenAI API 또는 Claude API에 요청한다. 앱은 어떤 제공자가 쓰이는지 알지 못한다.

```text
[Flutter Application]
          |
          |
     [Supabase]
          |
    +-----+------+
    |     |      |
   Auth  DB   Realtime
          |
    [Edge Functions]
          |
    +-----+------+
    |            |
 [OpenAI / Claude]  [External APIs]
               |
          [Google Maps]
```

---

# 3. 전체 화면 구성

## 3.1 인증 및 초기 화면

| 화면 | 기능 |
|---|---|
| 로그인 | 이메일 로그인 |
| 회원가입 | 사용자 계정 생성 |
| 메인 화면 | 여행방 목록 |
| 여행지 선택 | 여행지 검색 및 선택 |
| 여행 방식 선택 | 혼자 또는 친구와 여행 |
| 친구 초대 | 초대 코드 및 링크 생성 |
| 초대 대기실 | 참여 멤버 확인 |

## 3.2 여행방 내부 화면

| 화면 | 기능 |
|---|---|
| 여행방 대시보드 | 여행 진행 상황 및 주요 정보 |
| 채팅 | 실시간 메시지 |
| AI 조건 확인 | AI가 추출한 조건 확인 및 수정 |
| 여행 컨셉 투표 | 멤버별 여행 취향 조사 |
| 역할 관리 | 총무, 길잡이, 사진 담당 등 |
| 여행지 후보 | 여행지 등록 |
| 여행지 투표 | 찬성, 보통, 반대 |
| 투표 결과 | 여행지별 의견 집계 |
| AI 조율 | 여행지 추천 및 의견 조율 |
| 장소 검색 | 지도 기반 장소 검색 |
| 장소 후보함 | 등록된 장소 확인 |
| 장소 투표 | 방문 장소 결정 |
| 일정표 | 날짜별 여행 일정 |
| 일정 편집 | 장소 및 방문 순서 수정 |

## 3.3 하단 내비게이션

- 홈
- 채팅
- 장소
- 일정
- 설정

---

# 4. 주요 기능 상세 설계

## 4.1 여행방 관리

- 사용자는 새로운 여행방을 생성할 수 있다.
- 여행방마다 고유 초대 코드를 생성한다.
- 다른 사용자는 초대 코드를 통해 참여한다.
- 하나의 사용자는 여러 여행방에 참여할 수 있다.
- 여행방에는 방장과 일반 멤버가 존재한다.
- 예상 인원과 실제 참여 인원을 별도로 관리한다.

## 4.2 실시간 채팅

- 여행방별 채팅 공간을 제공한다.
- 메시지는 Supabase Database에 저장한다.
- Supabase Realtime을 이용하여 메시지를 실시간 전달한다.
- 사용자별 메시지를 구분한다.
- 메시지 저장과 AI 분석은 별도로 처리한다.

## 4.3 여행 컨셉 투표

기본 투표 항목은 다음과 같다.

| 항목 | 설명 |
|---|---|
| 식도락 | 맛집 및 음식 중심 |
| 휴식 | 휴양 및 여유로운 여행 |
| 감성 사진 | 풍경 및 사진 촬영 |
| 액티비티 | 체험 및 활동 중심 |

각 사용자는 항목별 점수를 입력한다.

네 항목의 합계는 100점이어야 한다.

전체 사용자의 점수를 집계하여 여행방의 공통 취향을 계산한다.

## 4.4 여행 역할 분담

기본 역할은 다음과 같다.

- 총무: 가계부 및 정산
- 길잡이: 동선 및 교통
- 사진 담당: 사진 및 앨범
- 맛집 담당: 식당 후보 검색

각 역할의 담당자를 지정하고 역할별 업무를 관리한다.

## 4.5 여행지 선정

- 각 사용자는 최대 2개의 여행지 후보를 등록한다.
- 후보별 추천 이유를 작성할 수 있다.
- 멤버들은 찬성, 보통, 반대 중 하나를 선택한다.
- 사용자별 중복 투표를 방지한다.
- 투표 결과를 집계한다.
- AI가 전체 여행 조건과 투표 결과를 분석한다.
- 최종 여행지는 방장이 확정한다.

## 4.6 장소 및 일정 관리

- 지도에서 장소를 검색한다.
- 맛집, 카페, 관광지 등 카테고리로 분류한다.
- 장소를 여행방 후보함에 추가한다.
- 멤버들이 장소에 투표한다.
- 확정된 장소를 여행 일정에 추가한다.
- 일차별 일정을 작성한다.
- 방문 시간과 장소 순서를 관리한다.

---

# 5. AI 기능 설계

AI는 단순한 대화형 챗봇이 아니라 여행 계획을 지원하는 분석 시스템으로 구현한다.

## 5.1 AI 채팅 분석

사용자가 작성한 메시지를 분석하여 다음 정보를 추출한다.

| 추출 항목 | 예시 |
|---|---|
| 여행 인원 | 3명 |
| 출발지 | 서울 |
| 여행 날짜 | 11월 20일~22일 |
| 예산 | 1인당 20만 원 |
| 이동 수단 | 자동차 |
| 선호 활동 | 바다, 해산물 |

### 처리 과정

1. 사용자가 채팅을 작성한다.
2. 메시지가 Supabase에 저장된다.
3. Edge Function이 분석할 메시지를 선별한다.
4. 공통 AI 모듈이 설정된 제공자(기본 OpenAI)에 메시지와 기존 여행 조건을 전달한다.
5. AI가 구조화된 조건을 반환한다.
6. 추출된 조건을 condition_proposals에 저장한다.
7. 사용자가 조건을 확인하고 수정한다.
8. 승인된 조건만 travel_conditions에 저장한다.

### 조건 상태

- pending: 확인 대기
- confirmed: 사용자 승인
- rejected: 사용자 거부
- superseded: 새로운 조건으로 대체

AI가 추측한 정보를 확정된 사실처럼 저장하지 않는다.

## 5.2 AI 여행지 추천

AI는 다음 요소를 고려하여 여행지를 추천한다.

- 전체 여행 예산
- 출발지
- 이동 수단
- 여행 기간
- 여행 컨셉
- 멤버별 선호도
- 여행지 투표 결과

추천 결과에는 여행지 이름, 추천 이유, 조건 일치 여부를 포함한다.

실제 거리, 가격, 운영 시간 등은 외부 데이터로 검증한다.

## 5.3 AI 의견 조율

멤버들의 여행지 투표가 갈리는 경우 다음 정보를 분석한다.

- 찬성 인원
- 반대 인원
- 여행 컨셉 선호도
- 예산 적합성
- 이동 편의성

AI는 합의 가능한 대안과 추천 이유를 제시한다.

AI는 최종 결정을 자동으로 내리지 않는다.

---

# 6. Supabase 데이터베이스 설계

## 6.1 데이터베이스 테이블

| 테이블 | 역할 |
|---|---|
| profiles | 사용자 정보 |
| travel_rooms | 여행방 정보 |
| room_members | 여행방 참여자 |
| travel_conditions | 확정된 여행 조건 |
| condition_proposals | AI가 추출한 조건 |
| messages | 채팅 메시지 |
| destinations | 여행지 후보 |
| destination_votes | 여행지 투표 |
| concept_votes | 여행 컨셉 투표 |
| member_roles | 여행 역할 |
| places | 장소 후보 |
| place_votes | 장소 투표 |
| itinerary_days | 여행 일차 |
| itinerary_items | 일차별 일정 |

## 6.2 핵심 관계

```text
profiles
  |
  +--- room_members --- travel_rooms
                            |
       +--------------------+------------------+
       |          |         |         |        |
   messages  destinations  places  conditions  itinerary
       |          |         |                    |
  condition_  destination  place_            itinerary_
  proposals    _votes      votes              items
```

## 6.3 주요 데이터 규칙

1. 모든 여행 관련 데이터는 room_id로 여행방과 연결한다.
2. 사용자 ID는 Supabase Auth의 UUID를 사용한다.
3. room_members의 room_id와 user_id는 중복될 수 없다.
4. destination_votes는 destination_id와 user_id 조합으로 중복 투표를 방지한다.
5. place_votes도 place_id와 user_id 조합으로 중복 투표를 방지한다.
6. AI 조건 제안과 확정된 조건을 별도 테이블로 관리한다.
7. 일정은 itinerary_days와 itinerary_items로 구분한다.

## 6.4 권한 관리

Supabase RLS를 사용한다.

- 여행방 멤버만 해당 여행방의 정보를 조회할 수 있다.
- 멤버는 자신의 투표만 수정할 수 있다.
- 방장만 여행방의 중요 설정을 변경할 수 있다.
- 방장만 최종 여행지를 확정할 수 있다.
- 다른 여행방의 데이터에는 접근할 수 없다.

중요한 권한 검증은 클라이언트가 아닌 데이터베이스 정책과 서버에서 처리한다.

---

# 7. API 설계

논리적인 API 목록은 다음과 같다.

## 인증

- POST /auth/signup
- POST /auth/login
- POST /auth/logout
- GET /users/me

## 여행방

- POST /rooms
- GET /rooms
- GET /rooms/{roomId}
- PATCH /rooms/{roomId}
- POST /rooms/join
- GET /rooms/{roomId}/members

## 채팅

- GET /rooms/{roomId}/messages
- POST /rooms/{roomId}/messages

## 여행 조건

- GET /rooms/{roomId}/conditions
- POST /rooms/{roomId}/conditions
- PATCH /conditions/{conditionId}
- POST /conditions/{conditionId}/confirm
- POST /conditions/{conditionId}/reject

## AI

- POST /ai/analyze-chat
- POST /ai/recommend-destinations
- POST /ai/suggest-questions
- POST /ai/mediate-votes

## 여행지

- POST /rooms/{roomId}/destinations
- GET /rooms/{roomId}/destinations
- POST /destinations/{destinationId}/votes
- GET /rooms/{roomId}/destination-results

## 장소 및 일정

- GET /places/search
- POST /rooms/{roomId}/places
- GET /rooms/{roomId}/places
- POST /places/{placeId}/votes
- POST /rooms/{roomId}/itinerary/days
- POST /itinerary/days/{dayId}/items
- PATCH /itinerary/items/{itemId}
- DELETE /itinerary/items/{itemId}

주의: 위 Endpoint는 기능 설계를 위한 논리적 경로다. 실제 구현은 Supabase SDK, Database, RPC, Edge Functions로 나누어 처리한다.

---

# 8. 프로젝트 폴더 구조

```text
travel-app/
├── lib/
│   ├── app/
│   │   ├── navigation/
│   │   └── screens/
│   │       ├── auth/
│   │       ├── home/
│   │       ├── room/
│   │       ├── dashboard/
│   │       ├── chat/
│   │       ├── destination/
│   │       ├── places/
│   │       └── itinerary/
│   ├── components/
│   │   ├── common/
│   │   ├── chat/
│   │   ├── vote/
│   │   └── itinerary/
│   ├── services/
│   ├── models/
│   ├── hooks/
│   └── utils/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   │   ├── _shared/ai/
│   │   ├── join-room/
│   │   ├── analyze-chat/
│   │   ├── recommend-destinations/
│   │   └── mediate-votes/
│   └── config.toml
├── android/
├── ios/
├── web/
├── pubspec.yaml
├── analysis_options.yaml
└── travel_app_context.md
```

---

# 9. 개발 우선순위

개발 초기부터 모든 기능을 구현하지 않는다.

기본적인 공동 작업 기능을 먼저 구현한 뒤 AI와 외부 서비스를 추가한다.

| 단계 | 개발 내용 | 우선순위 |
|---|---|---|
| 1 | Flutter 프로젝트 뼈대 | 완료 (#4) |
| 2 | Supabase 연결 및 인증 | 필수, 완료 (#5) |
| 3 | 여행방 생성 및 초대 코드 | 필수, 완료 (#5) |
| 4 | 실시간 채팅 | 필수, 완료 (#6) |
| 5 | 여행 조건 관리 | 필수, 완료 (PR #9 리뷰 대기) |
| 6 | 여행지 후보 및 투표 | 필수, 완료 (#8) |
| 7 | AI 채팅 분석 | 핵심, 구현 완료 (PR #9, 크레딧 충전 후 확인) |
| 8 | AI 여행지 추천 | 핵심 |
| 9 | 지도 및 장소 검색 | 확장, 보류 (11장 참고) |
| 10 | 공동 일정 관리 | 확장, 보류 (11장 참고) |
| 11 | 항공권 및 숙박 연동 | 확장 |
| 12 | 여행 경비 정산 | 확장 |

## 9.1 MVP 완성 목표

초기 버전은 다음 기능을 구현하는 것을 목표로 한다.

- 회원가입 및 로그인
- 여행방 생성
- 초대 코드 입장
- 실시간 채팅
- 여행 조건 설정
- 여행지 후보 등록
- 투표 및 결과 집계
- AI 여행 조건 추출
- AI 여행지 추천

이 기능들이 서로 다른 기기에서 정상적으로 작동하면 MVP의 핵심 목표를 달성한 것이다.

---

# 10. Codex 개발 지침

Codex가 이 프로젝트를 개발할 때 다음 규칙을 지킨다.

## 10.1 코드 작성 원칙

1. Dart를 기본 언어로 사용한다.
2. 화면 코드와 데이터 처리 코드를 분리한다.
3. 공통 UI는 components 폴더에서 관리한다.
4. Supabase 통신은 services 폴더에서 관리한다.
5. 데이터 타입은 types 폴더에서 관리한다.
6. 중복 코드를 최소화한다.
7. 오류 처리와 로딩 상태를 구현한다.
8. 사용하지 않는 패키지를 추가하지 않는다.

## 10.2 데이터베이스 원칙

1. 데이터베이스 변경은 migration 파일로 관리한다.
2. 테이블 변경 전 기존 데이터와 관계를 확인한다.
3. 모든 여행방 데이터에 적절한 RLS를 적용한다.
4. 사용자 ID는 Supabase Auth와 연결한다.
5. 중복 데이터가 생성되지 않도록 UNIQUE 제약 조건을 적용한다.
6. 클라이언트에서 권한을 임의로 변경하지 못하도록 한다.

## 10.3 AI 개발 원칙

1. OpenAI API 키와 Claude API 키를 클라이언트에 노출하지 않는다. 각 키는 소유자가 Supabase secrets에 직접 등록한다.
2. Edge Functions에서 AI 요청을 처리한다.
3. AI 응답은 구조화된 JSON으로 처리한다.
4. AI가 추출한 조건은 사용자 승인 후 저장한다.
5. AI 추천 결과와 실제 검증된 외부 정보는 구분한다.
6. 기존 조건과 충돌하는 정보는 자동으로 덮어쓰지 않는다.

## 10.4 개발 진행 방식

- 한 번에 모든 기능을 구현하지 않는다.
- 기능 단위로 구현하고 테스트한다.
- 기존 코드의 구조를 먼저 파악한 후 수정한다.
- 파일을 수정할 때 변경 이유를 설명한다.
- 새로운 라이브러리를 설치할 때 설치 목적을 설명한다.
- 오류가 발생하면 원인을 분석한 뒤 수정한다.
- 작업이 끝나면 변경된 파일과 테스트 결과를 정리한다.

---

# 11. 현재 개발 상태 및 다음 작업

## 현재 개발 상태 (2026-11-25)

### 확정한 기술 구성

- 앱: Flutter 3.47.9 / Dart 3.13.7, 상태 관리 Riverpod
- 백엔드: Supabase (`supabase_flutter` 2.18.3). Firebase 계획은 폐기했다.
- Supabase 프로젝트: 김현우 계정의 프로젝트 하나를 팀 공용으로 쓴다. 박영욱은 조직(Team)에 초대받아 같은 프로젝트를 쓴다.
- AI: 채팅 조건 추출은 OpenAI API(`gpt-4.1-mini`), 여행지 추천은 Claude API(`claude-opus-5-5`). 키는 Supabase Edge Functions의 Secrets에 등록한다 (`OPENAI_API_KEY` 등록 완료·크레딧 없음, `ANTHROPIC_API_KEY` 미등록).
- 지도: Google Maps Platform. 결제 계정과 카드 등록이 필요하고, 한국 내 자동차·도보 길찾기는 제한될 수 있다.
- 채팅 위치: 모든 여행방 화면 오른쪽 아래 채팅 버튼을 누르면 아래에서 올라오는 채팅창
- 설정 파일: `env.json` (`env.example.json`을 복사해 Supabase URL과 publishable 키를 넣는다. Git에서 제외)

### GitHub 반영 상태

| PR | 내용 | 상태 |
|---|---|---|
| #4~#6 | Flutter 뼈대, 로그인·여행방, 실시간 채팅 | 머지 완료 |
| #8 | 여행지 후보 등록, 투표, 방장 확정 | 머지 완료 |
| #9 | 채팅 조건 추출(AI), 조건 확인·수정 | 머지 완료 (2026-11-25) |
| #11 → #12 | AI 여행지 추천 | 머지 완료 (2026-11-25) |
| #13 | 장소 후보함, 공동 일정표 | 머지 완료 (2026-11-25) |
| #1 | 중복 활동지 정리 | 충돌, 처리 방법 결정 필요 |

- 11-18에 main에 PR 없이 올라온 `travel_conditions` 구현(커밋 `80777fb`)은 `trip_conditions`와 기능이 겹쳐 PR #9에서 제거했다.
- #11은 대상 브랜치가 #9 브랜치인 채로 머지돼 main에 들어가지 않아서 #12로 다시 옮겼다. **브랜치 위에 쌓은 PR은 머지 전에 대상이 `main`인지 확인한다.**
- 앞으로 main에는 직접 올리지 않고 브랜치 → PR → 리뷰 → 머지 순서로 올린다.

### 구현 완료

**DB** (파일은 `supabase/migrations/`, 파일 이름 순서대로 실행)

| 파일 | 내용 | Supabase 적용 |
|---|---|---|
| `20261118000000_profiles_rooms_members.sql` | `profiles`, `travel_rooms`, `room_members`, `create_room`, `join_room_by_code` | 완료 |
| `20261118010000_messages.sql` | `messages` (실시간 전달) | 완료 |
| `20261118020000_destinations.sql` | `destinations`, `destination_votes`, `confirm_destination` | 완료 |
| `20261118030000_trip_conditions.sql` | `trip_conditions`, `ai_requests` | 완료 |
| `20261118040000_trip_conditions_manual.sql` | 직접 고친 조건 표시 `manual` | 완료 |
| `20261125000000_destination_recommendations.sql` | `destination_recommendations` (AI 추천 결과) | **미적용** |
| `20261125010000_places_itinerary.sql` | `places`, `place_votes`, `itinerary_days`, `itinerary_items`, `reorder_itinerary` | **미적용** |

- RLS: 모든 여행방 데이터는 멤버만 조회·작성. 메시지·후보·투표·장소·좋아요는 본인 이름으로만 작성. 여행지 확정은 방장만, 장소 수정·삭제는 올린 사람만.
- 설계 변경: 5.1의 `condition_proposals`/`travel_conditions` 두 테이블 대신 `trip_conditions` 하나로 구현했다. AI가 정리한 값은 출처 메시지와 AI 추측 여부를 함께 저장하고, 멤버가 직접 고친 값(`manual`)은 AI가 덮어쓰지 않는다.
- 장소 투표는 찬성·반대 대신 '좋아요'(1인 1회)로 단순화했다. 일정 순서는 `reorder_itinerary` 함수로만 바꾸고, 그사이 다른 멤버가 항목을 넣거나 뺐으면 거절한다.

**Edge Function** (대시보드 편집기에 붙여 넣어 배포하므로 함수 하나는 파일 하나)

| 함수 | 내용 | 배포 |
|---|---|---|
| `extract-conditions` | 최근 채팅 80개를 OpenAI로 읽어 인원·날짜·출발지·이동수단·예산·활동 추출. 여행방당 10초에 1번, 하루 30번 | 완료 |
| `recommend-destinations` | 조건과 후보·투표 현황을 Claude로 보내 국내 여행지 3곳, 추천 이유, 조건별 일치 여부, 확인할 점을 저장. 여행방당 30초에 1번, 하루 10번 | **미배포** |

- 두 함수 모두 실패하면 아무것도 저장하지 않고 실패 이유(`reason`: `ai_key_missing`, `ai_no_credit`, `ai_timeout` 등)를 돌려준다.

**앱** (여행방 화면 메뉴 순서)
- 로그인 / 회원가입, 내 여행방 목록, 여행방 만들기, 초대 코드 입장
- 여행방 화면: 초대 코드 표시·복사, 멤버 목록
- 여행 조건: 채팅에서 AI로 정리, 출처 메시지와 "AI 추측"·"직접 입력" 표시, 직접 입력·수정·비우기
- AI 여행지 추천: 최근 추천 3곳과 이유·조건 일치 표시, "투표 후보로 올리기"
- 여행지 투표: 1인당 후보 2개, 찬성·보통·반대, 찬성이 과반이면 방장이 확정
- 장소·일정: 장소 후보함(올리기, 좋아요 순 정렬, 일정에 넣기), 일차별 일정표(일차 추가·삭제, 끌어서 순서 바꾸기, 방문 시간·메모)
- 실시간 채팅창

### 확인 결과

- `flutter analyze` 문제 없음, `flutter test` 41개 통과, 웹 빌드와 Android 디버그 빌드 성공
- 실제 Supabase에서 테스트 계정으로 확인 (11-18까지 적용한 기능)
  - 외부인은 여행방, 멤버, 메시지, 후보, 투표, 조건을 보거나 쓸 수 없음
  - 채팅, 투표, 확정, 조건 수정이 다른 멤버에게 약 0.4초 만에 실시간 도착
- 11-25에 추가한 DB는 Supabase와 비슷한 로컬 DB(PGlite)에 migration 7개를 차례로 적용하고 29개 시나리오를 확인했다 (외부인 차단, 남의 장소·좋아요 삭제 차단, 다른 방 장소 넣기 차단, 순서 직접 수정 차단, 삭제 시 일정 함께 삭제, 순서 충돌 거절).
- `recommend-destinations`는 `@anthropic-ai/sdk@1.8.0` 타입으로 `tsc --strict` 검사를 통과했다.
- **확인 안 됨**
  - AI 조건 추출·AI 추천의 실제 결과 (OpenAI 크레딧 없음, Claude 키 미등록)
  - 추천·장소·일정의 실제 Supabase 동작 (migration 미적용)
  - 기기 2대 동시 확인 (활동지 #10 완료 조건: 5초 이내 반영)
  - Android 에뮬레이터 실행: 켜졌다가 바로 꺼져서 원인 확인 필요 (크롬 실행은 정상)

### 데모 실행

```
flutter run -d chrome --web-port 5180 --dart-define-from-file=env.json
```

브라우저에서 http://localhost:5180 을 연다. 실시간 반영은 시크릿 창에서 다른 계정으로 같은 여행방에 들어가 확인한다.

### PC별 개발 환경

| 항목 | 문서 1.0 작성 PC | 김현우 PC |
|---|---|---|
| Flutter SDK 위치 | `%USERPROFILE%\flutter` | `%USERPROFILE%\develop\flutter` |
| Android SDK | 미설치 | 설치됨, 에뮬레이터 있음, NDK 28.2 설치 |
| 웹 빌드 | 성공 | 성공 |
| Android 빌드 | 불가 | 성공 |

iOS 빌드는 macOS와 Xcode가 필요하다. secret 키와 AI API 키는 앱에 넣지 않는다.

## 배포 전 할 일 (Supabase 대시보드)

1. SQL Editor에서 아직 적용하지 않은 migration 두 개를 순서대로 실행한다: `20261125000000_destination_recommendations.sql` → `20261125010000_places_itinerary.sql`
2. 11-18에 main에 올라왔던 `travel_conditions` 테이블이 Supabase에 만들어졌는지 Table Editor에서 확인한다. 있으면 지운다: `drop table public.travel_conditions; drop function public.bump_travel_conditions_revision();`
3. Edge Functions에서 `recommend-destinations`를 새로 만들고 `supabase/functions/recommend-destinations/index.ts`를 붙여 넣는다.
4. https://console.anthropic.com 에서 크레딧을 충전하고 API 키를 만들어 Secrets에 `ANTHROPIC_API_KEY`로 등록한다. 모델을 바꾸려면 `ANTHROPIC_MODEL`을 추가한다.
5. 시범 운행 2~3일 전에 OpenAI 크레딧을 충전한다 (https://platform.openai.com/settings/organization/billing). 조건 추출 결과와 "직접 고친 값을 AI가 덮어쓰지 않는지"를 확인한다.

## 보류한 작업

### Google 장소 검색과 지도 (활동지 #9) — 보류

공동 일정표(#10)는 장소를 직접 입력하는 방식으로 먼저 만들었다. `places`에 `google_place_id`, `lat`, `lng` 칸을 미리 만들어 두었으니 검색을 붙이면 채운다.

**시작 전에 준비할 것**
1. Google Cloud Console(https://console.cloud.google.com)에서 프로젝트를 만들고 결제 계정(카드)을 등록한다. 무료 사용량 안에서는 요금이 나가지 않는다.
2. **Places API (New)** 와 **Maps SDK for Android / iOS**, **Maps JavaScript API**(웹)를 사용 설정한다.
3. API 키를 만들고 사용할 API와 앱(패키지 이름)으로 제한한다. 장소 검색 키는 Edge Function Secrets(`GOOGLE_MAPS_API_KEY`)에 두고, 지도 표시 키만 앱 설정에 넣는다.

**만들 내용**
- Edge Function `search-places`: 확정된 여행지 근처 장소를 Places API로 검색한다. 키를 앱에 노출하지 않는다.
- 장소 올리기 화면에 검색 결과 고르기를 추가하고, 일정표에 지도 표시(`google_maps_flutter`)를 붙인다.
- 완료 조건(활동지 7주차): "성산일출봉"을 검색하면 장소명, 주소, 좌표가 목록에 표시된다.

### 결정이 필요한 항목

- 개발 중에는 Supabase 가입 확인 메일(Confirm email)을 꺼 두었다. 발표 전에 다시 켤지 정한다.
- 테스트 계정(`qa-`로 시작하는 `@example.com` 계정)을 정리한다.
- PR #1 충돌 처리 방법을 정한다.

## 다음 작업 순서

1. 박영욱의 UI 작업을 GitHub에 올리고, 지금 main과 충돌하는지 확인한 뒤 PR로 합친다.
2. 위 "배포 전 할 일" 1~3을 하고 기기 2대로 추천·장소·일정을 확인한다.
3. 시범 운행 2~3일 전 OpenAI·Claude 크레딧 충전 후 AI 기능 실제 확인
4. Google 장소 검색과 지도 (#9, 결제 계정 준비 후)
5. 13주차 실행 패키지: 세션 복구와 예외 처리(#11), 릴리스 APK와 README(#12)

---

# 12. Codex 첫 번째 작업 지시문

이 문서를 읽은 후 아래 지시문을 사용하여 개발을 시작한다.

## 첫 번째 개발 목표

Flutter와 Dart를 사용하여 공동 여행 계획 앱의 개발 환경을 구축한다.

작업 순서:

1. 현재 VS Code 프로젝트 폴더의 파일 구조를 확인한다.
2. 기존 프로젝트가 있는지 확인한다.
3. Flutter 프로젝트가 없다면 적절한 초기화 방식을 제안한다.
4. Supabase 연결을 위한 패키지를 설치한다.
5. 환경 변수 파일을 구성한다.
6. Supabase 연결 테스트 코드를 작성한다.
7. 실행 방법과 각 파일의 역할을 설명한다.

주의사항:

- 기존 파일을 확인하지 않고 삭제하지 않는다.
- API 키와 비밀번호를 코드에 직접 작성하지 않는다.
- 아직 구현하지 않은 기능을 구현 완료했다고 설명하지 않는다.
- 각 단계를 완료한 뒤 실행 결과를 확인한다.
- 다음 단계로 넘어가기 전에 발생한 오류를 해결한다.

**최종 목표:** 다른 기능을 추가할 수 있는 Flutter + Dart + Supabase 기본 프로젝트를 완성한다.

