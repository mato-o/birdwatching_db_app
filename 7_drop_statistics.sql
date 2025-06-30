-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 7_drop_statistics.sql
-- Description:
-- Deletes optimizer statistics for all tables and indexes in the current schema.
-- Useful for testing how the optimizer behaves without statistics or forcing them to be recalculated.

BEGIN
    -- Loop over all user tables in the current schema
    FOR t IN (
        SELECT table_name
        FROM user_tables
    )
    LOOP
        -- Remove statistics for each table and its indexes
        DBMS_STATS.DELETE_TABLE_STATS(
            ownname => USER,          -- The current Oracle schema
            tabname => t.table_name,  -- Table name to process
            cascade_indexes => TRUE   -- Also delete statistics for indexes on the table
        );
    END LOOP;

    -- Informational output
    DBMS_OUTPUT.PUT_LINE('Statistics dropped for all user tables and indexes.');
END;
/
