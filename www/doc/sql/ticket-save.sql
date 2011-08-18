-- Ticket v3.x
--
-- save a copy of all the ticket data from pre v 3.0 ticket tracker.
--
create table  ticket_projects_s as select * from ticket_projects;
create table  ticket_project_admins_s as select * from ticket_project_admins;
create table  ticket_assignments_s as select * from ticket_assignments;
create table  ticket_priorities_s as select * from ticket_priorities;
create table  ticket_issues_s as select * from ticket_issues;
create table  ticket_changes_s as select * from ticket_changes;
create table  ticket_issue_assignments_s as select * from ticket_issue_assignments;
create table  ticket_xrefs_s as select * from ticket_xrefs;
create table  ticket_issue_responses_s as select * from ticket_issue_responses;
create table  ticket_issue_notifications_s as select * from ticket_issue_notifications;

