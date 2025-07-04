-- RrcMeasurementReport
CREATE TABLE rrc_measurement_report (
    time TIMESTAMPTZ NOT NULL,
    source TEXT NOT NULL,
    network_function_id TEXT NOT NULL,
    ueid TEXT NOT NULL,
    nr_cell_id INTEGER NOT NULL,
    plmn_id TEXT NOT NULL,
    pci INTEGER,
    is_serving_cell BOOLEAN NOT NULL,
    ssb_rsrp INTEGER,
    ssb_rsrq INTEGER,
    ssb_sinr INTEGER
);

SELECT create_hypertable('rrc_measurement_report', 'time');
CREATE INDEX ON rrc_measurement_report (network_function_id, time DESC);
CREATE INDEX ON rrc_measurement_report (source, time DESC);
CREATE INDEX ON rrc_measurement_report (ueid, time DESC);
CREATE INDEX ON rrc_measurement_report (nr_cell_id, time DESC);
ALTER TABLE rrc_measurement_report SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);
SELECT add_compression_policy('rrc_measurement_report', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('rrc_measurement_report', INTERVAL '180 days');
ALTER TABLE rrc_measurement_report OWNER TO {{ .Values.cnpg.auth.username }};

COMMENT ON TABLE rrc_measurement_report IS 'Stores per-UE RRC measurement reports including signal strength and quality metrics.';
COMMENT ON COLUMN rrc_measurement_report.time IS 'Timestamp of the measurement (UTC).';
COMMENT ON COLUMN rrc_measurement_report.source IS 'Source of the report (e.g., base station identifier).';
COMMENT ON COLUMN rrc_measurement_report.network_function_id IS 'Identifier of the network function reporting this measurement.';
COMMENT ON COLUMN rrc_measurement_report.ueid IS 'Unique identifier of the User Equipment (UE).';
COMMENT ON COLUMN rrc_measurement_report.nr_cell_id IS 'NR Cell Identifier where the measurement was taken.';
COMMENT ON COLUMN rrc_measurement_report.plmn_id IS 'Public Land Mobile Network Identifier.';
COMMENT ON COLUMN rrc_measurement_report.pci IS 'Physical Cell Identifier (optional).';
COMMENT ON COLUMN rrc_measurement_report.is_serving_cell IS 'Whether the cell is the serving cell (true) or a neighbor (false).';
COMMENT ON COLUMN rrc_measurement_report.ssb_rsrp IS 'Received Signal Received Power of the Synchronization Signal Block.';
COMMENT ON COLUMN rrc_measurement_report.ssb_rsrq IS 'Received Signal Received Quality of the Synchronization Signal Block.';
COMMENT ON COLUMN rrc_measurement_report.ssb_sinr IS 'Signal-to-Interference-plus-Noise Ratio of the Synchronization Signal Block.';

-- L1MSSRSRP
CREATE TABLE l1_ms_srsrp (
    time TIMESTAMPTZ NOT NULL,
    network_function_id TEXT NOT NULL,
    ssb TEXT NOT NULL,
    bin_x INTEGER NOT NULL,
    value INTEGER
);
SELECT create_hypertable('l1_ms_srsrp', 'time');
CREATE INDEX ON l1_ms_srsrp (network_function_id, time DESC);
CREATE INDEX ON l1_ms_srsrp (ssb, time DESC);
CREATE INDEX ON l1_ms_srsrp (bin_x, time DESC);
ALTER TABLE l1_ms_srsrp SET (
    timescaledb.compress,
    timescaledb.compress_orderby = 'time DESC',
    timescaledb.compress_segmentby = 'network_function_id'
);

SELECT add_compression_policy('l1_ms_srsrp', compress_after => INTERVAL '14 days');
SELECT add_retention_policy('l1_ms_srsrp', INTERVAL '180 days');
ALTER TABLE l1_ms_srsrp OWNER TO {{ .Values.cnpg.auth.username }};
