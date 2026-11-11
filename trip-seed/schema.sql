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
