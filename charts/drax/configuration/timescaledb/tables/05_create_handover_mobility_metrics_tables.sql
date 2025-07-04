-- MMHoExeInterReqTimeMean
CREATE TABLE mm_ho_exe_inter_req_time_mean (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_exe_inter_req_time_mean', 'time');
CREATE INDEX ON mm_ho_exe_inter_req_time_mean (network_function_id, time DESC);
CREATE INDEX ON mm_ho_exe_inter_req_time_mean (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_exe_inter_req_time_mean (plmn_id, time DESC);
ALTER TABLE mm_ho_exe_inter_req_time_mean SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_exe_inter_req_time_mean', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_exe_inter_req_time_mean', INTERVAL '180 days');
ALTER TABLE mm_ho_exe_inter_req_time_mean OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoExeInterReqTimeMax
CREATE TABLE mm_ho_exe_inter_req_time_max (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_exe_inter_req_time_max', 'time');
CREATE INDEX ON mm_ho_exe_inter_req_time_max (network_function_id, time DESC);
CREATE INDEX ON mm_ho_exe_inter_req_time_max (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_exe_inter_req_time_max (plmn_id, time DESC);
ALTER TABLE mm_ho_exe_inter_req_time_max SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_exe_inter_req_time_max', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_exe_inter_req_time_max', INTERVAL '180 days');
ALTER TABLE mm_ho_exe_inter_req_time_max OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoPrepInterReq
CREATE TABLE mm_ho_prep_inter_req (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_prep_inter_req', 'time');
CREATE INDEX ON mm_ho_prep_inter_req (network_function_id, time DESC);
CREATE INDEX ON mm_ho_prep_inter_req (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_prep_inter_req (plmn_id, time DESC);
ALTER TABLE mm_ho_prep_inter_req SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_prep_inter_req', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_prep_inter_req', INTERVAL '180 days');
ALTER TABLE mm_ho_prep_inter_req OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoPrepInterSucc
CREATE TABLE mm_ho_prep_inter_succ (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_prep_inter_succ', 'time');
CREATE INDEX ON mm_ho_prep_inter_succ (network_function_id, time DESC);
CREATE INDEX ON mm_ho_prep_inter_succ (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_prep_inter_succ (plmn_id, time DESC);
ALTER TABLE mm_ho_prep_inter_succ SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_prep_inter_succ', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_prep_inter_succ', INTERVAL '180 days');
ALTER TABLE mm_ho_prep_inter_succ OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoPrepInterFail
CREATE TABLE mm_ho_prep_inter_fail (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    cause_type TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_prep_inter_fail', 'time');
CREATE INDEX ON mm_ho_prep_inter_fail (network_function_id, time DESC);
CREATE INDEX ON mm_ho_prep_inter_fail (cause_type, time DESC);
CREATE INDEX ON mm_ho_prep_inter_fail (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_prep_inter_fail (plmn_id, time DESC);
ALTER TABLE mm_ho_prep_inter_fail SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_prep_inter_fail', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_prep_inter_fail', INTERVAL '180 days');
ALTER TABLE mm_ho_prep_inter_fail OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoResAlloInterReq
CREATE TABLE mm_ho_res_allo_inter_req (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    cause_type TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_res_allo_inter_req', 'time');
CREATE INDEX ON mm_ho_res_allo_inter_req (network_function_id, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_req (cause_type, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_req (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_req (plmn_id, time DESC);
ALTER TABLE mm_ho_res_allo_inter_req SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_res_allo_inter_req', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_res_allo_inter_req', INTERVAL '180 days');
ALTER TABLE mm_ho_res_allo_inter_req OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoResAlloInterSucc
CREATE TABLE mm_ho_res_allo_inter_succ (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_res_allo_inter_succ', 'time');
CREATE INDEX ON mm_ho_res_allo_inter_succ (network_function_id, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_succ (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_succ (plmn_id, time DESC);
ALTER TABLE mm_ho_res_allo_inter_succ SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_res_allo_inter_succ', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_res_allo_inter_succ', INTERVAL '180 days');
ALTER TABLE mm_ho_res_allo_inter_succ OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoResAlloInterFail
CREATE TABLE mm_ho_res_allo_inter_fail (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    cause_type TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_res_allo_inter_fail', 'time');
CREATE INDEX ON mm_ho_res_allo_inter_fail (network_function_id, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_fail (cause_type, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_fail (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_res_allo_inter_fail (plmn_id, time DESC);
ALTER TABLE mm_ho_res_allo_inter_fail SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_res_allo_inter_fail', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_res_allo_inter_fail', INTERVAL '180 days');
ALTER TABLE mm_ho_res_allo_inter_fail OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoExeInterReq
CREATE TABLE mm_ho_exe_inter_req (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_exe_inter_req', 'time');
CREATE INDEX ON mm_ho_exe_inter_req (network_function_id, time DESC);
CREATE INDEX ON mm_ho_exe_inter_req (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_exe_inter_req (plmn_id, time DESC);
ALTER TABLE mm_ho_exe_inter_req SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_exe_inter_req', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_exe_inter_req', INTERVAL '180 days');
ALTER TABLE mm_ho_exe_inter_req OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoExeIntraReq
CREATE TABLE mm_ho_exe_intra_req (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_exe_intra_req', 'time');
CREATE INDEX ON mm_ho_exe_intra_req (network_function_id, time DESC);
CREATE INDEX ON mm_ho_exe_intra_req (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_exe_intra_req (plmn_id, time DESC);
ALTER TABLE mm_ho_exe_intra_req SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_exe_intra_req', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_exe_intra_req', INTERVAL '180 days');
ALTER TABLE mm_ho_exe_intra_req OWNER TO {{ .Values.cnpg.auth.username }};

-- MMHoExeIntraSucc
CREATE TABLE mm_ho_exe_intra_succ (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    value INTEGER
);
SELECT create_hypertable('mm_ho_exe_intra_succ', 'time');
CREATE INDEX ON mm_ho_exe_intra_succ (network_function_id, time DESC);
CREATE INDEX ON mm_ho_exe_intra_succ (nr_cell_id, time DESC);
CREATE INDEX ON mm_ho_exe_intra_succ (plmn_id, time DESC);
ALTER TABLE mm_ho_exe_intra_succ SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('mm_ho_exe_intra_succ', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('mm_ho_exe_intra_succ', INTERVAL '180 days');
ALTER TABLE mm_ho_exe_intra_succ OWNER TO {{ .Values.cnpg.auth.username }};
