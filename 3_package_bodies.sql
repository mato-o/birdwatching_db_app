-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 3_package_bodies.sql
-- Description:
-- Implements package bodies for users, events, sightings, and participation.
-- Includes:
--   - Row locking to ensure consistency
--   - Exception handling for duplicate and missing data
--   - Validation before inserts and updates
--   - Clear error messages

-----------------------------------------------------
-- Package Body: pkg_users
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_users IS

    -- Adds a new user
    PROCEDURE add_user(p_full_name VARCHAR2, p_email VARCHAR2) IS
    BEGIN
        INSERT INTO users (user_id, full_name, email, registration_date)
        VALUES (seq_users.NEXTVAL, p_full_name, p_email, SYSDATE);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20010, 'A user with this email already exists.');
    END;

    -- Deletes a user only if not registered for any events
    PROCEDURE delete_user(p_user_id NUMBER) IS
        v_count INTEGER;
        v_dummy INTEGER;
    BEGIN
        -- Lock the user row to prevent concurrent deletion
        BEGIN
            SELECT 1 INTO v_dummy FROM users WHERE user_id = p_user_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20011, 'User does not exist.');
        END;

        -- Check participations
        SELECT COUNT(*) INTO v_count FROM participation WHERE user_id = p_user_id;
        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Cannot delete user: has event participations.');
        END IF;

        DELETE FROM users WHERE user_id = p_user_id;
    END;

    -- Updates user email address
    PROCEDURE change_email(p_user_id NUMBER, p_new_email VARCHAR2) IS
    BEGIN
        UPDATE users
        SET email = p_new_email
        WHERE user_id = p_user_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'User not found.');
        END IF;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20013, 'This email is already in use by another user.');
    END;

END pkg_users;
/

-----------------------------------------------------
-- Package Body: pkg_events
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_events IS

    -- Creates a new event
    PROCEDURE create_event(p_name VARCHAR2, p_location_id NUMBER, p_start DATE, p_end DATE) IS
        v_dummy INTEGER;
    BEGIN
        -- Check if location exists
        BEGIN
            SELECT 1 INTO v_dummy FROM locations WHERE location_id = p_location_id;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20020, 'Specified location does not exist.');
        END;

        INSERT INTO events (event_id, name, location_id, start_date, end_date)
        VALUES (seq_events.NEXTVAL, p_name, p_location_id, p_start, p_end);
    END;

    -- Cancels an event
    PROCEDURE cancel_event(p_event_id NUMBER) IS
        v_dummy INTEGER;
    BEGIN
        -- Lock event row
        BEGIN
            SELECT 1 INTO v_dummy FROM events WHERE event_id = p_event_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20021, 'Event not found.');
        END;

        DELETE FROM events WHERE event_id = p_event_id;
    END;

    -- Computes event duration
    FUNCTION event_duration(p_event_id NUMBER) RETURN NUMBER IS
        v_start DATE;
        v_end DATE;
    BEGIN
        SELECT start_date, end_date INTO v_start, v_end FROM events WHERE event_id = p_event_id;
        RETURN v_end - v_start;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20022, 'Event not found.');
        WHEN TOO_MANY_ROWS THEN
            RAISE_APPLICATION_ERROR(-20023, 'Multiple events found with this ID.');
    END;

END pkg_events;
/

-----------------------------------------------------
-- Package Body: pkg_participation
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_participation IS

    -- Registers a user to an event
    PROCEDURE register_user(p_user_id NUMBER, p_event_id NUMBER) IS
        v_dummy INTEGER;
    BEGIN
        -- Ensure user exists
        BEGIN
            SELECT 1 INTO v_dummy FROM users WHERE user_id = p_user_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20030, 'User does not exist.');
        END;

        -- Ensure event exists
        BEGIN
            SELECT 1 INTO v_dummy FROM events WHERE event_id = p_event_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20031, 'Event does not exist.');
        END;

        -- Check if already registered
        BEGIN
            SELECT 1 INTO v_dummy
            FROM participation
            WHERE user_id = p_user_id AND event_id = p_event_id
            FOR UPDATE;
            -- Already registered
            RAISE_APPLICATION_ERROR(-20002, 'User already registered for the event.');
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO participation(user_id, event_id)
                VALUES (p_user_id, p_event_id);
        END;
    END;

    -- Unregisters a user
    PROCEDURE unregister_user(p_user_id NUMBER, p_event_id NUMBER) IS
    BEGIN
        DELETE FROM participation
        WHERE user_id = p_user_id AND event_id = p_event_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20032, 'No participation found to remove.');
        END IF;
    END;

END pkg_participation;
/

-----------------------------------------------------
-- Package Body: pkg_sightings
-----------------------------------------------------
CREATE OR REPLACE PACKAGE BODY pkg_sightings IS

    -- Logs a bird sighting
    PROCEDURE log_sighting(
        p_user_id NUMBER,
        p_event_id NUMBER,
        p_bird_id NUMBER,
        p_timestamp TIMESTAMP,
        p_note VARCHAR2
    ) IS
        v_dummy INTEGER;
    BEGIN
        -- Check and lock user
        BEGIN
            SELECT 1 INTO v_dummy FROM users WHERE user_id = p_user_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20040, 'User does not exist.');
        END;

        -- Check and lock event
        BEGIN
            SELECT 1 INTO v_dummy FROM events WHERE event_id = p_event_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20041, 'Event does not exist.');
        END;

        -- Check and lock bird species
        BEGIN
            SELECT 1 INTO v_dummy FROM bird_species WHERE bird_id = p_bird_id FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20042, 'Bird species does not exist.');
        END;

        -- Insert sighting
        INSERT INTO sightings (
            sighting_id, user_id, event_id, bird_id, timestamp, location_note
        )
        VALUES (
            seq_sightings.NEXTVAL, p_user_id, p_event_id, p_bird_id, p_timestamp, p_note
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20043, 'This sighting already exists.');
    END;

    -- Finds the most common bird seen
    FUNCTION most_common_bird RETURN VARCHAR2 IS
        v_common_name VARCHAR2(100);
    BEGIN
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
            RETURN 'No sightings recorded.';
    END;

END pkg_sightings;
/
