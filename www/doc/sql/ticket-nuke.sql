-- Ticket v3.x
--
-- Delete the v3.x ticket system tables.  Does not 
-- affect the ticket-save.sql saved tables from an 
-- old version of ticket tracker.
--

drop view ticket_pretty_audit;
drop view ticket_pretty;
drop trigger TICKET_ISSUES_I_audit_tr;
drop function ticket_one_if_blocker;
drop function ticket_one_if_high_priority;
drop table ticket_issue_notifications;
drop trigger ticket_response_mod_time;
drop table ticket_xrefs;
drop table ticket_issue_assignments;

drop trigger ticket_modification_time;
drop view ticket_issues_audit;
drop view ticket_issues;

drop table ticket_email_alerts;
drop sequence ticket_alert_id_sequence;

drop table ticket_index;

drop table ticket_issues_i_audit;
drop table ticket_issues_i;
-- DO NOT NUKE SO WE CAN PRESERVE IDs ON UPGRADE!
-- drop sequence ticket_issue_id_sequence;

drop table ticket_assignments;
drop sequence ticket_assignment_id_seq;

drop function ticket_admin_group_id;

drop table ticket_domain_project_map;

drop table ticket_domains;
drop sequence ticket_domain_id_sequence;

drop table ticket_deadlines;

drop table ticket_projects;
drop sequence ticket_project_id_sequence;

drop view ticket_codes;
drop table ticket_status_info;
drop table ticket_code_sets;
drop table ticket_codes_i;
drop sequence ticket_code_id_sequence;

-- clean up the comments.
delete from general_comments where on_which_table like 'ticket_issues%';
