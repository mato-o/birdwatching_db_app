-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 5_generate_statistics.sql
-- Description: Collects statistics on all user tables for cost-based optimizer.

BEGIN
    -- Gather statistics for all user tables
    FOR t IN (
        SELECT table_name
        FROM user_tables
    )
    LOOP
        DBMS_STATS.GATHER_TABLE_STATS(
            ownname => USER,
            tabname => t.table_name,
            cascade => TRUE,          -- Gather index stats as well
            method_opt => 'FOR ALL COLUMNS SIZE AUTO'
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Statistics gathered for all user tables.');
END;
/
