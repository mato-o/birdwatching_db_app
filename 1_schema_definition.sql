-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: schema_definition.sql
-- Description:
-- Defines the schema for a birdwatching event management system. Includes:
-- - Tables for users, locations, events, bird species, sightings, notes, weather
-- - Relationships via foreign keys and primary keys
-- - Business logic interfaces (package specs)
-- - Integrity triggers and logging
-- ===========================================
-- USERS
-- ===========================================
-- Stores registered birdwatchers.
-- Columns:
--   user_id: Primary key. Unique identifier for each user.
--   full_name: Full name of the user.
--   email: Unique email address used for login/contact.
--   registration_date: Date when the user was added. Defaults to SYSDATE.
CREATE TABLE users (
    user_id             NUMBER PRIMARY KEY,
    full_name           VARCHAR2(100) NOT NULL,
    email               VARCHAR2(100) UNIQUE NOT NULL,
    registration_date   DATE DEFAULT SYSDATE
);

-- Sequence for users
CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- LOCATIONS
-- ===========================================
-- Represents birdwatching locations.
-- Columns:
--   location_id: Primary key.
--   name: Name of the location (e.g. forest name).
--   region: Administrative region the location belongs to.
--   latitude, longitude: Optional GPS coordinates for mapping or filtering.
CREATE TABLE locations (
    location_id         NUMBER PRIMARY KEY,
    name                VARCHAR2(100) NOT NULL,
    region              VARCHAR2(100),
    latitude            NUMBER,
    longitude           NUMBER
);

CREATE SEQUENCE seq_locations START WITH 1 INCREMENT BY 1;


-- ===========================================
-- EVENTS
-- ===========================================
-- Stores birdwatching events (organized by date and location).
-- Columns:
--   event_id: Primary key.
--   name: Name of the event.
--   location_id: Foreign key to locations.
--   start_date, end_date: Defines the period of the event.
-- Constraint:
--   CHECK (end_date >= start_date): Ensures valid date range.
CREATE TABLE events (
    event_id            NUMBER PRIMARY KEY,
    name                VARCHAR2(100) NOT NULL,
    location_id         NUMBER NOT NULL REFERENCES locations(location_id),
    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,
    CHECK (end_date >= start_date)
);

-- Sequence for events
CREATE SEQUENCE seq_events START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- PARTICIPATION (user - event)
-- ===========================================
-- Links users to events they registered for (many-to-many).
-- Columns:
--   user_id: Foreign key to users.
--   event_id: Foreign key to events.
-- Composite PK (user_id, event_id): ensures one user can only register once per event.
CREATE TABLE participation (
    user_id     NUMBER NOT NULL REFERENCES users(user_id),
    event_id    NUMBER NOT NULL REFERENCES events(event_id),
    PRIMARY KEY (user_id, event_id)
);

-- ===========================================
-- BIRD SPECIES
-- ===========================================
-- Stores all birds that can be logged in sightings.
-- Columns:
--   bird_id: Primary key.
--   common_name: Friendly name (must be unique).
--   scientific_name: Optional Latin name.
CREATE TABLE bird_species (
    bird_id         NUMBER PRIMARY KEY,
    common_name     VARCHAR2(100) NOT NULL UNIQUE,
    scientific_name VARCHAR2(150)
);
CREATE SEQUENCE seq_bird_species START WITH 1 INCREMENT BY 1;


-- ===========================================
-- SIGHTINGS
-- ===========================================
-- Records each observation of a bird during an event by a user.
-- Columns:
--   sighting_id: Primary key.
--   user_id: Who saw the bird.
--   event_id: During what event.
--   bird_id: Which species.
--   timestamp: When the sighting was recorded.
--   location_note: Optional text like “by the river”.
-- Constraint:
--   UNIQUE(user_id, event_id, bird_id, timestamp): Prevents exact duplicates.
CREATE TABLE sightings (
    sighting_id     NUMBER PRIMARY KEY,
    user_id         NUMBER NOT NULL REFERENCES users(user_id),
    event_id        NUMBER NOT NULL REFERENCES events(event_id),
    bird_id         NUMBER NOT NULL REFERENCES bird_species(bird_id),
    timestamp       TIMESTAMP NOT NULL,
    location_note   VARCHAR2(200),
    UNIQUE(user_id, event_id, bird_id, timestamp)-- Prevents duplicate entries
);

