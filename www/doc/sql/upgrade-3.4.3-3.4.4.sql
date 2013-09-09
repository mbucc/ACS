-- /www/doc/sql/upgrade-3.4.3-3.4.4.sql
--
-- Script to upgrade an ACS 3.4.3 database to ACS 3.4.4
-- 
-- upgrade-3.4.3-3.4.4.sql,v 1.1.2.4 2000/10/04 22:40:23 kevin Exp

-- 
-- Remove is_checker references from intranet
--

-- these were a mistake
--
-- drop function im_proj_url_from_type;
-- 
-- drop index im_proj_url_machine_idx;
-- drop index im_proj_url_url_proj_idx;
-- 
-- drop table im_project_url_map;

-- This wasn't present at the time 3.4.4 was released, but is the 
-- correct thing to do.

alter table im_project_url_map drop column machine_id;


--
-- Drop ischecker data model
--

drop sequence ishack_website_id_sequence ;
drop sequence is_names_sequence ;

drop table ishack_websites ;
drop table is_machines_names_map; 
drop table is_machines_ips_map ;
drop table is_names ;
drop sequence is_ip_sequence ;
drop table is_ip_addresses ;
drop sequence is_network_id_sequence ;
drop table is_networks ;
drop sequence is_host_locations_sequence ;
drop function is_parse_hostname;
drop table is_users ;
drop table is_notices ;
drop sequence is_notices_seq ;
drop table is_notification_rules ;
drop sequence is_notification_rules_seq ;
drop table is_alerts ;
drop sequence is_alert_sequence ;
drop table is_mail_log ;
drop table is_event_log ;
drop sequence is_event_log_sequence ;
drop table is_web_services ;
drop sequence is_web_services_seq ;
drop table is_mail_services ;
drop sequence is_mail_services_seq ;
DROP INDEX XIF24IS_SERVICES;
drop table is_services ;
drop sequence is_services_seq ;
drop table is_group_machine_map ;
drop sequence is_machines_seq;
DROP TABLE is_machines ;
drop table is_host_locations ;
drop table is_machine_uses ;
drop sequence is_machine_use_id_seq ;
drop table is_sent_email_log ;
drop sequence is_sent_email_seq ;
drop table is_test_proc_log ;
drop sequence is_test_sequence ;
drop sequence is_mail_run_number ;
drop table is_test_state ;
drop table is_global_state ;
