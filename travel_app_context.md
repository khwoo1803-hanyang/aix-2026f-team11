# 공동 여행 계획 앱 프로젝트 컨텍스트

> VS Code / Codex 개발 참고 문서  
> 버전: 1.1 (2026-11-11 기술 구성과 진행 상황 최신화)  
> 프로젝트 상태: Flutter 뼈대 생성(GitHub 미반영), Supabase 프로젝트 생성, 테이블과 MVP 기능은 구현 전

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
| 1 | Flutter 프로젝트 뼈대 | 로컬 완료 (GitHub 미반영) |
| 2 | Supabase 연결 및 인증 | 필수 |
| 3 | 여행방 생성 및 초대 코드 | 필수 |
| 4 | 실시간 채팅 | 필수 |
| 5 | 여행 조건 관리 | 필수 |
| 6 | 여행지 후보 및 투표 | 필수 |
| 7 | AI 채팅 분석 | 핵심 |
| 8 | AI 여행지 추천 | 핵심 |
| 9 | 지도 및 장소 검색 | 확장 |
| 10 | 공동 일정 관리 | 확장 |
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

## 현재 개발 상태 (2026-11-11)

### 확정한 기술 구성

- 앱: Flutter 3.47.9 / Dart 3.13.7, 상태 관리 Riverpod
- 백엔드: Supabase (`supabase_flutter` 2.18.3). Firebase 계획은 폐기했다.
- AI: 채팅 조건 추출은 OpenAI API, 여행지 추천은 Claude API. 키는 각 소유자가 Supabase secrets에 직접 등록한다.
- 지도: Google Maps Platform. 결제 계정과 카드 등록이 필요하고, 한국 내 자동차·도보 길찾기는 제한될 수 있다.

### PC별 개발 환경

| 항목 | 문서 1.0 작성 PC | 김현우 PC |
|---|---|---|
| Flutter SDK 위치 | `%USERPROFILE%\flutter` | `%USERPROFILE%\develop\flutter` (OneDrive 밖으로 복사, PATH 변경 전) |
| Android SDK | 미설치 | 설치됨, 에뮬레이터 있음, NDK 28.2 미설치 |
| 웹 빌드 | 성공 | 성공 |
| Android 빌드 | 불가 | 실패 (NDK 28.2 필요) |
| 설정 파일 | `.env.json` | `env.json` |

iOS 빌드는 macOS와 Xcode가 필요하다. 설정 파일에는 Supabase URL과 publishable 키만 넣고, `--dart-define-from-file`로 전달한다. secret 키와 AI API 키는 앱에 넣지 않는다.

### 구현 상태

- 김현우 PC의 `feature/flutter-setup`에 Flutter 뼈대가 있다. 앱 시작, Supabase 초기화 코드, 임시 시작 화면까지이고 아직 GitHub에 올리지 않았다. `main`에는 Flutter 프로젝트가 없다.
- 위 뼈대는 코드 분석과 테스트 2개를 통과했다. 기기나 브라우저에서 실행해 보지는 않았다.
- Supabase 프로젝트는 생성했다. 연결 테스트, 테이블, RLS, Edge Functions는 구현 전이다.
- 로그인, 여행방, 채팅, 투표, AI, 지도 기능은 구현 전이다.

### 결정이 필요한 항목

- Flutter 뼈대가 두 PC에 따로 있으면 어느 쪽을 기준으로 할지 정한다.
- 설정 파일 이름을 `.env.json`과 `env.json` 중 하나로 통일한다.
- 지도와 공동 일정표를 11주차 MVP에 포함할지 정한다. 활동지 7주차는 포함, 이 문서 9장은 확장 기능으로 되어 있다.
- 채팅 위치를 하단 탭과 오른쪽 아래 채팅 버튼 중 하나로 정한다.

## 다음 작업 순서

### STEP 1. 개발 환경 구성 (일부 완료)
- Flutter 3.47.9 / Dart 3.13.7 설치 확인 완료
- VS Code 및 Codex 연결
- Flutter 개발 환경 구성 (웹 빌드 확인, Android는 NDK 28.2 설치 후 재확인 필요)
- Android, iOS, Web Flutter 프로젝트 생성 완료 (로컬, GitHub 미반영)

### STEP 2. Supabase 설정
- Supabase 프로젝트 생성 (완료)
- 환경 변수 설정 (URL 입력 완료, publishable 키 미입력)
- Supabase SDK 설치 (완료)
- 데이터베이스 연결 확인 (미완료)

### STEP 3. 데이터베이스 구축
- 초기 SQL Migration 작성
- 핵심 테이블 생성
- 외래 키 및 UNIQUE 제약 조건
- RLS 정책 작성
- 데이터 조회 테스트

### STEP 4. 첫 번째 기능 구현
- 회원가입
- 로그인
- 메인 화면
- 여행방 생성
- 초대 코드 입장

### STEP 5. 공동 작업 기능
- 멤버 관리
- 실시간 채팅
- 여행 조건 저장
- 투표 기능

### STEP 6. AI 및 여행 기능
- 채팅 분석
- 여행지 추천
- 지도 검색
- 공동 일정 관리

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

