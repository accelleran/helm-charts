-- DRBPdcpSduDelayDlQoS
CREATE TABLE drb_pdcp_sdu_delay_dl_qos (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_pdcp_sdu_delay_dl_qos', 'time');
CREATE INDEX ON drb_pdcp_sdu_delay_dl_qos (network_function_id, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_qos (qfi, time DESC);
ALTER TABLE drb_pdcp_sdu_delay_dl_qos SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_pdcp_sdu_delay_dl_qos', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_pdcp_sdu_delay_dl_qos', INTERVAL '14 days');
ALTER TABLE drb_pdcp_sdu_delay_dl_qos OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBPdcpSduDelayDlSnssai
CREATE TABLE drb_pdcp_sdu_delay_dl_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_pdcp_sdu_delay_dl_snssai', 'time');
CREATE INDEX ON drb_pdcp_sdu_delay_dl_snssai (network_function_id, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_snssai (snssai, time DESC);
ALTER TABLE drb_pdcp_sdu_delay_dl_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_pdcp_sdu_delay_dl_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_pdcp_sdu_delay_dl_snssai', INTERVAL '14 days');
ALTER TABLE drb_pdcp_sdu_delay_dl_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBPdcpSduDelayDlQfiSnssaiPlmn
CREATE TABLE acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi_snssai_plmnid TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn', 'time');
CREATE INDEX ON acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn (network_function_id, time DESC);
CREATE INDEX ON acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn (qfi_snssai_plmnid, time DESC);
ALTER TABLE acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn', INTERVAL '14 days');
ALTER TABLE acc_drb_pdcp_sdu_delay_dl_qfi_snssai_plmn OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBPdcpSduDelayDlDist
CREATE TABLE drb_pdcp_sdu_delay_dl_dist (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    bin_x INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_pdcp_sdu_delay_dl_dist', 'time');
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist (network_function_id, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist (bin_x, time DESC);
ALTER TABLE drb_pdcp_sdu_delay_dl_dist SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_pdcp_sdu_delay_dl_dist', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_pdcp_sdu_delay_dl_dist', INTERVAL '14 days');
ALTER TABLE drb_pdcp_sdu_delay_dl_dist OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBPdcpSduDelayDlDistQos
CREATE TABLE drb_pdcp_sdu_delay_dl_dist_qos (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi TEXT NOT NULL,
    bin_x INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_pdcp_sdu_delay_dl_dist_qos', 'time');
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist_qos (network_function_id, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist_qos (qfi, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist_qos (bin_x, time DESC);
ALTER TABLE drb_pdcp_sdu_delay_dl_dist_qos SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_pdcp_sdu_delay_dl_dist_qos', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_pdcp_sdu_delay_dl_dist_qos', INTERVAL '14 days');
ALTER TABLE drb_pdcp_sdu_delay_dl_dist_qos OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBPdcpSduDelayDlDistSnssai
CREATE TABLE drb_pdcp_sdu_delay_dl_dist_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    bin_x INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_pdcp_sdu_delay_dl_dist_snssai', 'time');
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist_snssai (network_function_id, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist_snssai (snssai, time DESC);
CREATE INDEX ON drb_pdcp_sdu_delay_dl_dist_snssai (bin_x, time DESC);
ALTER TABLE drb_pdcp_sdu_delay_dl_dist_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_pdcp_sdu_delay_dl_dist_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_pdcp_sdu_delay_dl_dist_snssai', INTERVAL '14 days');
ALTER TABLE drb_pdcp_sdu_delay_dl_dist_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBPdcpSduDelayDlDistQfiSnssaiPlmn
CREATE TABLE acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi_snssai_plmnid TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn', 'time');
CREATE INDEX ON acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn (network_function_id, time DESC);
CREATE INDEX ON acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn (qfi_snssai_plmnid, time DESC);
ALTER TABLE acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn', INTERVAL '14 days');
ALTER TABLE acc_drb_pdcp_sdu_delay_dl_dist_qfi_snssai_plmn OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBEstabAtt5QiSnssai
CREATE TABLE acc_drb_estab_att_5qi_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    fiveqi INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_estab_att_5qi_snssai', 'time');
CREATE INDEX ON acc_drb_estab_att_5qi_snssai (network_function_id, time DESC);
CREATE INDEX ON acc_drb_estab_att_5qi_snssai (snssai, time DESC);
CREATE INDEX ON acc_drb_estab_att_5qi_snssai (fiveqi, time DESC);
ALTER TABLE acc_drb_estab_att_5qi_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_drb_estab_att_5qi_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_drb_estab_att_5qi_snssai', INTERVAL '14 days');
ALTER TABLE acc_drb_estab_att_5qi_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBEstabAttSnssai
CREATE TABLE drb_estab_att_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_estab_att_snssai', 'time');
CREATE INDEX ON drb_estab_att_snssai (network_function_id, time DESC);
CREATE INDEX ON drb_estab_att_snssai (snssai, time DESC);
ALTER TABLE drb_estab_att_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_estab_att_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_estab_att_snssai', INTERVAL '14 days');
ALTER TABLE drb_estab_att_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBEstabAtt5Qi
CREATE TABLE drb_estab_att_5qi (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    fiveqi INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_estab_att_5qi', 'time');
CREATE INDEX ON drb_estab_att_5qi (network_function_id, time DESC);
CREATE INDEX ON drb_estab_att_5qi (fiveqi, time DESC);
ALTER TABLE drb_estab_att_5qi SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_estab_att_5qi', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_estab_att_5qi', INTERVAL '14 days');
ALTER TABLE drb_estab_att_5qi OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBEstabSucc5QiSnssai
CREATE TABLE acc_drb_estab_succ_5qi_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    fiveqi INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_estab_succ_5qi_snssai', 'time');
CREATE INDEX ON acc_drb_estab_succ_5qi_snssai (network_function_id, time DESC);
CREATE INDEX ON acc_drb_estab_succ_5qi_snssai (snssai, time DESC);
CREATE INDEX ON acc_drb_estab_succ_5qi_snssai (fiveqi, time DESC);
ALTER TABLE acc_drb_estab_succ_5qi_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_drb_estab_succ_5qi_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_drb_estab_succ_5qi_snssai', INTERVAL '14 days');
ALTER TABLE acc_drb_estab_succ_5qi_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBEstabSucc5Qi
CREATE TABLE drb_estab_succ_5qi (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    fiveqi INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_estab_succ_5qi', 'time');
CREATE INDEX ON drb_estab_succ_5qi (network_function_id, time DESC);
CREATE INDEX ON drb_estab_succ_5qi (fiveqi, time DESC);
ALTER TABLE drb_estab_succ_5qi SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_estab_succ_5qi', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_estab_succ_5qi', INTERVAL '14 days');
ALTER TABLE drb_estab_succ_5qi OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBEstabSuccSnssai
CREATE TABLE drb_estab_succ_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_estab_succ_snssai', 'time');
CREATE INDEX ON drb_estab_succ_snssai (network_function_id, time DESC);
CREATE INDEX ON drb_estab_succ_snssai (snssai, time DESC);
ALTER TABLE drb_estab_succ_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_estab_succ_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_estab_succ_snssai', INTERVAL '14 days');
ALTER TABLE drb_estab_succ_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBRelActNbr5QiSnssai
CREATE TABLE drb_rel_act_nbr_5qi_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    fiveqi INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_rel_act_nbr_5qi_snssai', 'time');
CREATE INDEX ON drb_rel_act_nbr_5qi_snssai (network_function_id, time DESC);
CREATE INDEX ON drb_rel_act_nbr_5qi_snssai (snssai, time DESC);
CREATE INDEX ON drb_rel_act_nbr_5qi_snssai (fiveqi, time DESC);
ALTER TABLE drb_rel_act_nbr_5qi_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_rel_act_nbr_5qi_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_rel_act_nbr_5qi_snssai', INTERVAL '14 days');
ALTER TABLE drb_rel_act_nbr_5qi_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBRelActNbr5Qi
CREATE TABLE drb_rel_act_nbr_5qi (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    fiveqi INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_rel_act_nbr_5qi', 'time');
CREATE INDEX ON drb_rel_act_nbr_5qi (network_function_id, time DESC);
CREATE INDEX ON drb_rel_act_nbr_5qi (fiveqi, time DESC);
ALTER TABLE drb_rel_act_nbr_5qi SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_rel_act_nbr_5qi', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_rel_act_nbr_5qi', INTERVAL '14 days');
ALTER TABLE drb_rel_act_nbr_5qi OWNER TO {{ .Values.cnpg.auth.username }};

-- DRBRelActNbrSnssai
CREATE TABLE drb_rel_act_nbr_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('drb_rel_act_nbr_snssai', 'time');
CREATE INDEX ON drb_rel_act_nbr_snssai (network_function_id, time DESC);
CREATE INDEX ON drb_rel_act_nbr_snssai (snssai, time DESC);
ALTER TABLE drb_rel_act_nbr_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('drb_rel_act_nbr_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('drb_rel_act_nbr_snssai', INTERVAL '14 days');
ALTER TABLE drb_rel_act_nbr_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBF1UPacketLossRateUlQoS
CREATE TABLE acc_drb_f1u_packet_loss_rate_ul_qos (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_f1u_packet_loss_rate_ul_qos', 'time');
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_qos (network_function_id, time DESC);
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_qos (qfi, time DESC);
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_qos (ueid, time DESC);
ALTER TABLE acc_drb_f1u_packet_loss_rate_ul_qos SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_drb_f1u_packet_loss_rate_ul_qos', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_drb_f1u_packet_loss_rate_ul_qos', INTERVAL '14 days');
ALTER TABLE acc_drb_f1u_packet_loss_rate_ul_qos OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBF1UPacketLossRateUlSnssai
CREATE TABLE acc_drb_f1u_packet_loss_rate_ul_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    ueid INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_f1u_packet_loss_rate_ul_snssai', 'time');
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_snssai (network_function_id, time DESC);
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_snssai (snssai, time DESC);
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_snssai (ueid, time DESC);
ALTER TABLE acc_drb_f1u_packet_loss_rate_ul_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_drb_f1u_packet_loss_rate_ul_snssai', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_drb_f1u_packet_loss_rate_ul_snssai', INTERVAL '14 days');
ALTER TABLE acc_drb_f1u_packet_loss_rate_ul_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBF1UPacketLossRateUlQfiSnssaiPlmn
CREATE TABLE acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi_snssai_plmnid TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn', 'time');
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn (network_function_id, time DESC);
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn (qfi_snssai_plmnid, time DESC);
CREATE INDEX ON acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn (ueid, time DESC);
ALTER TABLE acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_retention_policy('acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn', INTERVAL '14 days');
ALTER TABLE acc_drb_f1u_packet_loss_rate_ul_qfi_snssai_plmn OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBPdcpPacketDropRateDlQoS
CREATE TABLE acc_drb_pdcp_packet_drop_rate_dl_qos (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    qfi TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_pdcp_packet_drop_rate_dl_qos', 'time');
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_qos (network_function_id, time DESC);
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_qos (ueid, time DESC);
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_qos (qfi, time DESC);
ALTER TABLE acc_drb_pdcp_packet_drop_rate_dl_qos SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_retention_policy('acc_drb_pdcp_packet_drop_rate_dl_qos', INTERVAL '14 days');
ALTER TABLE acc_drb_pdcp_packet_drop_rate_dl_qos OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBPdcpPacketDropRateDlSnssai
CREATE TABLE acc_drb_pdcp_packet_drop_rate_dl_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    snssai BIGINT NOT NULL,
    ueid INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_pdcp_packet_drop_rate_dl_snssai', 'time');
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_snssai (network_function_id, time DESC);
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_snssai (snssai, time DESC);
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_snssai (ueid, time DESC);
ALTER TABLE acc_drb_pdcp_packet_drop_rate_dl_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_retention_policy('acc_drb_pdcp_packet_drop_rate_dl_snssai', INTERVAL '14 days');
ALTER TABLE acc_drb_pdcp_packet_drop_rate_dl_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- AccDRBPdcpPacketDropRateDlQfiSnssaiPlmn
CREATE TABLE acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi_snssai_plmnid TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn', 'time');
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn (network_function_id, time DESC);
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn (qfi_snssai_plmnid, time DESC);
CREATE INDEX ON acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn (ueid, time DESC);
ALTER TABLE acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_retention_policy('acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn', INTERVAL '14 days');
ALTER TABLE acc_drb_pdcp_packet_drop_rate_dl_qfi_snssai_plmn OWNER TO {{ .Values.cnpg.auth.username }};
