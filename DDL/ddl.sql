PRAGMA foreign_keys = ON;

CREATE TABLE event_types (
    etp_id INTEGER PRIMARY KEY,
    etp_name TEXT NOT NULL
);

CREATE TABLE events (
    evt_id INTEGER PRIMARY KEY,
    evt_name TEXT NOT NULL,
    evt_desc TEXT,
    evt_url  TEXT,
    evt_from TEXT NOT NULL,
    evt_to   TEXT NOT NULL,
    etp_id INTEGER NOT NULL,
    FOREIGN KEY (etp_id) REFERENCES event_types(etp_id) ON DELETE CASCADE
);

