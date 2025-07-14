-- AccGTPThpUl
CREATE TABLE acc_gtp_thp_ul (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value BIGINT
);
SELECT create_hypertable('acc_gtp_thp_ul', 'time');
CREATE INDEX ON acc_gtp_thp_ul (network_function_id, time DESC);
CREATE INDEX ON acc_gtp_thp_ul (ueid, time DESC);
ALTER TABLE acc_gtp_thp_ul SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_gtp_thp_ul', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_gtp_thp_ul', INTERVAL '14 days');
ALTER TABLE acc_gtp_thp_ul OWNER TO {{ .Values.cnpg.auth.username }};

-- AccGTPThpUlQfiSnssaiPlmn
CREATE TABLE acc_gtp_thp_ul_qfi_snssai_plmn (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi_snssai_plmnid TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value BIGINT
);
SELECT create_hypertable('acc_gtp_thp_ul_qfi_snssai_plmn', 'time');
CREATE INDEX ON acc_gtp_thp_ul_qfi_snssai_plmn (network_function_id, time DESC);
CREATE INDEX ON acc_gtp_thp_ul_qfi_snssai_plmn (qfi_snssai_plmnid, time DESC);
CREATE INDEX ON acc_gtp_thp_ul_qfi_snssai_plmn (ueid, time DESC);
ALTER TABLE acc_gtp_thp_ul_qfi_snssai_plmn SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_gtp_thp_ul_qfi_snssai_plmn', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_gtp_thp_ul_qfi_snssai_plmn', INTERVAL '14 days');
ALTER TABLE acc_gtp_thp_ul_qfi_snssai_plmn OWNER TO {{ .Values.cnpg.auth.username }};

-- AccGTPThpDl
CREATE TABLE acc_gtp_thp_dl (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value BIGINT
);
SELECT create_hypertable('acc_gtp_thp_dl', 'time');
CREATE INDEX ON acc_gtp_thp_dl (network_function_id, time DESC);
CREATE INDEX ON acc_gtp_thp_dl (ueid, time DESC);
ALTER TABLE acc_gtp_thp_dl SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_gtp_thp_dl', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_gtp_thp_dl', INTERVAL '14 days');
ALTER TABLE acc_gtp_thp_dl OWNER TO {{ .Values.cnpg.auth.username }};

-- AccGTPThpDlQfiSnssaiPlmn
CREATE TABLE acc_gtp_thp_dl_qfi_snssai_plmn (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    qfi_snssai_plmnid TEXT NOT NULL,
    ueid INTEGER NOT NULL,
    value BIGINT
);
SELECT create_hypertable('acc_gtp_thp_dl_qfi_snssai_plmn', 'time');
CREATE INDEX ON acc_gtp_thp_dl_qfi_snssai_plmn (network_function_id, time DESC);
CREATE INDEX ON acc_gtp_thp_dl_qfi_snssai_plmn (qfi_snssai_plmnid, time DESC);
CREATE INDEX ON acc_gtp_thp_dl_qfi_snssai_plmn (ueid, time DESC);
ALTER TABLE acc_gtp_thp_dl_qfi_snssai_plmn SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('acc_gtp_thp_dl_qfi_snssai_plmn', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('acc_gtp_thp_dl_qfi_snssai_plmn', INTERVAL '14 days');
ALTER TABLE acc_gtp_thp_dl_qfi_snssai_plmn OWNER TO {{ .Values.cnpg.auth.username }};
