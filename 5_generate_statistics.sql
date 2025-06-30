-- Author: Matej Bujňák
-- Date: 2025-06-16
-- Script: 5_generate_statistics.sql
-- Description:
-- This script gathers optimizer statistics on all tables owned by the current user/schema.
-- It uses DBMS_STATS to improve the performance of SQL queries via the cost-based optimizer.

BEGIN
    -- Loop through all tables in the current schema
    FOR t IN (
        SELECT table_name
        FROM user_tables
    )
    LOOP
        -- Collect statistics for the current table:
        -- - OWNNAME: schema name (current user)
        -- - TABNAME: table name
        -- - CASCADE: TRUE -> also gather stats for indexes on the table
        -- - METHOD_OPT: auto histograms for all columns
        DBMS_STATS.GATHER_TABLE_STATS(
            ownname => USER,
            tabname => t.table_name,
            cascade => TRUE,               -- Also gather index statistics
            method_opt => 'FOR ALL COLUMNS SIZE AUTO'  -- Use automatic histogram sizing
        );
    END LOOP;

    -- Print confirmation message
    DBMS_OUTPUT.PUT_LINE('Statistics gathered for all user tables.');
END;
/
