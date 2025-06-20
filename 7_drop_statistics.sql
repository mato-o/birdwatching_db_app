-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 7_drop_statistics.sql
-- Description: Deletes optimizer statistics for all tables and indexes in the current schema.

BEGIN
    -- Loop over user tables and delete statistics
    FOR t IN (
        SELECT table_name
        FROM user_tables
    )
    LOOP
        DBMS_STATS.DELETE_TABLE_STATS(
            ownname => USER,
            tabname => t.table_name,
            cascade_indexes => TRUE
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Statistics dropped for all user tables and indexes.');
END;
/
