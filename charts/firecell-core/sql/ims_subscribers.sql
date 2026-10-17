-- IMS lab subscribers — UDR (oai_db) is SoT (CAP-1 / D3).
-- Lab: PLMN 999/99, realm ims.mnc099.mcc999.3gppnetwork.org, UE 999990000000002.
-- Apply via: scripts/ims-udr-seed-apply.sh  (or kubectl exec mysql-0 … mysql oai_db < this file)
-- Additive: does not remove existing Auth/AM rows. Merges DNN ims @ 5QI 5 into SM JSON.
--
-- Note: ims-cx-gateway CX_SOT=udr (default) hydrates ims_hss_db from this table +
-- AuthenticationSubscription on Cx lookup. SAR S-CSCF binding → CxScscfBinding
-- (sql/cx_scscf_binding.sql). ims-cx-seed.sh is only for CX_SOT=legacy.

USE oai_db;

-- Merge DNN ims with signalling 5QI 5 (lab ueid is bare IMSI, servingPlmnid 99999).
INSERT INTO SessionManagementSubscriptionData (ueid, servingPlmnid, singleNssai, dnnConfigurations)
VALUES (
  '999990000000002',
  '99999',
  '{"sst": 1, "sd": "000001"}',
  '{"ims": {"pduSessionTypes": {"defaultSessionType": "IPV4V6"}, "sscModes": {"defaultSscMode": "SSC_MODE_1"}, "sessionAmbr": {"uplink": "100Mbps", "downlink": "100Mbps"}, "5gQosProfile": {"5qi": 5, "arp": {"priorityLevel": 1, "preemptCap": "NOT_PREEMPT", "preemptVuln": "NOT_PREEMPTABLE"}}}}'
)
ON DUPLICATE KEY UPDATE
  dnnConfigurations = JSON_MERGE_PATCH(COALESCE(dnnConfigurations, '{}'), VALUES(dnnConfigurations));

CREATE TABLE IF NOT EXISTS ImsSubscriptionData (
  ueid varchar(20) NOT NULL PRIMARY KEY,
  impi varchar(128) NOT NULL,
  impu varchar(128) NOT NULL,
  msisdn varchar(32) DEFAULT NULL,
  ims_user_data_xml mediumtext NOT NULL,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO ImsSubscriptionData (ueid, impi, impu, msisdn, ims_user_data_xml)
VALUES (
  '999990000000002',
  'imsi-999990000000002@ims.mnc099.mcc999.3gppnetwork.org',
  'sip:imsi-999990000000002@ims.mnc099.mcc999.3gppnetwork.org',
  '999990000000002',
  '<?xml version="1.0" encoding="UTF-8"?><IMSSubscription><PrivateID>imsi-999990000000002@ims.mnc099.mcc999.3gppnetwork.org</PrivateID><ServiceProfile><PublicIdentity><Identity>sip:imsi-999990000000002@ims.mnc099.mcc999.3gppnetwork.org</Identity></PublicIdentity><InitialFilterCriteria><Priority>1</Priority><TriggerPoint><ConditionTypeCNF>0</ConditionTypeCNF><SPT><ConditionNegated>0</ConditionNegated><Group>0</Group><Method>REGISTER</Method></SPT></TriggerPoint><ApplicationServer><ServerName>sip:scscf.ims.mnc099.mcc999.3gppnetwork.org</ServerName><DefaultHandling>0</DefaultHandling></ApplicationServer></InitialFilterCriteria></ServiceProfile></IMSSubscription>'
)
ON DUPLICATE KEY UPDATE
  impi = VALUES(impi),
  impu = VALUES(impu),
  msisdn = VALUES(msisdn),
  ims_user_data_xml = VALUES(ims_user_data_xml);
