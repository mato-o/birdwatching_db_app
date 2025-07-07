-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 6_test_script.sql
-- Description:
-- Tests core functionality of the birdwatching application using package procedures/functions.
-- Verifies correctness of user creation, event creation, participation registration,
-- sighting logging, querying functions, and error handling (such as preventing deletion
-- of users still registered to events).

SET SERVEROUTPUT ON;

DECLARE
    -- Variable declarations for capturing IDs of inserted or existing data
    v_user1_id users.user_id%TYPE;  -- Alice
    v_user2_id users.user_id%TYPE;  -- Bob
    v_event1_id events.event_id%TYPE;
    v_event2_id events.event_id%TYPE;
    v_bird1_id bird_species.bird_id%TYPE;
    v_bird2_id bird_species.bird_id%TYPE;
    v_location_id locations.location_id%TYPE;
    v_count INTEGER;  -- Used to check existence
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Ensuring test location exists ===');
    BEGIN
        -- Try to find a location named "Test Location" (to avoid duplicates)
        SELECT location_id
        INTO v_location_id
        FROM locations
        WHERE name = 'Test Location'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Insert the location if it does not exist
            INSERT INTO locations (location_id, name, region, latitude, longitude)
            VALUES (
                (SELECT COALESCE(MAX(location_id), 0) + 1 FROM locations),
                'Test Location',
                'Test Region',
                48.15,
                17.11
            )
            RETURNING location_id INTO v_location_id;
            COMMIT;
    END;

    DBMS_OUTPUT.PUT_LINE('=== Inserting users and capturing IDs ===');
    -- Insert User 1 (or fetch existing by email)
    BEGIN
        SELECT user_id
        INTO v_user1_id
        FROM users
        WHERE email = 'alice1@example.com'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO users (user_id, full_name, email, registration_date)
            VALUES (
                (SELECT COALESCE(MAX(user_id), 0) + 1 FROM users),
                'Alice Smith',
                'alice1@example.com',
                SYSDATE
            )
            RETURNING user_id INTO v_user1_id;
    END;

    -- Insert User 2 (or fetch existing)
    BEGIN
        SELECT user_id
        INTO v_user2_id
        FROM users
        WHERE email = 'bob1@example.com'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO users (user_id, full_name, email, registration_date)
            VALUES (
                (SELECT COALESCE(MAX(user_id), 0) + 1 FROM users),
                'Bob Johnson',
                'bob1@example.com',
                SYSDATE
            )
            RETURNING user_id INTO v_user2_id;
    END;

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_users.change_email ===');
    -- Update Alice's email if needed
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM users
        WHERE email = 'alice2@example.com';

        IF v_count = 0 THEN
            pkg_users.change_email(v_user1_id, 'alice2@example.com');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Email alice2@example.com already exists. Skipping update.');
        END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('=== Inserting events and capturing IDs ===');
    -- Insert Event 1 or reuse
    BEGIN
        SELECT event_id
        INTO v_event1_id
        FROM events
        WHERE name = 'Spring Birdwatch'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO events (event_id, name, location_id, start_date, end_date)
            VALUES (
                (SELECT COALESCE(MAX(event_id), 0) + 1 FROM events),
                'Spring Birdwatch',
                v_location_id,
                DATE '2025-05-01',
                DATE '2025-05-03'
            )
            RETURNING event_id INTO v_event1_id;
    END;

    -- Insert Event 2 or reuse
    BEGIN
        SELECT event_id
        INTO v_event2_id
        FROM events
        WHERE name = 'Summer Migration'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO events (event_id, name, location_id, start_date, end_date)
            VALUES (
                (SELECT COALESCE(MAX(event_id), 0) + 1 FROM events),
                'Summer Migration',
                v_location_id,
                DATE '2025-06-01',
                DATE '2025-06-02'
            )
            RETURNING event_id INTO v_event2_id;
    END;

    DBMS_OUTPUT.PUT_LINE('=== Inserting bird species and capturing IDs ===');
    -- Insert Bird 1 (Sparrow)
    BEGIN
        SELECT bird_id
        INTO v_bird1_id
        FROM bird_species
        WHERE common_name = 'Sparrow'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO bird_species (bird_id, common_name, scientific_name)
            VALUES (
                (SELECT COALESCE(MAX(bird_id), 0) + 1 FROM bird_species),
                'Sparrow',
                'Passer domesticus'
            )
            RETURNING bird_id INTO v_bird1_id;
    END;

    -- Insert Bird 2 (Blackbird)
    BEGIN
        SELECT bird_id
        INTO v_bird2_id
        FROM bird_species
        WHERE common_name = 'Blackbird'
        AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO bird_species (bird_id, common_name, scientific_name)
            VALUES (
                (SELECT COALESCE(MAX(bird_id), 0) + 1 FROM bird_species),
                'Blackbird',
                'Turdus merula'
            )
            RETURNING bird_id INTO v_bird2_id;
    END;

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_participation.register_user ===');
    -- Register Alice to Event 1
    BEGIN
        SELECT 1
        INTO v_count
        FROM participation
        WHERE user_id = v_user1_id
        AND event_id = v_event1_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pkg_participation.register_user(v_user1_id, v_event1_id);
    END;

    -- Register Bob to Event 1
    BEGIN
        SELECT 1
        INTO v_count
        FROM participation
        WHERE user_id = v_user2_id
        AND event_id = v_event1_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pkg_participation.register_user(v_user2_id, v_event1_id);
    END;

    -- Register Bob to Event 2
    BEGIN
        SELECT 1
        INTO v_count
        FROM participation
        WHERE user_id = v_user2_id
        AND event_id = v_event2_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pkg_participation.register_user(v_user2_id, v_event2_id);
    END;

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_sightings.log_sighting ===');
    -- Log a few sightings
    pkg_sightings.log_sighting(v_user1_id, v_event1_id, v_bird1_id, SYSTIMESTAMP, 'Near the lake');
    pkg_sightings.log_sighting(v_user2_id, v_event1_id, v_bird2_id, SYSTIMESTAMP, 'In the trees');
    pkg_sightings.log_sighting(v_user2_id, v_event2_id, v_bird1_id, SYSTIMESTAMP, 'On the river bank');

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_sightings.most_common_bird ===');
    DECLARE
        v_bird_name VARCHAR2(100);
    BEGIN
        -- Retrieve the most commonly sighted bird
        v_bird_name := pkg_sightings.most_common_bird;
        DBMS_OUTPUT.PUT_LINE('Most commonly sighted bird: ' || v_bird_name);
    END;

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_events.event_duration ===');
    DECLARE
        v_duration NUMBER;
    BEGIN
        -- Print event duration
        v_duration := pkg_events.event_duration(v_event1_id);
        DBMS_OUTPUT.PUT_LINE('Event duration: ' || v_duration || ' days');
    END;

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_participation.unregister_user ===');
    -- Unregister Bob from Event 2
    pkg_participation.unregister_user(v_user2_id, v_event2_id);

    DBMS_OUTPUT.PUT_LINE('=== Testing pkg_users.delete_user (with participation) ===');
    BEGIN
        -- This should fail because Bob is still registered in Event 1
        pkg_users.delete_user(v_user2_id);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Expected error: ' || SQLERRM);
    END;

    DBMS_OUTPUT.PUT_LINE('=== Unregistering user to allow deletion ===');
    pkg_participation.unregister_user(v_user2_id, v_event1_id);

    DBMS_OUTPUT.PUT_LINE('=== Deleting user sightings to allow deletion ===');
    DELETE FROM sightings WHERE user_id = v_user2_id;
    COMMIT;

    -- Now Bob can be deleted
    pkg_users.delete_user(v_user2_id);

    DBMS_OUTPUT.PUT_LINE('All tests completed.');
END;
/

SELECT /*+RULE*/ * FROM vw_observation_records WHERE timestamp>=TRUNC(sysdate);
SELECT /*+RULE*/ * FROM sightings WHERE timestamp>=TRUNC(sysdate);
