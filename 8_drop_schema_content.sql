-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 8_drop_schema_content.sql
-- Description: Drops all database objects created by the application.

-- Drop views first (depend on tables and other objects)
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW vw_event_participants';
    EXECUTE IMMEDIATE 'DROP VIEW vw_observation_records';
    EXECUTE IMMEDIATE 'DROP VIEW vw_registered_birds';
    EXECUTE IMMEDIATE 'DROP VIEW vw_all_events';
    EXECUTE IMMEDIATE 'DROP VIEW vw_birdwatchers';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping views: ' || SQLERRM);
END;
/

-- Drop triggers
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER trg_check_age';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping triggers: ' || SQLERRM);
END;
/

-- Drop packages (body first, then spec)
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_birdwatcher';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_birdwatcher';
    
    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_event';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_event';

    EXECUTE IMMEDIATE 'DROP PACKAGE BODY pkg_observation';
    EXECUTE IMMEDIATE 'DROP PACKAGE pkg_observation';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping packages: ' || SQLERRM);
END;
/

-- Drop sequences
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_bird_id';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_watcher_id';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_event_id';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_participation_id';
    EXECUTE IMMEDIATE 'DROP SEQUENCE seq_observation_id';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping sequences: ' || SQLERRM);
END;
/

-- Drop tables last (in reverse dependency order)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Observation CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE EventParticipation CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Event CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Birdwatcher CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Bird CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Species CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Location CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error dropping tables: ' || SQLERRM);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Schema content dropped successfully.');
END;
/
