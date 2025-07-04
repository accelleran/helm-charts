-- SMPDUSessionSetupReq
CREATE TABLE smp_du_session_setup_req (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('smp_du_session_setup_req', 'time');
CREATE INDEX ON smp_du_session_setup_req (network_function_id, time DESC);
CREATE INDEX ON smp_du_session_setup_req (nr_cell_id, time DESC);
CREATE INDEX ON smp_du_session_setup_req (plmn_id, time DESC);
ALTER TABLE smp_du_session_setup_req SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('smp_du_session_setup_req', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('smp_du_session_setup_req', INTERVAL '180 days');
ALTER TABLE smp_du_session_setup_req OWNER TO {{ .Values.cnpg.auth.username }};

-- SMPDUSessionSetupReqSnssai
CREATE TABLE smp_du_session_setup_req_snssai (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    snssai INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('smp_du_session_setup_req_snssai', 'time');
CREATE INDEX ON smp_du_session_setup_req_snssai (network_function_id, time DESC);
CREATE INDEX ON smp_du_session_setup_req_snssai (nr_cell_id, time DESC);
CREATE INDEX ON smp_du_session_setup_req_snssai (plmn_id, time DESC);
CREATE INDEX ON smp_du_session_setup_req_snssai (snssai, time DESC);
ALTER TABLE smp_du_session_setup_req_snssai SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('smp_du_session_setup_req_snssai', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('smp_du_session_setup_req_snssai', INTERVAL '180 days');
ALTER TABLE smp_du_session_setup_req_snssai OWNER TO {{ .Values.cnpg.auth.username }};

-- SMPDUSessionSetupFail
CREATE TABLE smp_du_session_setup_fail (
    time TIMESTAMPTZ NOT NULL,
    cause_type TEXT NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('smp_du_session_setup_fail', 'time');
CREATE INDEX ON smp_du_session_setup_fail (network_function_id, time DESC);
CREATE INDEX ON smp_du_session_setup_fail (cause_type, time DESC);
CREATE INDEX ON smp_du_session_setup_fail (nr_cell_id, time DESC);
CREATE INDEX ON smp_du_session_setup_fail (plmn_id, time DESC);
ALTER TABLE smp_du_session_setup_fail SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('smp_du_session_setup_fail', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('smp_du_session_setup_fail', INTERVAL '180 days');
ALTER TABLE smp_du_session_setup_fail OWNER TO {{ .Values.cnpg.auth.username }};
