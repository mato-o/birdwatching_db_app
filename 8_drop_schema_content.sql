-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 8_drop_schema_content.sql
-- Description:
-- Drops all database objects created by the birdwatching application.
-- Drops views first, then triggers, packages, sequences, and tables.

-- Drop views first (they depend on tables)
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_observation_records';
    EXECUTE IMMEDIATE 'DROP VIEW vw_registered_birds';
    EXECUTE IMMEDIATE 'DROP VIEW vw_event_participants';
    EXECUTE IMMEDIATE 'DROP VIEW vw_all_events';
    EXECUTE IMMEDIATE 'DROP VIEW vw_birdwatchers';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping views: ' || SQLERRM);
END;
/

-- Drop triggers
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_no_user_delete_with_sightings';
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_log_deleted_bird';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping triggers: ' || SQLERRM);
END;
/

-- Drop package bodies and specifications
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_users';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_users';

    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_events';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_events';

    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_participation';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_participation';

    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_sightings';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_sightings';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping packages: ' || SQLERRM);
END;
/

-- Drop sequences
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_users';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_locations';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_events';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_bird_species';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_sightings';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_notes';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping sequences: ' || SQLERRM);
END;
/

-- Drop tables (in reverse dependency order)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE bird_species_log CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE notes CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE weather_conditions CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE sightings CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE participation CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE events CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE bird_species CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE locations CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE users CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping tables: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Schema content dropped successfully.');
END;
/
