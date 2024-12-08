-- start: auto generated add index --

-- chair_locations
-- 	 SELECT * FROM chair_locations WHERE chair_id = ? ORDER BY created_at DESC LIMIT 1
ALTER TABLE chair_locations ADD INDEX idx_chair_id_created_at (chair_id, created_at desc);
-- 	 SELECT * FROM chair_locations WHERE id = ?
-- ALTER TABLE chair_locations ADD INDEX idx_id (id);
-- chairs
-- 	 SELECT * FROM chairs WHERE access_token = ?
ALTER TABLE chairs ADD INDEX idx_access_token (access_token);
-- 	 SELECT * FROM chairs INNER JOIN (SELECT id FROM chairs WHERE is_active = TRUE ORDER BY RAND() LIMIT 1) AS tmp ON chairs.id = tmp.id LIMIT 1
ALTER TABLE chairs ADD INDEX idx_id_is_active (id, is_active);
-- 	 SELECT * FROM chairs WHERE id = ?
-- ALTER TABLE chairs ADD INDEX idx_id (id);
-- 	 SELECT * FROM chairs WHERE owner_id = ?
ALTER TABLE chairs ADD INDEX idx_owner_id (owner_id);
-- coupons
-- 	 SELECT * FROM coupons WHERE code = ? FOR UPDATE
ALTER TABLE coupons ADD INDEX idx_code (code);
-- 	 SELECT * FROM coupons WHERE used_by = ?
ALTER TABLE coupons ADD INDEX idx_used_by (used_by);
-- 	 SELECT * FROM coupons WHERE user_id = ? AND code = 'CP_NEW2024' AND used_by IS NULL FOR UPDATE
-- 	 SELECT * FROM coupons WHERE user_id = ? AND code = 'CP_NEW2024' AND used_by IS NULL
ALTER TABLE coupons ADD INDEX idx_user_id_code_used_by (user_id, code, used_by);
-- 	 SELECT * FROM coupons WHERE user_id = ? AND used_by IS NULL ORDER BY created_at LIMIT 1 FOR UPDATE
-- 	 SELECT * FROM coupons WHERE user_id = ? AND used_by IS NULL ORDER BY created_at LIMIT 1
ALTER TABLE coupons ADD INDEX idx_user_id_used_by_created_at (user_id, used_by, created_at);
-- owners
-- 	 SELECT * FROM owners WHERE access_token = ?
ALTER TABLE owners ADD INDEX idx_access_token (access_token);
-- 	 SELECT * FROM owners WHERE chair_register_token = ?
ALTER TABLE owners ADD INDEX idx_chair_register_token (chair_register_token);
-- 	 SELECT * FROM owners WHERE id = ?
-- ALTER TABLE owners ADD INDEX idx_id (id);
-- payment_tokens
-- 	 SELECT * FROM payment_tokens WHERE user_id = ?
ALTER TABLE payment_tokens ADD INDEX idx_user_id (user_id);
-- ride_statuses
-- 	 SELECT * FROM ride_statuses WHERE ride_id = ? AND app_sent_at IS NULL ORDER BY created_at ASC LIMIT 1
ALTER TABLE ride_statuses ADD INDEX idx_ride_id_app_sent_at_created_at (ride_id, app_sent_at, created_at);
-- 	 SELECT * FROM ride_statuses WHERE ride_id = ? AND chair_sent_at IS NULL ORDER BY created_at ASC LIMIT 1
ALTER TABLE ride_statuses ADD INDEX idx_ride_id_chair_sent_at_created_at (ride_id, chair_sent_at, created_at);
-- 	 SELECT * FROM ride_statuses WHERE ride_id = ? ORDER BY created_at
ALTER TABLE ride_statuses ADD INDEX idx_ride_id_created_at (ride_id, created_at);
-- 	 SELECT status FROM ride_statuses WHERE ride_id = ? ORDER BY created_at DESC LIMIT 1
ALTER TABLE ride_statuses ADD INDEX idx_status_ride_id_created_at (status, ride_id, created_at desc);
-- rides
-- 	 SELECT * FROM rides WHERE chair_id IS NULL ORDER BY created_at LIMIT 1
-- 	 SELECT * FROM rides WHERE chair_id = ? ORDER BY created_at DESC
ALTER TABLE rides ADD INDEX idx_chair_id_created_at (chair_id, created_at desc);
-- 	 SELECT * FROM rides WHERE chair_id = ? ORDER BY updated_at DESC
-- 	 SELECT * FROM rides WHERE chair_id = ? ORDER BY updated_at DESC LIMIT 1
ALTER TABLE rides ADD INDEX idx_chair_id_updated_at (chair_id, updated_at desc);
-- 	 SELECT * FROM rides WHERE id = ?
-- 	 SELECT * FROM rides WHERE id = ? FOR UPDATE
-- ALTER TABLE rides ADD INDEX idx_id (id);
-- 	 SELECT * FROM rides WHERE user_id = ? ORDER BY created_at DESC
-- 	 SELECT * FROM rides WHERE user_id = ? ORDER BY created_at ASC
-- 	 SELECT * FROM rides WHERE user_id = ? ORDER BY created_at DESC LIMIT 1
ALTER TABLE rides ADD INDEX idx_user_id_created_at (user_id, created_at desc);
ALTER TABLE rides ADD INDEX idx_user_id_created_at_desc (user_id, created_at desc);
-- 	 SELECT * FROM rides WHERE user_id = ?
-- 	 SELECT COUNT(*) FROM rides WHERE user_id = ?
ALTER TABLE rides ADD INDEX idx_user_id (user_id);
-- settings
-- 	 SELECT value FROM settings WHERE name = 'payment_gateway_url'
-- ALTER TABLE settings ADD INDEX idx_value_name (value, name);
-- tmp
-- 	 SELECT * FROM chairs INNER JOIN (SELECT id FROM chairs WHERE is_active = TRUE ORDER BY RAND() LIMIT 1) AS tmp ON chairs.id = tmp.id LIMIT 1
-- ALTER TABLE tmp ADD INDEX idx_id (id);
-- users
-- 	 SELECT * FROM users WHERE access_token = ?
ALTER TABLE users ADD INDEX idx_access_token (access_token);
-- 	 SELECT * FROM users WHERE invitation_code = ?
ALTER TABLE users ADD INDEX idx_invitation_code (invitation_code);
-- start: could not determined index --
-- 	 SELECT COUNT(*) = 0 FROM (SELECT COUNT(chair_sent_at) = 6 AS completed FROM ride_statuses WHERE ride_id IN (SELECT id FROM rides WHERE chair_id = ?) GROUP BY ride_id) is_completed WHERE completed = FALSE
-- 	 SELECT rides.* FROM rides JOIN ride_statuses ON rides.id = ride_statuses.ride_id WHERE chair_id = ? AND status = 'COMPLETED' AND updated_at BETWEEN ? AND ? + INTERVAL 999 MICROSECOND
-- end: could not determined index --
-- end: auto generated add index --

