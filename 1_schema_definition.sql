-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: schema_definition.sql
-- Description:
-- Defines the schema for a birdwatching event management system
-- Includes named constraints, indexes for foreign keys and timestamps, and improved triggers.

-- ===========================================
-- USERS
-- ===========================================
CREATE TABLE users (
    user_id             NUMBER,
    full_name           VARCHAR2(100) NOT NULL,
    email               VARCHAR2(100) NOT NULL,
    registration_date   DATE DEFAULT SYSDATE,
    CONSTRAINT pk_users PRIMARY KEY (user_id),
    CONSTRAINT uq_users_email UNIQUE (email)
);

CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- LOCATIONS
-- ===========================================
CREATE TABLE locations (
    location_id         NUMBER,
    name                VARCHAR2(100) NOT NULL,
    region              VARCHAR2(100),
    latitude            NUMBER,
    longitude           NUMBER,
    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    -- Real key to prevent duplicates
    CONSTRAINT uq_locations_name_region UNIQUE (name, region)
);

CREATE SEQUENCE seq_locations START WITH 1 INCREMENT BY 1;

-- ===========================================
-- EVENTS
-- ===========================================
CREATE TABLE events (
    event_id            NUMBER,
    name                VARCHAR2(100) NOT NULL,
    location_id         NUMBER NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    CONSTRAINT pk_events PRIMARY KEY (event_id),
    CONSTRAINT fk_events_location FOREIGN KEY (location_id) REFERENCES locations(location_id),
    CONSTRAINT chk_events_date CHECK (end_date >= start_date),
    -- Real key
    CONSTRAINT uq_events_name_start UNIQUE (name, start_date)
);

CREATE SEQUENCE seq_events START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- PARTICIPATION
-- ===========================================
CREATE TABLE participation (
    user_id     NUMBER NOT NULL,
    event_id    NUMBER NOT NULL,
    CONSTRAINT pk_participation PRIMARY KEY (user_id, event_id),
    CONSTRAINT fk_participation_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_participation_event FOREIGN KEY (event_id) REFERENCES events(event_id)
);

-- ===========================================
-- BIRD SPECIES
-- ===========================================
CREATE TABLE bird_species (
    bird_id         NUMBER,
    common_name     VARCHAR2(100) NOT NULL,
    scientific_name VARCHAR2(150),
    CONSTRAINT pk_bird_species PRIMARY KEY (bird_id),
    CONSTRAINT uq_bird_species_common_name UNIQUE (common_name)
);

CREATE SEQUENCE seq_bird_species START WITH 1 INCREMENT BY 1;

-- ===========================================
-- SIGHTINGS
-- ===========================================
CREATE TABLE sightings (
    sighting_id     NUMBER,
    user_id         NUMBER NOT NULL,
    event_id        NUMBER NOT NULL,
    bird_id         NUMBER NOT NULL,
    timestamp       TIMESTAMP NOT NULL,
    location_note   VARCHAR2(200),
    CONSTRAINT pk_sightings PRIMARY KEY (sighting_id),
    CONSTRAINT fk_sightings_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_sightings_event FOREIGN KEY (event_id) REFERENCES events(event_id),
    CONSTRAINT fk_sightings_bird FOREIGN KEY (bird_id) REFERENCES bird_species(bird_id),
    CONSTRAINT uq_sightings UNIQUE (user_id, event_id, bird_id, timestamp)
);

CREATE SEQUENCE seq_sightings START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- WEATHER CONDITIONS
-- ===========================================
CREATE TABLE weather_conditions (
    event_id        NUMBER,
    temperature     NUMBER,
    conditions      VARCHAR2(100),
    wind_speed      NUMBER,
    CONSTRAINT pk_weather PRIMARY KEY (event_id),
    CONSTRAINT fk_weather_event FOREIGN KEY (event_id) REFERENCES events(event_id)
);

-- ===========================================
-- NOTES
-- ===========================================
CREATE TABLE notes (
    note_id         NUMBER,
    user_id         NUMBER,
    event_id        NUMBER,
    note_text       CLOB,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_notes PRIMARY KEY (note_id),
    CONSTRAINT fk_notes_user FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_notes_event FOREIGN KEY (event_id) REFERENCES events(event_id)
);

CREATE SEQUENCE seq_notes START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- INDEXES for foreign keys and timestamps
-- ===========================================
CREATE INDEX idx_participation_user ON participation(user_id);
CREATE INDEX idx_participation_event ON participation(event_id);

CREATE INDEX idx_sightings_event_timestamp ON sightings(event_id, timestamp);
CREATE INDEX idx_sightings_user ON sightings(user_id);
CREATE INDEX idx_sightings_bird ON sightings(bird_id);

CREATE INDEX idx_notes_created_at ON notes(created_at);

-- ===========================================
-- TRIGGERS
-- ===========================================
-- Prevent deletion of user with sightings
CREATE OR REPLACE TRIGGER trg_no_user_delete_with_sightings
BEFORE DELETE ON users
FOR EACH ROW
DECLARE
    v_dummy INTEGER;
BEGIN
    -- More robust: stop as soon as one sighting exists
    SELECT 1 INTO v_dummy
    FROM sightings
    WHERE user_id = :OLD.user_id
    AND ROWNUM = 1;
    RAISE_APPLICATION_ERROR(-20001, 'Cannot delete user with sightings.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- No sightings, allow deletion
END;
/

-- Log deletion of bird species
CREATE TABLE bird_species_log (
    log_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    bird_id         NUMBER,
    deleted_at      TIMESTAMP DEFAULT SYSTIMESTAMP,
    deleted_by      VARCHAR2(100)
);

CREATE OR REPLACE TRIGGER trg_log_deleted_bird
AFTER DELETE ON bird_species
FOR EACH ROW
BEGIN
    INSERT INTO bird_species_log (bird_id, deleted_by)
    VALUES (:OLD.bird_id, USER);
END;
/

-- ===========================================
-- PACKAGE INTERFACES
-- ===========================================
CREATE OR REPLACE PACKAGE pkg_users IS
    PROCEDURE add_user(p_full_name VARCHAR2, p_email VARCHAR2);
    PROCEDURE delete_user(p_user_id NUMBER);
    PROCEDURE change_email(p_user_id NUMBER, p_new_email VARCHAR2);
END pkg_users;
/

CREATE OR REPLACE PACKAGE pkg_events IS
    PROCEDURE create_event(p_name VARCHAR2, p_location_id NUMBER, p_start DATE, p_end DATE);
    PROCEDURE cancel_event(p_event_id NUMBER);
    FUNCTION event_duration(p_event_id NUMBER) RETURN NUMBER;
END pkg_events;
/

CREATE OR REPLACE PACKAGE pkg_sightings IS
    PROCEDURE log_sighting(p_user_id NUMBER, p_event_id NUMBER, p_bird_id NUMBER, p_timestamp TIMESTAMP, p_note VARCHAR2);
    FUNCTION most_common_bird RETURN VARCHAR2;
END pkg_sightings;
/

CREATE OR REPLACE PACKAGE pkg_participation IS
    PROCEDURE register_user(p_user_id NUMBER, p_event_id NUMBER);
    PROCEDURE unregister_user(p_user_id NUMBER, p_event_id NUMBER);
END pkg_participation;
/

