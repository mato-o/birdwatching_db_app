-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 4_view_definition.sql
-- Description: Creates application-facing views simulating user interface screens.

-------------------------------------------------------
-- View: vw_birdwatchers
-- Lists all birdwatchers with age and event count.
-------------------------------------------------------

CREATE OR REPLACE VIEW vw_birdwatchers AS
SELECT
    u.user_id,
    u.full_name,
    u.email,
    TRUNC(MONTHS_BETWEEN(SYSDATE, u.registration_date) / 12) AS years_since_registration,
    (
        SELECT COUNT(*) 
        FROM participation p
        WHERE p.user_id = u.user_id
    ) AS num_events
FROM users u;

-------------------------------------------------------
-- View: vw_all_events
-- Shows event details along with location name.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_all_events AS
SELECT
    e.event_id,
    e.name AS event_name,
    e.start_date,
    e.end_date,
    l.name AS location_name,
    l.region,
    l.latitude,
    l.longitude
FROM events e
JOIN locations l ON e.location_id = l.location_id;

-------------------------------------------------------
-- View: vw_event_participants
-- Shows which birdwatchers are registered for which events.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_event_participants AS
SELECT
    p.user_id,
    u.full_name AS participant_name,
    u.email,
    e.name AS event_name,
    e.start_date
FROM participation p
JOIN users u ON p.user_id = u.user_id
JOIN events e ON p.event_id = e.event_id;

-------------------------------------------------------
-- View: vw_registered_birds
-- Lists all birds and their assigned species.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_registered_birds AS
SELECT
    DISTINCT s.bird_id,
    bs.common_name,
    bs.scientific_name
FROM sightings s
JOIN bird_species bs ON s.bird_id = bs.bird_id;

-------------------------------------------------------
-- View: vw_observation_records
-- Shows observations with observer, bird, species, and event info.
-------------------------------------------------------
CREATE OR REPLACE VIEW vw_observation_records AS
SELECT
    s.sighting_id,
    u.full_name AS observer_name,
    bs.common_name AS bird_common_name,
    bs.scientific_name,
    e.name AS event_name,
    s.timestamp,
    s.location_note
FROM sightings s
JOIN users u ON s.user_id = u.user_id
JOIN events e ON s.event_id = e.event_id
JOIN bird_species bs ON s.bird_id = bs.bird_id;