DROP TABLE IF EXISTS ride_statuses_latest;
CREATE TABLE ride_statuses_latest (
  id              VARCHAR(26)                                                                NOT NULL,
  ride_id VARCHAR(26)                                                                        NOT NULL COMMENT 'ライドID',
  status          ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NOT NULL COMMENT '状態',
  created_at      DATETIME(6)                                                                NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '状態変更日時',
  app_sent_at     DATETIME(6)                                                                NULL COMMENT 'ユーザーへの状態通知日時',
  chair_sent_at   DATETIME(6)                                                                NULL COMMENT '椅子への状態通知日時',
  PRIMARY KEY (ride_id)
);

DELIMITER //

DROP TRIGGER IF EXISTS after_insert_ride_statuses //
CREATE TRIGGER after_insert_ride_statuses
AFTER INSERT ON ride_statuses
FOR EACH ROW
BEGIN
  INSERT INTO ride_statuses_latest (id, ride_id, status, app_sent_at, chair_sent_at)
  VALUES (NEW.id, NEW.ride_id, NEW.status, NULL, NULL)
  ON DUPLICATE KEY UPDATE
    id = VALUES(id),
    ride_id = VALUES(ride_id),
    status = VALUES(status),
    app_sent_at = NULL,
    chair_sent_at = NULL;
