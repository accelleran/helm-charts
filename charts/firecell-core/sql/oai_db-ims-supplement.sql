-- Idempotent IMS tables required by cn-agent in oai_db (SHOW TABLES LIKE 'users').
-- Distinct from firecell_nms_api.users (NMS GUI accounts).
USE oai_db;

CREATE TABLE IF NOT EXISTS users (
  imsi       VARCHAR(32) PRIMARY KEY,
  fullname   VARCHAR(64),
  hassip     BOOLEAN,
  context    VARCHAR(64),
  host       VARCHAR(64),
  transport  VARCHAR(16)
);
