-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 2_data_insertion.sql
-- Description:
-- This script inserts demonstration data into the birdwatching schema.
-- It uses sequences to generate primary keys and populates all core tables
-- with sample users, locations, events, bird species, sightings, weather, and notes.

SET SERVEROUTPUT ON;

DECLARE
    -- === Variables to store generated IDs ===
    -- Users
    v_user1_id NUMBER;
    v_user2_id NUMBER;

    -- Locations
    v_loc1_id NUMBER;
    v_loc2_id NUMBER;

    -- Events
    v_event1_id NUMBER;
    v_event2_id NUMBER;

    -- Bird species ID
    v_bird1_id NUMBER;
    v_bird2_id NUMBER;
    v_bird3_id NUMBER;

    -- Sightings
    v_sighting_id NUMBER;

    -- Notes
    v_note_id NUMBER;

BEGIN
    -- USERS
    -- Insert two demo users into the system
    INSERT INTO users(user_id, full_name, email)
    VALUES (seq_users.NEXTVAL, 'Alice Johnson', 'alice@example.com')
    RETURNING user_id INTO v_user1_id;

    INSERT INTO users(user_id, full_name, email)
    VALUES (seq_users.NEXTVAL, 'Bob Smith', 'bob@example.com')
    RETURNING user_id INTO v_user2_id;

    -- LOCATIONS
    -- Insert two locations where events will take place
    INSERT INTO locations(location_id, name, region, latitude, longitude)
    VALUES (seq_events.NEXTVAL, 'Green Park', 'North', 50.087, 14.421)
    RETURNING location_id INTO v_loc1_id;

    INSERT INTO locations(location_id, name, region, latitude, longitude)
    VALUES (seq_events.NEXTVAL, 'Blue Lake', 'West', 49.800, 13.500)
    RETURNING location_id INTO v_loc2_id;

    -- EVENTS
    -- Insert two events held at different times and places
    INSERT INTO events(event_id, name, location_id, start_date, end_date)
    VALUES (seq_events.NEXTVAL, 'Spring Birdwatch', v_loc1_id, DATE '2025-04-01', DATE '2025-04-03')
    RETURNING event_id INTO v_event1_id;

    INSERT INTO events(event_id, name, location_id, start_date, end_date)
    VALUES (seq_events.NEXTVAL, 'Autumn Birdwatch', v_loc2_id, DATE '2025-09-10', DATE '2025-09-12')
    RETURNING event_id INTO v_event2_id;

    -- PARTICIPATION
    -- Link users to events they will attend
    INSERT INTO participation(user_id, event_id) VALUES (v_user1_id, v_event1_id);
    INSERT INTO participation(user_id, event_id) VALUES (v_user2_id, v_event1_id);
    INSERT INTO participation(user_id, event_id) VALUES (v_user2_id, v_event2_id);

    -- BIRD SPECIES
    -- Add bird species to the system for use in sightings
    INSERT INTO bird_species(bird_id, common_name, scientific_name)
    VALUES (seq_events.NEXTVAL, 'European Robin', 'Erithacus rubecula')
    RETURNING bird_id INTO v_bird1_id;

    INSERT INTO bird_species(bird_id, common_name, scientific_name)
    VALUES (seq_events.NEXTVAL, 'Common Blackbird', 'Turdus merula')
    RETURNING bird_id INTO v_bird2_id;

    INSERT INTO bird_species(bird_id, common_name, scientific_name)
    VALUES (seq_events.NEXTVAL, 'Blue Tit', 'Cyanistes caeruleus')
    RETURNING bird_id INTO v_bird3_id;

    -- SIGHTINGS
    -- Record bird sightings made by the users during the event
    INSERT INTO sightings(sighting_id, user_id, event_id, bird_id, timestamp, location_note)
    VALUES (seq_sightings.NEXTVAL, v_user1_id, v_event1_id, v_bird1_id,
            TO_TIMESTAMP('2025-04-01 08:15:00', 'YYYY-MM-DD HH24:MI:SS'),
            'Near entrance');

    INSERT INTO sightings(sighting_id, user_id, event_id, bird_id, timestamp, location_note)
    VALUES (seq_sightings.NEXTVAL, v_user2_id, v_event1_id, v_bird2_id,
            TO_TIMESTAMP('2025-04-01 08:30:00', 'YYYY-MM-DD HH24:MI:SS'),
            'By the lake');

    -- WEATHER CONDITIONS
    -- Store weather for the first event
    INSERT INTO weather_conditions(event_id, temperature, conditions, wind_speed)
    VALUES (v_event1_id, 12.5, 'Sunny', 5.2);

    -- NOTES
    -- Add a personal note made by Alice about the event
    INSERT INTO notes(note_id, user_id, event_id, note_text)
    VALUES (seq_notes.NEXTVAL, v_user1_id, v_event1_id, 'Saw a robin building a nest.');
END;
/

COMMIT;
