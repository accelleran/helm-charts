-- RRCConnMean
CREATE TABLE rrc_conn_mean (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('rrc_conn_mean', 'time');
CREATE INDEX ON rrc_conn_mean (network_function_id, time DESC);
CREATE INDEX ON rrc_conn_mean (nr_cell_id, time DESC);
CREATE INDEX ON rrc_conn_mean (plmn_id, time DESC);
ALTER TABLE rrc_conn_mean SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_conn_mean', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('rrc_conn_mean', INTERVAL '14 days');
ALTER TABLE rrc_conn_mean OWNER TO {{ .Values.cnpg.auth.username }};

-- RRCConnMax
CREATE TABLE rrc_conn_max (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('rrc_conn_max', 'time');
CREATE INDEX ON rrc_conn_max (network_function_id, time DESC);
CREATE INDEX ON rrc_conn_max (nr_cell_id, time DESC);
CREATE INDEX ON rrc_conn_max (plmn_id, time DESC);
ALTER TABLE rrc_conn_max SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_conn_max', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('rrc_conn_max', INTERVAL '14 days');
ALTER TABLE rrc_conn_max OWNER TO {{ .Values.cnpg.auth.username }};

-- RRCConnEstabAtt
CREATE TABLE rrc_conn_estab_att (
    time TIMESTAMPTZ NOT NULL,
    cause_type TEXT NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('rrc_conn_estab_att', 'time');
CREATE INDEX ON rrc_conn_estab_att (network_function_id, time DESC);
CREATE INDEX ON rrc_conn_estab_att (cause_type, time DESC);
CREATE INDEX ON rrc_conn_estab_att (nr_cell_id, time DESC);
CREATE INDEX ON rrc_conn_estab_att (plmn_id, time DESC);
ALTER TABLE rrc_conn_estab_att SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_conn_estab_att', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('rrc_conn_estab_att', INTERVAL '14 days');
ALTER TABLE rrc_conn_estab_att OWNER TO {{ .Values.cnpg.auth.username }};

-- RRCConnEstabSucc
CREATE TABLE rrc_conn_estab_succ (
    time TIMESTAMPTZ NOT NULL,
    cause_type TEXT NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('rrc_conn_estab_succ', 'time');
CREATE INDEX ON rrc_conn_estab_succ (network_function_id, time DESC);
CREATE INDEX ON rrc_conn_estab_succ (cause_type, time DESC);
CREATE INDEX ON rrc_conn_estab_succ (nr_cell_id, time DESC);
CREATE INDEX ON rrc_conn_estab_succ (plmn_id, time DESC);
ALTER TABLE rrc_conn_estab_succ SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_conn_estab_succ', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('rrc_conn_estab_succ', INTERVAL '14 days');
ALTER TABLE rrc_conn_estab_succ OWNER TO {{ .Values.cnpg.auth.username }};

-- RRCConnReestabAtt
CREATE TABLE rrc_conn_reestab_att (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('rrc_conn_reestab_att', 'time');
CREATE INDEX ON rrc_conn_reestab_att (network_function_id, time DESC);
CREATE INDEX ON rrc_conn_reestab_att (nr_cell_id, time DESC);
CREATE INDEX ON rrc_conn_reestab_att (plmn_id, time DESC);
ALTER TABLE rrc_conn_reestab_att SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_conn_reestab_att', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('rrc_conn_reestab_att', INTERVAL '14 days');
ALTER TABLE rrc_conn_reestab_att OWNER TO {{ .Values.cnpg.auth.username }};

-- RRCConnReestabSucc
CREATE TABLE rrc_conn_reestab_succ (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('rrc_conn_reestab_succ', 'time');
CREATE INDEX ON rrc_conn_reestab_succ (network_function_id, time DESC);
CREATE INDEX ON rrc_conn_reestab_succ (nr_cell_id, time DESC);
CREATE INDEX ON rrc_conn_reestab_succ (plmn_id, time DESC);
ALTER TABLE rrc_conn_reestab_succ SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_conn_reestab_succ', compress_after => INTERVAL '7 days');
SELECT add_retention_policy('rrc_conn_reestab_succ', INTERVAL '14 days');
ALTER TABLE rrc_conn_reestab_succ OWNER TO {{ .Values.cnpg.auth.username }};
