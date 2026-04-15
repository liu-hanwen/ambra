CREATE TABLE IF NOT EXISTS materials (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    path       TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS briefs (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    path       TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS knowledges (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    path       TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS wisdoms (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    path       TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT,
    deleted_at TEXT
);

CREATE TABLE IF NOT EXISTS layer_state (
    layer           TEXT PRIMARY KEY,
    last_visited_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_materials_updated  ON materials(updated_at);
CREATE INDEX IF NOT EXISTS idx_briefs_updated     ON briefs(updated_at);
CREATE INDEX IF NOT EXISTS idx_knowledges_updated ON knowledges(updated_at);
CREATE INDEX IF NOT EXISTS idx_wisdoms_updated    ON wisdoms(updated_at);

INSERT OR IGNORE INTO layer_state(layer) VALUES
    ('material'),
    ('brief'),
    ('knowledge'),
    ('wisdom'),
    ('idea');