END //

DROP TRIGGER IF EXISTS after_update_ride_statuses //
CREATE TRIGGER after_update_ride_statuses
AFTER UPDATE ON ride_statuses
FOR EACH ROW
BEGIN
  IF NEW.chair_sent_at <> OLD.chair_sent_at THEN
    UPDATE ride_statuses_latest
    SET chair_sent_at = NEW.chair_sent_at
    WHERE id = NEW.id;
  END IF;

  IF NEW.app_sent_at <> OLD.app_sent_at THEN
    UPDATE ride_statuses_latest
    SET app_sent_at = NEW.app_sent_at
    WHERE id = NEW.id;
  END IF;
END //

DELIMITER ;

INSERT INTO ride_statuses_latest (id, ride_id, status, created_at, app_sent_at, chair_sent_at)
SELECT id, ride_id, status, created_at, app_sent_at, chair_sent_at
FROM (
  SELECT id, ride_id, status, created_at, app_sent_at, chair_sent_at,
         ROW_NUMBER() OVER (PARTITION BY ride_id ORDER BY created_at DESC) as rn
  FROM ride_statuses
) sub
WHERE rn = 1
ON DUPLICATE KEY UPDATE
  id = VALUES(id),
  status = VALUES(status),
  created_at = VALUES(created_at),
  app_sent_at = VALUES(app_sent_at),
  chair_sent_at = VALUES(chair_sent_at);

-- 1. chair_distancesテーブルの作成
CREATE TABLE IF NOT EXISTS chair_distances (
  chair_id VARCHAR(26) NOT NULL PRIMARY KEY,
  total_distance DOUBLE NOT NULL DEFAULT 0,
  total_distance_updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
);

-- 2. 既存データの集計と挿入
INSERT INTO chair_distances (chair_id, total_distance, total_distance_updated_at)
SELECT chair_id,
       SUM(IFNULL(distance, 0)) AS total_distance,
       MAX(created_at) AS total_distance_updated_at
FROM (
  SELECT chair_id,
         created_at,
         ABS(latitude - LAG(latitude) OVER (PARTITION BY chair_id ORDER BY created_at)) +
         ABS(longitude - LAG(longitude) OVER (PARTITION BY chair_id ORDER BY created_at)) AS distance
  FROM chair_locations
) tmp
GROUP BY chair_id
ON DUPLICATE KEY UPDATE
  total_distance = VALUES(total_distance),
  total_distance_updated_at = VALUES(total_distance_updated_at);

-- 3. トリガーの作成
DELIMITER //

CREATE TRIGGER after_insert_chair_locations
AFTER INSERT ON chair_locations
FOR EACH ROW
BEGIN
  DECLARE new_distance DOUBLE;
  DECLARE last_latitude DOUBLE;
  DECLARE last_longitude DOUBLE;
  DECLARE last_created_at DATETIME(6);

  -- 前回の位置情報を取得
  SELECT latitude, longitude, created_at INTO last_latitude, last_longitude, last_created_at
  FROM chair_locations
  WHERE chair_id = NEW.chair_id
  ORDER BY created_at DESC
  LIMIT 1, 1;

  -- 前回の位置情報が存在する場合、新しい距離を計算
  IF last_latitude IS NOT NULL AND last_longitude IS NOT NULL THEN
    SET new_distance = IFNULL(ABS(NEW.latitude - last_latitude), ) + IFNULL(ABS(NEW.longitude - last_longitude), 0);
  END IF;

  -- chair_distancesテーブルを更新
  INSERT INTO chair_distances (chair_id, total_distance, total_distance_updated_at)
  VALUES (NEW.chair_id, new_distance, NEW.created_at)
  ON DUPLICATE KEY UPDATE
    total_distance = IFNULL(total_distance, 0) + new_distance,
    total_distance_updated_at = NEW.created_at;
END //

DELIMITER ;

UPDATE chair_distances
SET total_distance = 0
WHERE total_distance IS NULL;
