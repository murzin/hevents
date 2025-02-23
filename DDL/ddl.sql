PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS event_types (
    etp_id INTEGER PRIMARY KEY,
    etp_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS event_places (
    epl_id INTEGER PRIMARY KEY,
    epl_name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS events (
    evt_id INTEGER PRIMARY KEY,
    evt_name TEXT NOT NULL,
    evt_desc TEXT,
    evt_url  TEXT,
    evt_from TEXT NOT NULL,
    evt_to   TEXT NOT NULL,
    etp_id INTEGER NOT NULL,
    epl_id INTEGER NOT NULL,
    FOREIGN KEY (etp_id) REFERENCES event_types(etp_id) ON DELETE CASCADE,
    FOREIGN KEY (epl_id) REFERENCES event_places(epl_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_links (
    evt_id_1 INTEGER NOT NULL,
    evt_id_2 INTEGER NOT NULL,
    PRIMARY KEY (evt_id_1, evt_id_2),
    FOREIGN KEY (evt_id_1) REFERENCES events(evt_id) ON DELETE CASCADE,
    FOREIGN KEY (evt_id_2) REFERENCES events(evt_id) ON DELETE CASCADE
);

