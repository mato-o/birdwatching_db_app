-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 4_view_definition.sql
-- Description:
-- Creates application-facing views simulating user interface screens.
-- Each view presents data for birdwatching management in a human-readable way.

-------------------------------------------------------
-- View: vw_birdwatchers
-- Lists all birdwatchers, showing their email, how long they have been registered,
-- and how many events they are registered for.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_birdwatchers AS
SELECT
    u.user_id,                                            -- Unique ID of the user
    u.full_name,                                          -- Full name
    u.email,                                              -- Email address
    TRUNC(MONTHS_BETWEEN(SYSDATE, u.registration_date)/12) AS years_since_registration, -- Years since registered
    (
        SELECT COUNT(*)
        FROM participation p
        WHERE p.user_id = u.user_id
    ) AS num_events                                       -- Number of registered events
FROM users u;

-------------------------------------------------------
-- View: vw_all_events
-- Shows each event with dates and detailed location info.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_all_events AS
SELECT
    e.event_id,                                           -- Event unique ID
    e.name AS event_name,                                 -- Event name
    e.start_date,                                         -- Start date
    e.end_date,                                           -- End date
    l.name AS location_name,                              -- Location name
    l.region,                                             -- Region
    l.latitude,                                           -- Latitude (GPS)
    l.longitude                                           -- Longitude (GPS)
FROM events e
JOIN locations l ON e.location_id = l.location_id;

-------------------------------------------------------
-- View: vw_event_participants
-- Shows users registered for each event, for event rosters.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_event_participants AS
SELECT
    p.user_id,                                            -- User ID
    u.full_name AS participant_name,                      -- Full name of participant
    u.email,                                              -- Email
    e.name AS event_name,                                 -- Event name
    e.start_date                                          -- Event start date
FROM participation p
JOIN users u ON p.user_id = u.user_id
JOIN events e ON p.event_id = e.event_id;

-------------------------------------------------------
-- View: vw_registered_birds
-- Lists bird species that have been sighted (distinct).
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_registered_birds AS
SELECT
    DISTINCT s.bird_id,                                   -- Bird ID
    bs.common_name,                                       -- Common name
    bs.scientific_name                                    -- Scientific (Latin) name
FROM sightings s
JOIN bird_species bs ON s.bird_id = bs.bird_id;

-------------------------------------------------------
-- View: vw_observation_records
-- Shows detailed observations linking users, events, and birds.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_observation_records AS
SELECT
    s.sighting_id,                                        -- Sighting unique ID
    u.full_name AS observer_name,                         -- Who observed
    bs.common_name AS bird_common_name,                   -- Bird common name
    bs.scientific_name,                                   -- Bird Latin name
    e.name AS event_name,                                 -- Event name
    s.timestamp,                                          -- Observation timestamp
    s.location_note                                       -- Free-text note
FROM sightings s
JOIN users u ON s.user_id = u.user_id
JOIN events e ON s.event_id = e.event_id
JOIN bird_species bs ON s.bird_id = bs.bird_id;
