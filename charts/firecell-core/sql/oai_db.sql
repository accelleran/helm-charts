-- Firecell 5G Core Database Initialization
-- This script creates all required databases and tables for OAI 5G Core NFs.

-- ============================================================
-- NMS API Database
-- ============================================================
CREATE DATABASE IF NOT EXISTS firecell_nms_api;
USE firecell_nms_api;

CREATE TABLE CoreNetworkElement (
  id integer PRIMARY KEY AUTO_INCREMENT,
  address VARCHAR(128),
  name VARCHAR(128),
  status VARCHAR(32),
  isHealthy BOOLEAN,
  ipPoolAddress VARCHAR(32),
  ipPoolNetmask VARCHAR(32),
  bitrateMaxUplink INT,
  bitrateMaxDownlink INT,
  opKey VARCHAR(32)
);
CREATE TABLE Plmn (
  id integer PRIMARY KEY AUTO_INCREMENT,
  core_id INT,
  plmn VARCHAR(32),
  mnc VARCHAR(32),
  mcc VARCHAR(32),
  mnc_length INT
);
CREATE TABLE Snssai (
  core_id_plmn VARCHAR(32) PRIMARY KEY,
  core_id INT,
  plmn VARCHAR(32),
  sst INT,
  sd VARCHAR(32)
);
CREATE TABLE coreBitrates (
  id integer PRIMARY KEY AUTO_INCREMENT,
  cnId INT,
  uplink INT,
  downlink INT,
  timestamp DATETIME
);
CREATE TABLE coreResources (
  id integer PRIMARY KEY AUTO_INCREMENT,
  cnId INT,
  uplink INT,
  downlink INT,
  timestamp DATETIME
);
CREATE TABLE RanNetworkElement (
  id integer PRIMARY KEY AUTO_INCREMENT,
  cnId INT,
  address VARCHAR(32),
  name VARCHAR(32),
  type VARCHAR(32),
  position VARCHAR(32),
  frequencyBand VARCHAR(32),
  tac INT,
  ran_type VARCHAR(32),
  ran_id_length INT,
  ran_id INT,
  n3_ip_address VARCHAR(64),
  connectivity BOOLEAN,
  is_alive BOOLEAN
);
CREATE TABLE ranN3Bitrates (
  id integer PRIMARY KEY AUTO_INCREMENT,
  ran_id INT,
  uplink INT,
  downlink INT,
  timestamp DATETIME
);
CREATE TABLE coreN3Bitrates (
  id integer PRIMARY KEY AUTO_INCREMENT,
  core_id INT,
  uplink FLOAT,
  downlink FLOAT,
  timestamp DATETIME
);
CREATE TABLE cells (
  id VARCHAR(32) PRIMARY KEY,
  coreId INT,
  ranId INT,
  name VARCHAR(32),
  type VARCHAR(32),
  status VARCHAR(32),
  position VARCHAR(32),
  bandwidth INT,
  frequency INT,
  scs INT,
  uplinkBandwidth INT,
  downlinkBandwidth INT,
  online_devices INT,
  frequencyBand VARCHAR(32),
  tac INT,
  nr_cell_id VARCHAR(32),
  ran_id INT,
  tx_layer INT,
  rx_layer INT,
  tdd_pattern INT
);
CREATE TABLE cellBitrates (
  id integer PRIMARY KEY AUTO_INCREMENT,
  cellId VARCHAR(32),
  uplink INT,
  downlink INT,
  timestamp DATETIME
);
CREATE TABLE cellResources (
  id integer PRIMARY KEY AUTO_INCREMENT,
  cellId VARCHAR(32),
  uplink FLOAT,
  downlink FLOAT,
  timestamp DATETIME
);
CREATE TABLE cellDevicesHistory (
  id integer PRIMARY KEY AUTO_INCREMENT,
  cellId VARCHAR(32),
  devices INT,
  timestamp DATETIME
);
CREATE TABLE devices (
  imsi VARCHAR(32) PRIMARY KEY,
  cellId VARCHAR(32),
  imei VARCHAR(32),
  name VARCHAR(32),
  type VARCHAR(32),
  status VARCHAR(32),
  tac INT,
  encryptionKey VARCHAR(64),
  opKey VARCHAR(64),
  opcKey VARCHAR(64),
  isIpAllocatedStatic BOOLEAN,
  ipAddress VARCHAR(64),
  qos VARCHAR(64),
  dnn_id INT
);
CREATE TABLE ipPool (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ipAddress VARCHAR(64),
  dnn_id INT,
  isIpAllocatedStatic BOOLEAN,
  imsi VARCHAR(32)
);
CREATE TABLE dnn (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(64) UNIQUE,
  subnet VARCHAR(64)
);
CREATE TABLE ueBitrates (
  id integer PRIMARY KEY AUTO_INCREMENT,
  ueId INT,
  uplink INT,
  downlink INT,
  timestamp DATETIME
);
CREATE TABLE ueResources (
  id integer PRIMARY KEY AUTO_INCREMENT,
  ueId INT,
  uplink INT,
  downlink INT,
  timestamp DATETIME
);
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32),
  firstName VARCHAR(32),
  role VARCHAR(32),
  isAdmin BOOLEAN,
  email VARCHAR(32),
  hashPassword VARCHAR(255),
  isFirstConnexion BOOLEAN,
  theme VARCHAR(32),
  language VARCHAR(32)
);
CREATE TABLE connexion_tokens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT,
  token VARCHAR(255),
  expirationDate DATETIME
);
CREATE TABLE password_tokens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  userId INT,
  token VARCHAR(255),
  expirationDate DATETIME
);
CREATE TABLE userLog (
  id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
  userId INT NOT NULL,
  user VARCHAR(255) NOT NULL,
  log VARCHAR(255) NOT NULL,
  date DATETIME NOT NULL
);
CREATE TABLE networkLog (
  id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
  log VARCHAR(255) NOT NULL,
  date DATETIME NOT NULL
);
CREATE TABLE qos (
  id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
  rule_order INT,
  ip VARCHAR(32),
  mask INT,
  port_start INT,
  port_stop INT,
  type_of_service INT,
  direction ENUM ('source', 'destination', 'both'),
  category INT,
  description VARCHAR(255),
  derived_rule_name VARCHAR(32),
  flow_description_index INT
);
CREATE TABLE IF NOT EXISTS Version (
  version VARCHAR(64) PRIMARY KEY
);
TRUNCATE TABLE Version;
INSERT INTO Version (version) VALUES ('4.1.0');

