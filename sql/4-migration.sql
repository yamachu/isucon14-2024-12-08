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

CREATE TABLE ride_statuses_latest (
  ride_id VARCHAR(26)                                                                        NOT NULL PRIMARY KEY COMMENT 'ライドID',
  status          ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NOT NULL COMMENT '状態',
);

DELIMITER //

CREATE TRIGGER after_insert_ride_statuses
AFTER INSERT ON ride_statuses
FOR EACH ROW
BEGIN
  INSERT INTO ride_statuses_latest (ride_id, status)
  VALUES (NEW.ride_id, NEW.status)
  ON DUPLICATE KEY UPDATE
    ride_id = VALUES(ride_id),
    status = VALUES(status);
END //

DELIMITER ;

