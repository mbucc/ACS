-- 
-- www/doc/sql/upgrade-contest-3.4.9-3.4.10.sql
-- 
-- The column "blather" in contest_domains was mysteriously changed 
-- to "preamble" without changing any of the SQL statements in the system.
-- 
-- This script should effectively change the name back while preserving 
-- any information stored in the column.
-- 
-- Before running this, check columns contest_domains has in your
-- installation.  If it has blather rather than preamble, you don't need 
-- to run this.  
-- 
-- This procedure is not transactional, so you might want to shut down
-- your server while you do it.


-- Add the correct column

alter table contest_domains add (
    blather         varchar2(4000)
);

-- move any existing information

update contest_domains set blather = preamble;

-- drop the other column

alter table contest_domains drop column preamble;