CREATE TABLE IF NOT EXISTS initialNetworkConnection (
  id VARCHAR(32) PRIMARY KEY,
  connectionFlag INT
);
INSERT INTO initialNetworkConnection (id, connectionFlag)
VALUES ("initialNetworkConnection", 0);

CREATE TABLE IF NOT EXISTS nmsInitialization (
  id INT PRIMARY KEY AUTO_INCREMENT,
  initializationKey VARCHAR(32) UNIQUE NOT NULL,
  isInitialized BOOLEAN NOT NULL
);
INSERT INTO nmsInitialization (initializationKey, isInitialized)
VALUES ("nmsStartup", 0);

INSERT INTO users (name, firstName, role, isAdmin, email, hashPassword, isFirstConnexion, language, theme)
VALUES ("admin", "admin", "admin", 1, "admin",
  "pbkdf2:sha256:260000$RBEVcdUh9Vr0TsuJ$d0339f2afc51fc9480cd79b4e36c5b782ebcc0bc2514d96e4da437d213c8bb38",
  0, "en", "light");

-- ============================================================
-- OAI Core Database
-- ============================================================
CREATE DATABASE IF NOT EXISTS oai_db;
USE oai_db;

-- DnnPolicyDecision
DROP TABLE IF EXISTS `DnnPolicyDecision_PccRuleIds`;
DROP TABLE IF EXISTS `DnnPolicyDecision`;

