--
-- /www/doc/sql/job-listings-drop.sql
--
-- Drops the job listings tables
--
-- @author mbryzek@arsdigita.com
-- @creation-date 1/9/2001
--
-- job-listings-drop.sql,v 1.1.2.1 2001/01/10 18:04:37 mbryzek Exp
--

drop sequence job_listing_id_seq;
drop sequence jl_email_template_id_seq;

drop table job_listing_email_template_map;
drop table job_listing_email_templates;
drop table job_listing_office_map;
drop table job_listings;
