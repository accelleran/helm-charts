-- DURLCMeasurements
CREATE TABLE du_rlc_measurements (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    acc_du_id INTEGER NOT NULL,
    acc_ue_id INTEGER NOT NULL,
    acc_sch_ue_rnti INTEGER NOT NULL,
    acc_drb_id INTEGER NOT NULL,
    acc_rlc_dl_num_sdus INTEGER,
    acc_rlc_dl_num_sdu_pulled INTEGER,
    acc_rlc_dl_num_sdu_bytes INTEGER,
    acc_rlc_dl_num_sdu_dropped INTEGER,
    acc_rlc_dl_num_sdu_discarded INTEGER,
    acc_rlc_dl_num_sdu_failed_discard INTEGER,
    acc_rlc_dl_tot_sdu_latency INTEGER,
    acc_rlc_dl_ave_sdu_latency DOUBLE PRECISION,
    acc_rlc_dl_num_pdu_no_segment INTEGER,
    acc_rlc_dl_num_pdu_bytes_no_segment INTEGER,
    acc_rlc_dl_mode INTEGER,
    acc_rlc_dl_num_small_alloc INTEGER,
    acc_rlc_dl_num_pdu_segmentation INTEGER,
    acc_rlc_dl_num_pdu_bytes_segmentation INTEGER,
    acc_rlc_dl_num_pdu_retx INTEGER,
    acc_rlc_dl_num_pdu_bytes_retx INTEGER,
    acc_rlc_dl_num_pdu_ctrl INTEGER,
    acc_rlc_dl_num_pdu_bytes_ctrl INTEGER,
    acc_rlc_ul_num_sdus INTEGER,
    acc_rlc_ul_num_sdu_bytes INTEGER,
    acc_rlc_ul_num_pdus INTEGER,
    acc_rlc_ul_num_pdu_bytes INTEGER,
    acc_rlc_ul_num_pdu_lost INTEGER,
    acc_rlc_ul_num_pdu_malformed INTEGER,
    acc_rlc_ul_mode INTEGER,
    acc_rlc_ul_num_sdu_segments INTEGER,
    acc_rlc_ul_num_sdu_bytes_segment INTEGER,
    acc_rlc_ul_num_pdu_ctrl INTEGER,
    acc_rlc_ul_num_pdu_bytes_ctrl INTEGER
);

SELECT create_hypertable('du_rlc_measurements', 'time');

CREATE INDEX ON du_rlc_measurements (acc_ue_id, time DESC);
CREATE INDEX ON du_rlc_measurements (acc_du_id, time DESC);
CREATE INDEX ON du_rlc_measurements (network_function_id, time DESC);

ALTER TABLE du_rlc_measurements SET (
  timescaledb.compress,
  timescaledb.compress_orderby = 'time DESC',
  timescaledb.compress_segmentby = 'acc_ue_id'
);

SELECT add_compression_policy('du_rlc_measurements', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('du_rlc_measurements', INTERVAL '24 hours');
ALTER TABLE du_rlc_measurements OWNER TO {{ .Values.cnpg.auth.username }};