CREATE TABLE `DnnPolicyDecision` (
  `Dnn` VARCHAR(128) NOT NULL PRIMARY KEY,
  `DnnIsSet` TINYINT(1) NOT NULL,
  `PccRuleIdsIsSet` TINYINT(1) NOT NULL)
ENGINE=InnoDB;

CREATE TABLE `DnnPolicyDecision_PccRuleIds` (
  `object_id` VARCHAR(128) NOT NULL,
  `index` BIGINT UNSIGNED NOT NULL,
  `value` TEXT NOT NULL,
  CONSTRAINT `DnnPolicyDecision_PccRuleIds_object_id_fk`
    FOREIGN KEY (`object_id`)
    REFERENCES `DnnPolicyDecision` (`Dnn`)
    ON DELETE CASCADE)
ENGINE=InnoDB;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

-- AccessAndMobilitySubscriptionData
CREATE TABLE `AccessAndMobilitySubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `servingPlmnid` varchar(15) NOT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `gpsis` json DEFAULT NULL,
  `internalGroupIds` json DEFAULT NULL,
  `sharedVnGroupDataIds` json DEFAULT NULL,
  `subscribedUeAmbr` json DEFAULT NULL,
  `nssai` json DEFAULT NULL,
  `ratRestrictions` json DEFAULT NULL,
  `forbiddenAreas` json DEFAULT NULL,
  `serviceAreaRestriction` json DEFAULT NULL,
  `coreNetworkTypeRestrictions` json DEFAULT NULL,
  `rfspIndex` int(10) DEFAULT NULL,
  `subsRegTimer` int(10) DEFAULT NULL,
  `ueUsageType` int(10) DEFAULT NULL,
  `mpsPriority` tinyint(1) DEFAULT NULL,
  `mcsPriority` tinyint(1) DEFAULT NULL,
  `activeTime` int(10) DEFAULT NULL,
  `sorInfo` json DEFAULT NULL,
  `sorInfoExpectInd` tinyint(1) DEFAULT NULL,
  `sorafRetrieval` tinyint(1) DEFAULT NULL,
  `sorUpdateIndicatorList` json DEFAULT NULL,
  `upuInfo` json DEFAULT NULL,
  `micoAllowed` tinyint(1) DEFAULT NULL,
  `sharedAmDataIds` json DEFAULT NULL,
  `odbPacketServices` json DEFAULT NULL,
  `serviceGapTime` int(10) DEFAULT NULL,
  `mdtUserConsent` json DEFAULT NULL,
  `mdtConfiguration` json DEFAULT NULL,
  `traceData` json DEFAULT NULL,
  `cagData` json DEFAULT NULL,
  `stnSr` varchar(50) DEFAULT NULL,
  `cMsisdn` varchar(50) DEFAULT NULL,
  `nbIoTUePriority` int(10) DEFAULT NULL,
  `nssaiInclusionAllowed` tinyint(1) DEFAULT NULL,
  `rgWirelineCharacteristics` varchar(50) DEFAULT NULL,
  `ecRestrictionDataWb` json DEFAULT NULL,
  `ecRestrictionDataNb` tinyint(1) DEFAULT NULL,
  `expectedUeBehaviourList` json DEFAULT NULL,
  `primaryRatRestrictions` json DEFAULT NULL,
  `secondaryRatRestrictions` json DEFAULT NULL,
  `edrxParametersList` json DEFAULT NULL,
  `ptwParametersList` json DEFAULT NULL,
  `iabOperationAllowed` tinyint(1) DEFAULT NULL,
  `wirelineForbiddenAreas` json DEFAULT NULL,
  `wirelineServiceAreaRestriction` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Amf3GppAccessRegistration
CREATE TABLE `Amf3GppAccessRegistration` (
  `ueid` varchar(15) NOT NULL,
  `amfInstanceId` varchar(50) NOT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `purgeFlag` tinyint(1) DEFAULT NULL,
  `pei` varchar(50) DEFAULT NULL,
  `imsVoPs` json DEFAULT NULL,
  `deregCallbackUri` varchar(255) NOT NULL,
  `amfServiceNameDereg` json DEFAULT NULL,
  `pcscfRestorationCallbackUri` varchar(255) DEFAULT NULL,
  `amfServiceNamePcscfRest` json DEFAULT NULL,
  `initialRegistrationInd` tinyint(1) DEFAULT NULL,
  `guami` json NOT NULL,
  `backupAmfInfo` json DEFAULT NULL,
  `drFlag` tinyint(1) DEFAULT NULL,
  `ratType` json NOT NULL,
  `urrpIndicator` tinyint(1) DEFAULT NULL,
  `amfEeSubscriptionId` varchar(50) DEFAULT NULL,
  `epsInterworkingInfo` json DEFAULT NULL,
  `ueSrvccCapability` tinyint(1) DEFAULT NULL,
  `registrationTime` varchar(50) DEFAULT NULL,
  `vgmlcAddress` json DEFAULT NULL,
  `contextInfo` json DEFAULT NULL,
  `noEeSubscriptionInd` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- AuthenticationStatus
CREATE TABLE `AuthenticationStatus` (
  `ueid` varchar(20) NOT NULL,
  `nfInstanceId` varchar(50) NOT NULL,
  `success` tinyint(1) NOT NULL,
  `timeStamp` varchar(50) NOT NULL,
  `authType` varchar(25) NOT NULL,
  `servingNetworkName` varchar(50) NOT NULL,
  `authRemovalInd` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- AuthenticationSubscription
CREATE TABLE `AuthenticationSubscription` (
  `ueid` varchar(20) NOT NULL,
  `authenticationMethod` varchar(25) NOT NULL,
  `encPermanentKey` varchar(50) DEFAULT NULL,
  `protectionParameterId` varchar(50) DEFAULT NULL,
  `sequenceNumber` json DEFAULT NULL,
  `authenticationManagementField` varchar(50) DEFAULT NULL,
  `algorithmId` varchar(50) DEFAULT NULL,
  `encOpcKey` varchar(50) DEFAULT NULL,
  `encTopcKey` varchar(50) DEFAULT NULL,
  `vectorGenerationInHss` tinyint(1) DEFAULT NULL,
  `n5gcAuthMethod` varchar(15) DEFAULT NULL,
  `rgAuthenticationInd` tinyint(1) DEFAULT NULL,
  `supi` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- SdmSubscriptions
CREATE TABLE `SdmSubscriptions` (
  `ueid` varchar(15) NOT NULL,
  `subsId` int(10) UNSIGNED NOT NULL,
  `nfInstanceId` varchar(50) NOT NULL,
  `implicitUnsubscribe` tinyint(1) DEFAULT NULL,
  `expires` varchar(50) DEFAULT NULL,
  `callbackReference` varchar(255) NOT NULL,
  `amfServiceName` json DEFAULT NULL,
  `monitoredResourceUris` json NOT NULL,
  `singleNssai` json DEFAULT NULL,
  `dnn` varchar(50) DEFAULT NULL,
  `subscriptionId` varchar(50) DEFAULT NULL,
  `plmnId` json DEFAULT NULL,
  `immediateReport` tinyint(1) DEFAULT NULL,
  `report` json DEFAULT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `contextInfo` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- SessionManagementSubscriptionData
CREATE TABLE `SessionManagementSubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `servingPlmnid` varchar(15) NOT NULL,
  `singleNssai` json NOT NULL,
  `dnnConfigurations` json DEFAULT NULL,
  `internalGroupIds` json DEFAULT NULL,
  `sharedVnGroupDataIds` json DEFAULT NULL,
  `sharedDnnConfigurationsId` varchar(50) DEFAULT NULL,
  `odbPacketServices` json DEFAULT NULL,
  `traceData` json DEFAULT NULL,
  `sharedTraceDataId` varchar(50) DEFAULT NULL,
  `expectedUeBehavioursList` json DEFAULT NULL,
  `suggestedPacketNumDlList` json DEFAULT NULL,
  `3gppChargingCharacteristics` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- SmfRegistrations
