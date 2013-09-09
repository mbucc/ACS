--
-- recreate-site-wide-search.sql
--
-- by branimir@arsdigita.com
--
-- re-create intermedia index for site wide index
-- Typically you'll have to run this whenever you import the whole
-- database or indexing gets screwed up for some other reason.  Note that
-- it may take a LONG time.
--
-- You don't need to run this if you are just installing the system from scratch
--
-- NOTE! Log in as your normal user, NOT as ctxsys
--  
--
-- phong@arsdigita.com 8/25/2000
-- The procedure for the sws_user_datastore preference needs your database username
-- appended to the end of it.
--
-- COMMAND TO RUN: sqlplus username/password @recreate-site-wide-search.sql username       
--

begin
  ctx_ddl.drop_preference('sws_user_datastore');
end;
/

begin
  ctx_ddl.create_preference('sws_user_datastore', 'user_datastore');
  ctx_ddl.set_attribute('sws_user_datastore', 'procedure', 'sws_user_proc_&1');
end;
/


drop index sws_ctx_index;

create index sws_ctx_index on site_wide_index (datastore)
indextype is ctxsys.context parameters ('datastore sws_user_datastore memory 250M section group swsgroup');
