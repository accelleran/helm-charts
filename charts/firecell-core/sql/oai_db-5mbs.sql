-- 5MBS subscription data of the UDR (cn5g-udr L5-MBS-UDR-1: GET 5mbs-data, TS 29.505 5.2.46;
-- data type TS 29.503 6.1.6.2.84). The same table as build/scripts/oai_db_v2.sql of cn5g-udr, made
-- idempotent so that it also runs on a database that has the other tables.
-- Runs once, when the MySQL data directory is first initialised, like the other init scripts; on a
-- running database run this file with mysql.

USE oai_db;

CREATE TABLE IF NOT EXISTS `MbsSubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `mbsAllowed` tinyint(1) DEFAULT NULL,
  `mbsSessionIdList` json DEFAULT NULL,
  `ueMbsAssistanceInfo` json DEFAULT NULL,
  PRIMARY KEY (ueid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