CREATE TABLE `SmfRegistrations` (
  `ueid` varchar(15) NOT NULL,
  `subpduSessionId` int(10) NOT NULL,
  `smfInstanceId` varchar(50) NOT NULL,
  `smfSetId` varchar(50) DEFAULT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `pduSessionId` int(10) NOT NULL,
  `singleNssai` json NOT NULL,
  `dnn` varchar(50) DEFAULT NULL,
  `emergencyServices` tinyint(1) DEFAULT NULL,
  `pcscfRestorationCallbackUri` varchar(255) DEFAULT NULL,
  `plmnId` json NOT NULL,
  `pgwFqdn` varchar(50) DEFAULT NULL,
  `epdgInd` tinyint(1) DEFAULT NULL,
  `deregCallbackUri` varchar(255) DEFAULT NULL,
  `registrationReason` json DEFAULT NULL,
  `registrationTime` varchar(50) DEFAULT NULL,
  `contextInfo` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- SmfSelectionSubscriptionData
CREATE TABLE `SmfSelectionSubscriptionData` (
  `ueid` varchar(15) NOT NULL,
  `servingPlmnid` varchar(15) NOT NULL,
  `supportedFeatures` varchar(50) DEFAULT NULL,
  `subscribedSnssaiInfos` json DEFAULT NULL,
  `sharedSnssaiInfosId` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Indexes
ALTER TABLE `AccessAndMobilitySubscriptionData` ADD PRIMARY KEY (`ueid`,`servingPlmnid`) USING BTREE;
ALTER TABLE `Amf3GppAccessRegistration` ADD PRIMARY KEY (`ueid`);
ALTER TABLE `AuthenticationStatus` ADD PRIMARY KEY (`ueid`);
ALTER TABLE `AuthenticationSubscription` ADD PRIMARY KEY (`ueid`);
ALTER TABLE `SdmSubscriptions` ADD PRIMARY KEY (`subsId`,`ueid`) USING BTREE;
ALTER TABLE `SessionManagementSubscriptionData` ADD PRIMARY KEY (`ueid`,`servingPlmnid`) USING BTREE;
ALTER TABLE `SmfRegistrations` ADD PRIMARY KEY (`ueid`,`subpduSessionId`) USING BTREE;
ALTER TABLE `SmfSelectionSubscriptionData` ADD PRIMARY KEY (`ueid`,`servingPlmnid`) USING BTREE;
ALTER TABLE `SdmSubscriptions` MODIFY `subsId` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

-- PCF Policy Tables
DROP TABLE IF EXISTS `PccRuleODB_RefQosMon`;
DROP TABLE IF EXISTS `PccRuleODB_RefUmN3gData`;
DROP TABLE IF EXISTS `PccRuleODB_RefUmData`;
DROP TABLE IF EXISTS `PccRuleODB_RefChgN3gData`;
DROP TABLE IF EXISTS `PccRuleODB_RefChgData`;
DROP TABLE IF EXISTS `PccRuleODB_RefTcData`;
DROP TABLE IF EXISTS `PccRuleODB_RefAltQosParams`;
DROP TABLE IF EXISTS `PccRuleODB_RefQosData`;
DROP TABLE IF EXISTS `PccRuleODB`;

CREATE TABLE `PccRuleODB` (
  `FlowInfos` TEXT NOT NULL,
  `FlowInfosIsSet` TINYINT(1) NOT NULL,
  `AppId` TEXT NOT NULL,
  `AppIdIsSet` TINYINT(1) NOT NULL,
  `AppDescriptor` TEXT NOT NULL,
  `AppDescriptorIsSet` TINYINT(1) NOT NULL,
  `ContVer` INT NOT NULL,
  `ContVerIsSet` TINYINT(1) NOT NULL,
  `PccRuleId` VARCHAR(128) NOT NULL PRIMARY KEY,
  `Precedence` INT NOT NULL,
  `PrecedenceIsSet` TINYINT(1) NOT NULL,
  `AfSigProtocol` TEXT NOT NULL,
  `AfSigProtocolIsSet` TINYINT(1) NOT NULL,
  `AppReloc` TINYINT(1) NOT NULL,
  `AppRelocIsSet` TINYINT(1) NOT NULL,
  `RefQosDataIsSet` TINYINT(1) NOT NULL,
  `RefAltQosParamsIsSet` TINYINT(1) NOT NULL,
  `RefTcDataIsSet` TINYINT(1) NOT NULL,
  `RefChgDataIsSet` TINYINT(1) NOT NULL,
  `RefChgN3gDataIsSet` TINYINT(1) NOT NULL,
  `RefUmDataIsSet` TINYINT(1) NOT NULL,
  `RefUmN3gDataIsSet` TINYINT(1) NOT NULL,
  `RefCondData` TEXT NOT NULL,
  `RefCondDataIsSet` TINYINT(1) NOT NULL,
  `RefQosMonIsSet` TINYINT(1) NOT NULL,
  `AddrPreserInd` TINYINT(1) NOT NULL,
  `AddrPreserIndIsSet` TINYINT(1) NOT NULL,
  `TscaiInputDl` TEXT NOT NULL,
  `TscaiInputDlIsSet` TINYINT(1) NOT NULL,
  `TscaiInputUl` TEXT NOT NULL,
  `TscaiInputUlIsSet` TINYINT(1) NOT NULL,
  `DdNotifCtrl` TEXT NOT NULL,
  `DdNotifCtrlIsSet` TINYINT(1) NOT NULL,
  `DdNotifCtrl2` TEXT NOT NULL,
  `DdNotifCtrl2IsSet` TINYINT(1) NOT NULL,
  `DisUeNotif` TINYINT(1) NOT NULL,
  `DisUeNotifIsSet` TINYINT(1) NOT NULL)
ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefQosData` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefQosData_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefAltQosParams` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefAltQosParams_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefTcData` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefTcData_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefChgData` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefChgData_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefChgN3gData` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefChgN3gData_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefUmData` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefUmData_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefUmN3gData` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefUmN3gData_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

CREATE TABLE `PccRuleODB_RefQosMon` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `PccRuleODB_RefQosMon_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `PccRuleODB` (`PccRuleId`) ON DELETE CASCADE) ENGINE=InnoDB;

-- QosData
DROP TABLE IF EXISTS `QosData`;
CREATE TABLE `QosData` (
  `QosId` VARCHAR(128) NOT NULL PRIMARY KEY,
  `r_5qi` INT NOT NULL, `r_5qiIsSet` TINYINT(1) NOT NULL,
  `MaxbrUl` TEXT NOT NULL, `MaxbrUlIsSet` TINYINT(1) NOT NULL,
  `MaxbrDl` TEXT NOT NULL, `MaxbrDlIsSet` TINYINT(1) NOT NULL,
  `GbrUl` TEXT NOT NULL, `GbrUlIsSet` TINYINT(1) NOT NULL,
  `GbrDl` TEXT NOT NULL, `GbrDlIsSet` TINYINT(1) NOT NULL,
  `Arp_PriorityLevel` INT NOT NULL,
  `Arp_PreemptCap_value_value` ENUM('INVALID_VALUE_OPENAPI_GENERATED', 'NOT_PREEMPT', 'MAY_PREEMPT') NOT NULL,
  `Arp_PreemptVuln_value_value` ENUM('INVALID_VALUE_OPENAPI_GENERATED', 'NOT_PREEMPTABLE', 'PREEMPTABLE') NOT NULL,
  `ArpIsSet` TINYINT(1) NOT NULL,
  `Qnc` TINYINT(1) NOT NULL, `QncIsSet` TINYINT(1) NOT NULL,
  `PriorityLevel` INT NOT NULL, `PriorityLevelIsSet` TINYINT(1) NOT NULL,
  `AverWindow` INT NOT NULL, `AverWindowIsSet` TINYINT(1) NOT NULL,
  `MaxDataBurstVol` INT NOT NULL, `MaxDataBurstVolIsSet` TINYINT(1) NOT NULL,
  `ReflectiveQos` TINYINT(1) NOT NULL, `ReflectiveQosIsSet` TINYINT(1) NOT NULL,
  `SharingKeyDl` TEXT NOT NULL, `SharingKeyDlIsSet` TINYINT(1) NOT NULL,
  `SharingKeyUl` TEXT NOT NULL, `SharingKeyUlIsSet` TINYINT(1) NOT NULL,
  `MaxPacketLossRateDl` INT NOT NULL, `MaxPacketLossRateDlIsSet` TINYINT(1) NOT NULL,
  `MaxPacketLossRateUl` INT NOT NULL, `MaxPacketLossRateUlIsSet` TINYINT(1) NOT NULL,
  `DefQosFlowIndication` TINYINT(1) NOT NULL, `DefQosFlowIndicationIsSet` TINYINT(1) NOT NULL,
  `ExtMaxDataBurstVol` INT NOT NULL, `ExtMaxDataBurstVolIsSet` TINYINT(1) NOT NULL,
  `PacketDelayBudget` INT NOT NULL, `PacketDelayBudgetIsSet` TINYINT(1) NOT NULL,
  `PacketErrorRate` TEXT NOT NULL, `PacketErrorRateIsSet` TINYINT(1) NOT NULL)
ENGINE=InnoDB;

-- SlicePolicyDecision
DROP TABLE IF EXISTS `SlicePolicyDecision_PccRuleIds`;
DROP TABLE IF EXISTS `SlicePolicyDecision`;

CREATE TABLE `SlicePolicyDecision` (
  `Snssai_Sst` INT NOT NULL, `Snssai_Sd` VARCHAR(128) NOT NULL,
  `Snssai_SdIsSet` TINYINT(1) NOT NULL, `SnssaiIsSet` TINYINT(1) NOT NULL,
  `PccRuleIdsIsSet` TINYINT(1) NOT NULL,
  PRIMARY KEY (`Snssai_Sst`, `Snssai_Sd`, `Snssai_SdIsSet`)) ENGINE=InnoDB;

CREATE TABLE `SlicePolicyDecision_PccRuleIds` (
  `object_id_Sst` INT NOT NULL, `object_id_Sd` VARCHAR(128) NOT NULL,
  `object_id_SdIsSet` TINYINT(1) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `SlicePolicyDecision_PccRuleIds_object_id_fk` FOREIGN KEY (`object_id_Sst`, `object_id_Sd`, `object_id_SdIsSet`)
  REFERENCES `SlicePolicyDecision` (`Snssai_Sst`, `Snssai_Sd`, `Snssai_SdIsSet`) ON DELETE CASCADE) ENGINE=InnoDB;

-- SupiPolicyDecision
DROP TABLE IF EXISTS `SupiPolicyDecision_PccRuleIds`;
DROP TABLE IF EXISTS `SupiPolicyDecision`;

CREATE TABLE `SupiPolicyDecision` (
  `Supi` VARCHAR(128) NOT NULL PRIMARY KEY,
  `SupiIsSet` TINYINT(1) NOT NULL, `PccRuleIdsIsSet` TINYINT(1) NOT NULL) ENGINE=InnoDB;

CREATE TABLE `SupiPolicyDecision_PccRuleIds` (
  `object_id` VARCHAR(128) NOT NULL, `index` BIGINT UNSIGNED NOT NULL, `value` TEXT NOT NULL,
  CONSTRAINT `SupiPolicyDecision_PccRuleIds_object_id_fk` FOREIGN KEY (`object_id`) REFERENCES `SupiPolicyDecision` (`Supi`) ON DELETE CASCADE) ENGINE=InnoDB;

-- TrafficControlDataODB
DROP TABLE IF EXISTS `TrafficControlDataODB`;
CREATE TABLE `TrafficControlDataODB` (
  `TcId` VARCHAR(128) NOT NULL PRIMARY KEY,
  `FlowStatus` TEXT NOT NULL, `FlowStatusIsSet` TINYINT(1) NOT NULL,
  `RedirectInfo` TEXT NOT NULL, `RedirectInfoIsSet` TINYINT(1) NOT NULL,
  `AddRedirectInfo` TEXT NOT NULL, `AddRedirectInfoIsSet` TINYINT(1) NOT NULL,
  `MuteNotif` TINYINT(1) NOT NULL, `MuteNotifIsSet` TINYINT(1) NOT NULL,
  `TrafficSteeringPolIdDl` TEXT NOT NULL, `TrafficSteeringPolIdDlIsSet` TINYINT(1) NOT NULL,
  `TrafficSteeringPolIdUl` TEXT NOT NULL, `TrafficSteeringPolIdUlIsSet` TINYINT(1) NOT NULL,
  `RouteToLocs` TEXT NOT NULL, `RouteToLocsIsSet` TINYINT(1) NOT NULL,
  `TraffCorreInd` TINYINT(1) NOT NULL, `TraffCorreIndIsSet` TINYINT(1) NOT NULL,
  `UpPathChgEvent` TEXT NOT NULL, `UpPathChgEventIsSet` TINYINT(1) NOT NULL,
  `SteerFun` TEXT NOT NULL, `SteerFunIsSet` TINYINT(1) NOT NULL,
  `SteerModeDl` TEXT NOT NULL, `SteerModeDlIsSet` TINYINT(1) NOT NULL,
  `SteerModeUl` TEXT NOT NULL, `SteerModeUlIsSet` TINYINT(1) NOT NULL,
  `MulAccCtrl` TEXT NOT NULL, `MulAccCtrlIsSet` TINYINT(1) NOT NULL) ENGINE=InnoDB;

-- IMS SIP table
CREATE TABLE IF NOT EXISTS sip (
  id INT PRIMARY KEY AUTO_INCREMENT,
  language VARCHAR(8), tcpenable BOOLEAN, tcpbindaddr VARCHAR(64),
  tcpbindport INT, srvlookup ENUM('yes','no') NOT NULL DEFAULT 'no',
  ims_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO sip (id, language, tcpenable, tcpbindaddr, tcpbindport, srvlookup)
VALUES (1, 'en', 1, '0.0.0.0', 5060, 'yes')
ON DUPLICATE KEY UPDATE language=VALUES(language), tcpenable=VALUES(tcpenable),
  tcpbindaddr=VALUES(tcpbindaddr), tcpbindport=VALUES(tcpbindport),
  srvlookup=VALUES(srvlookup), ims_date=CURRENT_TIMESTAMP;

-- IMS subscriber table (cn-agent checks SHOW TABLES LIKE 'users' in oai_db)
CREATE TABLE IF NOT EXISTS users (
  imsi       VARCHAR(32) PRIMARY KEY,
  fullname   VARCHAR(64),
  hassip     BOOLEAN,
  context    VARCHAR(64),
  host       VARCHAR(64),
  transport  VARCHAR(16)
);
