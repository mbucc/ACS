-- Ticket v3.x
--
-- Nuke the old ticket system tables.  Do only after 
-- ticket-save.sql has been run (and was successful).
--
drop function ticket_one_if_blocker;
drop function ticket_one_if_high_priority;
drop procedure ticket_update_for_response;
drop table ticket_issue_notifications;
drop trigger response_modification_time;
drop table ticket_issue_responses;
drop sequence ticket_response_id_sequence;
drop table ticket_xrefs;
drop table ticket_issue_assignments;
drop trigger ticket_activity_logger;
drop table ticket_changes;
drop trigger ticket_modification_time;
drop table ticket_issues;
-- DO NOT DROP SINCE WE WANT TO KEEP IDs CONSISTENT
-- drop sequence ticket_issue_id_sequence;
drop table ticket_priorities;
drop table ticket_assignments;
-- These we can drop since consistency is not an issue...
drop sequence ticket_assignment_id_sequence;
drop sequence ticket_project_admins_sequence;
drop table ticket_project_admins;
drop table ticket_projects;
drop sequence ticket_project_id_sequence;
