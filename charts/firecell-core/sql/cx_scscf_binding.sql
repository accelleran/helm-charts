-- Cx-on-UDR Slice 2: tiny Cx-state table for S-CSCF binding (not a subscriber SoT).
-- Keyed by bare ueid/IMSI. Populated by ims-cx-gateway on SAR; restored on hydrate.
-- Apply: kubectl exec mysql-0 -- mysql oai_db < this file  (or cx_gateway_init.sh CREATE)

USE oai_db;

CREATE TABLE IF NOT EXISTS CxScscfBinding (
  ueid varchar(20) NOT NULL PRIMARY KEY,
  scscf varchar(512) DEFAULT NULL,
  scscf_realm varchar(512) DEFAULT NULL,
  scscf_peer varchar(512) DEFAULT NULL,
  scscf_timestamp datetime DEFAULT NULL,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
