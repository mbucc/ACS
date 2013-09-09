--
-- upgrade-site-wide-search-3.4.1-3.4.2.sql
--
-- by phong@arsdigita.com
--
--
-- run this before you load the site-wide-search.sql file
--

drop table site_wide_index;

begin
  ctx_ddl.drop_preference('sws_user_datastore');
end;
/

drop index sws_ctx_index force;



