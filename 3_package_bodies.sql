-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 3_package_bodies.sql
-- Description:
-- Implements package bodies for users, events, sightings, and participation.
-- Includes logic for inserting, deleting, and querying with validation,
-- and includes row locking to ensure data consistency under concurrent execution.
-----------------------------------------------------
-- Package Body: pkg_users
-- Handles operations related to user accounts
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_users IS

    -- Adds a new user with name and email
    -- Automatically sets the registration date to current date
    PROCEDURE add_user(p_full_name VARCHAR2, p_email VARCHAR2) IS
    BEGIN
        INSERT INTO users (user_id, full_name, email, registration_date)
        VALUES (seq_users.NEXTVAL, p_full_name, p_email, SYSDATE);
    END;

    -- Deletes a user, but only if they have no event participations
    -- Locks the user row to prevent concurrent changes
    PROCEDURE delete_user(p_user_id NUMBER) IS
        v_count INTEGER;  -- number of participations
        v_dummy INTEGER;  -- used for row lock
    BEGIN
        -- Lock the user row
        SELECT 1 INTO v_dummy FROM users WHERE user_id = p_user_id FOR UPDATE;
    
        -- Check if user is registered for any event
        SELECT COUNT(*) INTO v_count FROM participation WHERE user_id = p_user_id;
        IF v_count > 0 THEN
            -- User cannot be deleted if participating in events
            RAISE_APPLICATION_ERROR(-20001, 'Cannot delete user: has event participations.');
        END IF;
    
        DELETE FROM users WHERE user_id = p_user_id;
    END;

    -- Updates a user's email address
    PROCEDURE change_email(p_user_id NUMBER, p_new_email VARCHAR2) IS
    BEGIN
        UPDATE users SET email = p_new_email WHERE user_id = p_user_id;
    END;

END pkg_users;
/

-----------------------------------------------------
-- Package Body: pkg_events
-- Manages creation, deletion, and duration of events
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_events IS


    -- Creates a new event with a name, location, and date range
    PROCEDURE create_event(p_name VARCHAR2, p_location_id NUMBER, p_start DATE, p_end DATE) IS
    BEGIN
        INSERT INTO events (event_id, name, location_id, start_date, end_date)
        VALUES (seq_events.NEXTVAL, p_name, p_location_id, p_start, p_end);
    END;


    -- Cancels an event (deletes it) after locking its row
    PROCEDURE cancel_event(p_event_id NUMBER) IS
        v_dummy INTEGER;
    BEGIN
        -- Lock the event row to prevent concurrent access
        SELECT 1 INTO v_dummy FROM events WHERE event_id = p_event_id FOR UPDATE;
        -- Delete the event
        DELETE FROM events WHERE event_id = p_event_id;
    END;

    -- Computes the duration (in days) between start and end of an event
    FUNCTION event_duration(p_event_id NUMBER) RETURN NUMBER IS
        v_start DATE;
        v_end DATE;
    BEGIN
        SELECT start_date, end_date INTO v_start, v_end FROM events WHERE event_id = p_event_id;
        RETURN v_end - v_start;
    END;

END pkg_events;
/

-----------------------------------------------------
-- Package Body: pkg_participation
-- Manages registration and unregistration of users to/from events
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_participation IS

    -- Registers a user to an event, unless already registered
    -- Ensures concurrency safety via row-level locking
    PROCEDURE register_user(p_user_id NUMBER, p_event_id NUMBER) IS
        v_dummy NUMBER;
    BEGIN
        -- Use row locking to ensure this check is concurrency safe
        BEGIN
            SELECT 1 INTO v_dummy
            FROM participation
            WHERE user_id = p_user_id AND event_id = p_event_id
            FOR UPDATE;

            -- If found, user is already registered
            RAISE_APPLICATION_ERROR(-20002, 'User already registered for the event.');
        EXCEPTION
            -- If not found, allow registration
            WHEN NO_DATA_FOUND THEN
                INSERT INTO participation(user_id, event_id)
                VALUES (p_user_id, p_event_id);
        END;
    END;

    -- Removes a user's registration from an event
    PROCEDURE unregister_user(p_user_id NUMBER, p_event_id NUMBER) IS
    BEGIN
        DELETE FROM participation
        WHERE user_id = p_user_id AND event_id = p_event_id;
    END;

END pkg_participation;
/

-----------------------------------------------------
-- Package Body: pkg_sightings
-- Logs bird sightings during events and finds the most common bird seen
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_sightings IS

    -- Logs a bird sighting made by a user during an event
    -- Locks involved rows to ensure referential integrity under concurrency
    PROCEDURE log_sighting(
        p_user_id NUMBER,        -- Who saw the bird
        p_event_id NUMBER,       -- Which event it happened at
        p_bird_id NUMBER,        -- Which bird was seen
        p_timestamp TIMESTAMP,   -- When the sighting occurred
        p_note VARCHAR2          -- Optional location note
    ) IS
        v_dummy NUMBER;
    BEGIN
        -- Lock the user row to ensure it exists and is not concurrently deleted
        SELECT 1 INTO v_dummy FROM users WHERE user_id = p_user_id FOR UPDATE;
        
        -- Lock the event row
        SELECT 1 INTO v_dummy FROM events WHERE event_id = p_event_id FOR UPDATE;
        
        -- Lock the bird species row
        SELECT 1 INTO v_dummy FROM bird_species WHERE bird_id = p_bird_id FOR UPDATE;

        -- Now insert the sighting
        INSERT INTO sightings (
            sighting_id, user_id, event_id, bird_id, timestamp, location_note
        )
        VALUES (
            seq_sightings.NEXTVAL, p_user_id, p_event_id, p_bird_id, p_timestamp, p_note
        );
    EXCEPTION
        -- Raise a clear error if any of the required parent records are missing
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Foreign key constraint failed during log_sighting');
    END;
    
    -- Returns the most frequently sighted bird across all events
    FUNCTION most_common_bird RETURN VARCHAR2 IS
        v_common_name VARCHAR2(100);
    BEGIN
        -- Group sightings by bird, count them, and return the most common one
        SELECT bs.common_name
        INTO v_common_name
        FROM sightings s
        JOIN bird_species bs ON s.bird_id = bs.bird_id
        GROUP BY bs.common_name
        ORDER BY COUNT(*) DESC
        FETCH FIRST 1 ROWS ONLY;

        RETURN v_common_name;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'No sightings recorded';
    END;

END pkg_sightings;
/
