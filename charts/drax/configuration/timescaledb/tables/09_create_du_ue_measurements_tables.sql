-- DUUEMeasurements
CREATE TABLE du_ue_measurements (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    acc_sch_ue_pci INTEGER NOT NULL,
    acc_sch_ue_rnti INTEGER NOT NULL,
    acc_sch_ue_cqi INTEGER,
    acc_sch_ue_rank_indicator DOUBLE PRECISION,
    acc_sch_ue_dl_mcs INTEGER,
    acc_sch_ue_dl_data_rate DOUBLE PRECISION,
    acc_sch_ue_dl_harq_acks INTEGER,
    acc_sch_ue_dl_harq_nacks INTEGER,
    acc_sch_ue_dl_harq_retransmissions DOUBLE PRECISION,
    acc_sch_ue_ul_bsr INTEGER,
    acc_sch_ue_avg_pusch_snr DOUBLE PRECISION,
    acc_sch_ue_avg_pucch_snr DOUBLE PRECISION,
    acc_sch_ue_avg_pusch_rsrp DOUBLE PRECISION,
    acc_sch_ue_ul_mcs INTEGER,
    acc_sch_ue_ul_data_rate DOUBLE PRECISION,
    acc_sch_ue_ul_harq_acks INTEGER,
    acc_sch_ue_ul_harq_nacks INTEGER,
    acc_sch_ue_ul_harq_retransmissions DOUBLE PRECISION,
    acc_sch_ue_dl_buffer_status INTEGER,
    acc_sch_ue_ta BIGINT,
    acc_sch_ue_phr INTEGER
);

SELECT create_hypertable('du_ue_measurements', 'time');

CREATE INDEX ON du_ue_measurements (acc_sch_ue_rnti, time DESC);
CREATE INDEX ON du_ue_measurements (acc_sch_ue_pci, time DESC);
CREATE INDEX ON du_ue_measurements (network_function_id, time DESC);

ALTER TABLE du_ue_measurements SET (
  timescaledb.compress,
  timescaledb.compress_orderby = 'time DESC',
  timescaledb.compress_segmentby = 'acc_sch_ue_rnti'
);

SELECT add_compression_policy('du_ue_measurements', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('du_ue_measurements', INTERVAL '24 hours');
ALTER TABLE du_ue_measurements OWNER TO {{ .Values.cnpg.auth.username }};
