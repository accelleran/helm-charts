CREATE DATABASE IF NOT EXISTS firecell_ran_tr069;
USE firecell_ran_tr069;

CREATE TABLE IF NOT EXISTS RanNetworkElement (
  id INT NOT NULL AUTO_INCREMENT,
  ip_address VARCHAR(32),
  device_serial VARCHAR(32) NOT NULL,
  connection_request_url VARCHAR(128),
  oui VARCHAR(32),
  vendor VARCHAR(32),
  gnb_id INT,
  gnb_id_length INT,
  gnb_name VARCHAR(32),
  amf_address VARCHAR(128),
  ue_number INT,
  is_connected BOOLEAN,
  periodic_inform_interval INT NOT NULL DEFAULT 30,
  periodic_inform_enable BOOLEAN,
  last_inform_time DATETIME(3),
  cwmp_id INT,
  adminstate VARCHAR(8),
  PRIMARY KEY (id),
  UNIQUE KEY uq_ranne_device_serial (device_serial),
  UNIQUE KEY uq_ranne_gnb_id (gnb_id),
  KEY idx_ranne_ip_address (ip_address)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Cells (
  id INT NOT NULL AUTO_INCREMENT,
  gnb_id INT NOT NULL,
  nrcell_identity INT NOT NULL,
  cell_local_id INT,
  cell_idx INT,
  phycell_identity INT,
  plmn VARCHAR(32),
  tac INT,
  sst INT,
  sd INT,
  snssai BIGINT UNSIGNED,
  ul_arfcn INT,
  dl_arfcn INT,
  dl_bandwidth INT,
  ul_bandwidth INT,
  tx_antenna INT,
  rx_antenna INT,
  scs INT,
  band VARCHAR(8),
  tdd_slot_config JSON,
  tdd_pattern_alias VARCHAR(64),
  admin_state VARCHAR(8),
  op_state VARCHAR(8),
  max_dl_throughput DECIMAL(10,2),
  max_ul_throughput DECIMAL(10,2),
  num_connected_devices INT,
  dl_carrier_freq VARCHAR(16),
  last_updated DATETIME(3),
  PRIMARY KEY (id),
  UNIQUE KEY uq_cells_gnb_id_nrcell_identity (gnb_id, nrcell_identity),
  KEY idx_cells_gnb_id (gnb_id),
  CONSTRAINT fk_cells_gnb_id
    FOREIGN KEY (gnb_id) REFERENCES RanNetworkElement (gnb_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Gps (
  gnb_id INT NOT NULL,
  sync_status BOOLEAN,
  lockedlongitude FLOAT,
  lockedlatitude FLOAT,
  PRIMARY KEY (gnb_id),
  CONSTRAINT fk_gps_gnb_id
    FOREIGN KEY (gnb_id) REFERENCES RanNetworkElement (gnb_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS PerfMgmt (
  id INT NOT NULL AUTO_INCREMENT,
  device_serial VARCHAR(32),
  enable BOOLEAN,
  url VARCHAR(128),
  upload_interval INT,
  upload_time DATETIME(3),
  username VARCHAR(16),
  password VARCHAR(16),
  PRIMARY KEY (id),
  KEY idx_perfmgmt_device_serial (device_serial),
  CONSTRAINT fk_perfmgmt_device_serial
    FOREIGN KEY (device_serial) REFERENCES RanNetworkElement (device_serial)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Alarms (
  id INT NOT NULL,
  device_serial VARCHAR(32),
  type VARCHAR(64),
  additional_information VARCHAR(256),
  additional_text VARCHAR(256),
  alarm_identifier INT,
  alarm_internal_serial_num INT,
  alarm_raised_time DATETIME(3) NOT NULL,
  alarm_sequence_number INT,
  event_index INT,
  event_time DATETIME(3),
  event_type VARCHAR(128),
  fault_location VARCHAR(256),
  managed_obj_inst VARCHAR(256),
  notification_type VARCHAR(32),
  perceived_severity VARCHAR(64),
  probable_cause VARCHAR(128),
  specific_problem VARCHAR(128),
  PRIMARY KEY (id),
  KEY idx_alarms_device_serial (device_serial),
  CONSTRAINT fk_alarms_device_serial
    FOREIGN KEY (device_serial) REFERENCES RanNetworkElement (device_serial)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS RpcQueue (
  id INT NOT NULL AUTO_INCREMENT,
  ran_ne_id INT NOT NULL,
  device_serial VARCHAR(32) NOT NULL,
  ip_address VARCHAR(32) NOT NULL,
  rpc_type VARCHAR(32) NOT NULL,
  internal_task_type VARCHAR(32) NOT NULL,
  payload JSON,
  created_at DATETIME(3) NOT NULL,
  updated_at DATETIME(3),
  completed_at DATETIME(3),
  status VARCHAR(32) NOT NULL,
  cwmp_id VARCHAR(64),
  command_key VARCHAR(64),
  max_attempt INT NOT NULL DEFAULT 5,
  next_retry_at DATETIME(3),
  retry_count INT NOT NULL DEFAULT 0,
  lease_until DATETIME(3),
  PRIMARY KEY (id),
  KEY idx_rpcqueue_ran_ne_id (ran_ne_id),
  KEY idx_rpcqueue_device_serial_status_created_at (device_serial, status, created_at),
  KEY idx_rpcqueue_command_key (command_key),
  CONSTRAINT fk_rpcqueue_ran_ne_id
    FOREIGN KEY (ran_ne_id) REFERENCES RanNetworkElement (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pm_kpi_catalog (
  id INT NOT NULL,
  vendor VARCHAR(32) NOT NULL DEFAULT 'cloudran',
  kpi_name VARCHAR(64) NOT NULL,
  unit VARCHAR(16),
  category VARCHAR(32),
  calculation_method VARCHAR(32),
  numerator_counters JSON,
  denominator_counters JSON,
  multiplier FLOAT,
  is_active BOOLEAN,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pm_kpi_catalog_vendor_kpi_name (vendor, kpi_name)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS pm_kpi_samples (
  ts DATETIME(3) NOT NULL,
  granularity_s INT NOT NULL,
  ran_ne_id INT NOT NULL,
  cell_pk INT NOT NULL,
  kpi_id INT NOT NULL,
  value DOUBLE,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  is_sent BOOLEAN,
  PRIMARY KEY (cell_pk, granularity_s, kpi_id, ts, is_sent),
  KEY idx_pm_kpi_samples_ran_ne_id (ran_ne_id),
  KEY idx_pm_kpi_samples_kpi_id (kpi_id),
  CONSTRAINT fk_pm_kpi_samples_ran_ne_id
    FOREIGN KEY (ran_ne_id) REFERENCES RanNetworkElement (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_pm_kpi_samples_cell_pk
    FOREIGN KEY (cell_pk) REFERENCES Cells (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_pm_kpi_samples_kpi_id
    FOREIGN KEY (kpi_id) REFERENCES pm_kpi_catalog (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS FileTransferJobs (
  job_id VARCHAR(64) NOT NULL,
  command_key VARCHAR(64) NOT NULL,
  ran_ne_id INT NOT NULL,
  device_serial VARCHAR(32) NOT NULL,
  file_type VARCHAR(32),
  status VARCHAR(32),
  file_path VARCHAR(256),
  file_size INT,
  fault_code INT,
  fault_string VARCHAR(256),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3),
  completed_at DATETIME(3),
  PRIMARY KEY (job_id),
  KEY idx_filetransferjobs_ran_ne_id (ran_ne_id),
  KEY idx_filetransferjobs_device_serial_status (device_serial, status),
  KEY idx_filetransferjobs_command_key (command_key),
  CONSTRAINT fk_filetransferjobs_ran_ne_id
    FOREIGN KEY (ran_ne_id) REFERENCES RanNetworkElement (id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_filetransferjobs_device_serial
    FOREIGN KEY (device_serial) REFERENCES RanNetworkElement (device_serial)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;
