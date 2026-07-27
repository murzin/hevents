PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS event_types (
  etp_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  etp_name TEXT NOT NULL UNIQUE,
  epr_id   INTEGER REFERENCES event_periods(epr_id)
);

CREATE TABLE IF NOT EXISTS event_places (
  epl_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  epl_name TEXT NOT NULL UNIQUE,
  epr_id   INTEGER REFERENCES event_periods(epr_id)
);

CREATE TABLE IF NOT EXISTS event_periods (
  epr_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  epr_name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS events (
  evt_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  evt_name TEXT NOT NULL,
  evt_desc TEXT NOT NULL,
  evt_url  TEXT NOT NULL,
  evt_from TEXT NOT NULL,
  evt_to   TEXT NOT NULL,
  etp_id   INTEGER NOT NULL REFERENCES event_types(etp_id),
  epl_id   INTEGER NOT NULL REFERENCES event_places(epl_id),
  epr_id   INTEGER NOT NULL REFERENCES event_periods(epr_id)
);

CREATE TABLE IF NOT EXISTS event_links (
  evt_id_1 INTEGER NOT NULL REFERENCES events(evt_id),
  evt_id_2 INTEGER NOT NULL REFERENCES events(evt_id),
  PRIMARY KEY (evt_id_1, evt_id_2)
);

CREATE INDEX IF NOT EXISTS events_etp_id_idx ON events(etp_id);
CREATE INDEX IF NOT EXISTS events_epl_id_idx ON events(epl_id);
CREATE INDEX IF NOT EXISTS events_epr_id_idx ON events(epr_id);
CREATE INDEX IF NOT EXISTS events_evt_id_idx ON events(evt_id);
CREATE INDEX IF NOT EXISTS event_types_epr_id_idx ON event_types(epr_id);
CREATE INDEX IF NOT EXISTS event_places_epr_id_idx ON event_places(epr_id);
CREATE INDEX IF NOT EXISTS event_links_evt_ids_idx
  ON event_links(evt_id_1, evt_id_2);
DROP INDEX IF EXISTS event_links_evt_id_2_idx;
