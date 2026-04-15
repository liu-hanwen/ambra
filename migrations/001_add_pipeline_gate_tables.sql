-- =============================================================
-- Migration 001: Pipeline Gate Tables
-- Purpose: Replace timestamp-driven layer promotion with
--          publish-unit + version-based readiness gate.
-- =============================================================

-- Table 1: pipeline_units
-- Represents a publish unit — the minimum complete upstream unit
-- that downstream layers can consume.
--
-- Naming convention for unit_id:
--   {layer}:{source_kind}:{source_key}
--   The source_key may contain path separators (e.g. slashes).
--   Examples:
--     "material:document:source/item-name" (source_key = "source/item-name")
--     "material:book:books/foo"           (source_key = "books/foo")
--     "brief:document:source/item-name"
--     "brief:book:books/foo"
--
-- Status state machine:
--   pending → in_progress → ready
--                         → blocked → in_progress (after fix)
--   ready → in_progress (on revision)
--
CREATE TABLE IF NOT EXISTS pipeline_units (
    unit_id           TEXT    PRIMARY KEY,
    layer             TEXT    NOT NULL,
    unit_type         TEXT    NOT NULL DEFAULT 'single',
    source_kind       TEXT    NOT NULL DEFAULT 'generic',
    source_key        TEXT    NOT NULL,
    root_path         TEXT    NOT NULL,
    status            TEXT    NOT NULL DEFAULT 'pending',
    required_count    INTEGER NOT NULL DEFAULT 0,
    done_count        INTEGER NOT NULL DEFAULT 0,
    blocked_count     INTEGER NOT NULL DEFAULT 0,
    ready_version     INTEGER NOT NULL DEFAULT 0,
    ready_at          TEXT,
    created_at        TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_pipeline_units_layer      ON pipeline_units(layer);
CREATE INDEX IF NOT EXISTS idx_pipeline_units_status     ON pipeline_units(status);
CREATE INDEX IF NOT EXISTS idx_pipeline_units_source_key ON pipeline_units(source_key);

-- Table 2: pipeline_unit_members
-- Represents individual members of a publish unit.
--
-- member_role:
--   required — must be done before unit can become ready
--   optional — does not block unit readiness
--
-- member_status state machine:
--   pending → in_progress → done
--                         → blocked → in_progress (after fix)
--   done → in_progress (on revision)
--
CREATE TABLE IF NOT EXISTS pipeline_unit_members (
    unit_id        TEXT    NOT NULL REFERENCES pipeline_units(unit_id),
    member_path    TEXT    NOT NULL,
    member_role    TEXT    NOT NULL DEFAULT 'required',
    member_type    TEXT    NOT NULL DEFAULT 'file',
    member_key     TEXT,
    member_status  TEXT    NOT NULL DEFAULT 'pending',
    member_version INTEGER NOT NULL DEFAULT 0,
    last_error     TEXT,
    updated_at     TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (unit_id, member_path)
);

CREATE INDEX IF NOT EXISTS idx_pipeline_unit_members_unit   ON pipeline_unit_members(unit_id);
CREATE INDEX IF NOT EXISTS idx_pipeline_unit_members_status ON pipeline_unit_members(member_status);

-- Table 3: pipeline_consumptions
-- Tracks which downstream layer has consumed which unit at which version.
-- Supports multiple consumers per unit (e.g. knowledge consumes brief,
-- wisdom and idea both consume knowledge independently).
--
CREATE TABLE IF NOT EXISTS pipeline_consumptions (
    unit_id          TEXT NOT NULL REFERENCES pipeline_units(unit_id),
    consumer_layer   TEXT NOT NULL,
    consumed_version INTEGER NOT NULL DEFAULT 0,
    consumed_at      TEXT,
    output_ref       TEXT,
    PRIMARY KEY (unit_id, consumer_layer)
);

CREATE INDEX IF NOT EXISTS idx_pipeline_consumptions_consumer ON pipeline_consumptions(consumer_layer);

-- =============================================================
-- Aggregation rules (reference — implemented in agent logic):
--
-- After updating any member, re-aggregate the unit status:
--
--   IF any required member is blocked   → unit.status = 'blocked'
--   ELIF all required members are done  → unit.status = 'ready'
--     AND increment ready_version, set ready_at = now
--   ELIF any member is in_progress      → unit.status = 'in_progress'
--   ELSE                                → unit.status = 'pending'
--
-- Downstream consumption query:
--
--   SELECT pu.unit_id, pu.ready_version
--   FROM   pipeline_units pu
--   LEFT JOIN pipeline_consumptions pc
--     ON pu.unit_id = pc.unit_id AND pc.consumer_layer = '{downstream_layer}'
--   WHERE  pu.layer  = '{upstream_layer}'
--     AND  pu.status = 'ready'
--     AND  pu.ready_version > COALESCE(pc.consumed_version, 0);
--
-- =============================================================
