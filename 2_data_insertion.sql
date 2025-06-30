-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 2_data_insertion.sql
-- Description:
-- Inserts demonstration data into the birdwatching schema.
-- Uses sequences to generate primary keys, with checks to avoid duplicates.

SET SERVEROUTPUT ON;

DECLARE
    -- === Variables to store generated IDs ===
    v_user1_id NUMBER;
    v_user2_id NUMBER;
    v_loc1_id NUMBER;
    v_loc2_id NUMBER;
    v_event1_id NUMBER;
    v_event2_id NUMBER;
    v_bird1_id NUMBER;
    v_bird2_id NUMBER;
    v_bird3_id NUMBER;
BEGIN
    -- USERS
    -- Insert Alice if not exists
    BEGIN
        SELECT user_id INTO v_user1_id
        FROM users
        WHERE email = 'alice@example.com';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO users(user_id, full_name, email)
            VALUES (seq_users.NEXTVAL, 'Alice Johnson', 'alice@example.com')
            RETURNING user_id INTO v_user1_id;
    END;

    -- Insert Bob if not exists
    BEGIN
        SELECT user_id INTO v_user2_id
        FROM users
        WHERE email = 'bob@example.com';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO users(user_id, full_name, email)
            VALUES (seq_users.NEXTVAL, 'Bob Smith', 'bob@example.com')
            RETURNING user_id INTO v_user2_id;
    END;

    -- LOCATIONS
    -- Insert Green Park if not exists
    BEGIN
        SELECT location_id INTO v_loc1_id
        FROM locations
        WHERE name = 'Green Park' AND region = 'North';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO locations(location_id, name, region, latitude, longitude)
            VALUES (seq_locations.NEXTVAL, 'Green Park', 'North', 50.087, 14.421)
            RETURNING location_id INTO v_loc1_id;
    END;

    -- Insert Blue Lake if not exists
    BEGIN
        SELECT location_id INTO v_loc2_id
        FROM locations
        WHERE name = 'Blue Lake' AND region = 'West';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO locations(location_id, name, region, latitude, longitude)
            VALUES (seq_locations.NEXTVAL, 'Blue Lake', 'West', 49.800, 13.500)
            RETURNING location_id INTO v_loc2_id;
    END;

    -- EVENTS
    -- Insert Spring Birdwatch
    BEGIN
        SELECT event_id INTO v_event1_id
        FROM events
        WHERE name = 'Spring Birdwatch' AND start_date = DATE '2025-04-01';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO events(event_id, name, location_id, start_date, end_date)
            VALUES (seq_events.NEXTVAL, 'Spring Birdwatch', v_loc1_id, DATE '2025-04-01', DATE '2025-04-03')
            RETURNING event_id INTO v_event1_id;
    END;

    -- Insert Autumn Birdwatch
    BEGIN
        SELECT event_id INTO v_event2_id
        FROM events
        WHERE name = 'Autumn Birdwatch' AND start_date = DATE '2025-09-10';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO events(event_id, name, location_id, start_date, end_date)
            VALUES (seq_events.NEXTVAL, 'Autumn Birdwatch', v_loc2_id, DATE '2025-09-10', DATE '2025-09-12')
            RETURNING event_id INTO v_event2_id;
    END;

    -- PARTICIPATION
    BEGIN
        INSERT INTO participation(user_id, event_id) VALUES (v_user1_id, v_event1_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
    BEGIN
        INSERT INTO participation(user_id, event_id) VALUES (v_user2_id, v_event1_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
    BEGIN
        INSERT INTO participation(user_id, event_id) VALUES (v_user2_id, v_event2_id);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;

    -- BIRD SPECIES
    -- Insert European Robin
    BEGIN
        SELECT bird_id INTO v_bird1_id
        FROM bird_species
        WHERE common_name = 'European Robin';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO bird_species(bird_id, common_name, scientific_name)
            VALUES (seq_bird_species.NEXTVAL, 'European Robin', 'Erithacus rubecula')
            RETURNING bird_id INTO v_bird1_id;
    END;

    -- Insert Common Blackbird
    BEGIN
        SELECT bird_id INTO v_bird2_id
        FROM bird_species
        WHERE common_name = 'Common Blackbird';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO bird_species(bird_id, common_name, scientific_name)
            VALUES (seq_bird_species.NEXTVAL, 'Common Blackbird', 'Turdus merula')
            RETURNING bird_id INTO v_bird2_id;
    END;

    -- Insert Blue Tit
    BEGIN
        SELECT bird_id INTO v_bird3_id
        FROM bird_species
        WHERE common_name = 'Blue Tit';
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO bird_species(bird_id, common_name, scientific_name)
            VALUES (seq_bird_species.NEXTVAL, 'Blue Tit', 'Cyanistes caeruleus')
            RETURNING bird_id INTO v_bird3_id;
    END;

    -- SIGHTINGS
    -- Insert only if does not exist
    BEGIN
        INSERT INTO sightings(sighting_id, user_id, event_id, bird_id, timestamp, location_note)
        VALUES (
            seq_sightings.NEXTVAL,
            v_user1_id, v_event1_id, v_bird1_id,
            TO_TIMESTAMP('2025-04-01 08:15:00', 'YYYY-MM-DD HH24:MI:SS'),
            'Near entrance'
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;

    BEGIN
        INSERT INTO sightings(sighting_id, user_id, event_id, bird_id, timestamp, location_note)
        VALUES (
            seq_sightings.NEXTVAL,
            v_user2_id, v_event1_id, v_bird2_id,
            TO_TIMESTAMP('2025-04-01 08:30:00', 'YYYY-MM-DD HH24:MI:SS'),
            'By the lake'
        );
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;

    -- WEATHER CONDITIONS (one per event)
    BEGIN
        INSERT INTO weather_conditions(event_id, temperature, conditions, wind_speed)
        VALUES (v_event1_id, 12.5, 'Sunny', 5.2);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;

    -- NOTES
    BEGIN
        INSERT INTO notes(note_id, user_id, event_id, note_text)
        VALUES (seq_notes.NEXTVAL, v_user1_id, v_event1_id, 'Saw a robin building a nest.');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
END;
/

COMMIT;