-- Sequence for sightings
CREATE SEQUENCE seq_sightings START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- WEATHER CONDITIONS (Optional)
-- ===========================================
-- Stores environmental data tied to a single event.
-- Columns:
--   event_id: Primary key + FK to events.
--   temperature: °C reading.
--   conditions: Description (e.g. “Sunny”).
--   wind_speed: Measured in suitable units (e.g. m/s or km/h).
CREATE TABLE weather_conditions (
    event_id        NUMBER PRIMARY KEY REFERENCES events(event_id),
    temperature     NUMBER,
    conditions      VARCHAR2(100),
    wind_speed      NUMBER
);

-- ===========================================
-- NOTES (Optional)
-- ===========================================
-- Allows users to write journal-style text about an event.
-- Columns:
--   note_id: Primary key.
--   user_id: Optional link to author.
--   event_id: Optional link to event.
--   note_text: Free-form CLOB text.
--   created_at: Auto-filled with current timestamp.
CREATE TABLE notes (
    note_id         NUMBER PRIMARY KEY,
    user_id         NUMBER REFERENCES users(user_id),
    event_id        NUMBER REFERENCES events(event_id),
    note_text       CLOB,
    created_at      TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Sequence for notes
CREATE SEQUENCE seq_notes START WITH 1 INCREMENT BY 1 NOCACHE;

-- ===========================================
-- INDEXES
-- ===========================================
CREATE INDEX idx_sightings_event ON sightings(event_id);
CREATE INDEX idx_participation_event ON participation(event_id);

-- ===========================================
-- TRIGGERS
-- ===========================================

-- Prevent deletion of a user who has sightings
CREATE OR REPLACE TRIGGER trg_no_user_delete_with_sightings
BEFORE DELETE ON users
FOR EACH ROW
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM sightings
    WHERE user_id = :OLD.user_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cannot delete user with sightings.');
    END IF;
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
-- PACKAGE INTERFACES (DECLARATIONS)
-- ===========================================

-- Package for users
CREATE OR REPLACE PACKAGE pkg_users IS
    -- Adds a new user to the system
    PROCEDURE add_user(p_full_name VARCHAR2, p_email VARCHAR2);
    -- Deletes a user (only if not registered to events)
    PROCEDURE delete_user(p_user_id NUMBER);
    -- Changes user's email
    PROCEDURE change_email(p_user_id NUMBER, p_new_email VARCHAR2);
END pkg_users;
/

-- Package for events
CREATE OR REPLACE PACKAGE pkg_events IS
    -- Creates a new birdwatching event
    PROCEDURE create_event(p_name VARCHAR2, p_location_id NUMBER, p_start DATE, p_end DATE);
    -- Cancels (deletes) an event
    PROCEDURE cancel_event(p_event_id NUMBER);
    -- Returns duration in days
    FUNCTION event_duration(p_event_id NUMBER) RETURN NUMBER;
END pkg_events;
/

-- Package for sightings
CREATE OR REPLACE PACKAGE pkg_sightings IS
    -- Logs a sighting by a user at an event
    PROCEDURE log_sighting(p_user_id NUMBER, p_event_id NUMBER, p_bird_id NUMBER, p_timestamp TIMESTAMP, p_note VARCHAR2);
    -- Returns most commonly sighted bird by name
    FUNCTION most_common_bird RETURN VARCHAR2;
END pkg_sightings;
/

-- Package for participation
CREATE OR REPLACE PACKAGE pkg_participation IS
    -- Registers a user for an event
    PROCEDURE register_user(p_user_id NUMBER, p_event_id NUMBER);
    -- Unregisters a user from an event
    PROCEDURE unregister_user(p_user_id NUMBER, p_event_id NUMBER);
END pkg_participation;
/

-- ===========================================
-- End of Script 1
-- ===========================================
