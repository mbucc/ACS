-- Ticket Tracker v3.x
--
-- Driving data 
--


-- add the module to acs_modules

insert into acs_modules (
        module_key, pretty_name, public_directory, admin_directory,
        site_wide_admin_directory, module_type, supports_scoping_p, 
        documentation_url, data_model_url, description
) values ( 
        'ticket','Ticket System','/ticket/','/ticket/admin/','/admin/ticket/','system','f',
        '/doc/ticket.html','doc/sql/ticket/sql',  'The ticket system: for tracking bugs tasks and enhancement requests');
       
-- create an administration group for ticket tracker administration
begin
   administration_group_add ('Ticket Admin Staff', 'ticket', 'ticket', NULL, 'f', '/ticket/admin/');
end;
/

declare
 n_ticket_rows		integer;
 n_ticket_i_rows	integer;
begin
 select count(*) into n_ticket_rows from table_acs_properties where table_name = 'ticket_issues';
 if n_ticket_rows = 0 then 
   insert into table_acs_properties
    (table_name, module_key, section_name, user_url_stub, admin_url_stub)
    values
    ('ticket_issues', 'ticket', 'Tickets','/ticket/issue-view.tcl?msg_id=','/ticket/issue-new.tcl?msg_id=');
 end if;
 select count(*) into n_ticket_i_rows from table_acs_properties where table_name = 'ticket_issues_i';
 if n_ticket_i_rows = 0 then 
   insert into table_acs_properties
    (table_name, module_key, section_name, user_url_stub, admin_url_stub)
    values
    ('ticket_issues_i', 'ticket', 'New Tickets','/ticket/issue-view.tcl?msg_id=','/ticket/issue-new.tcl?msg_id=');
 end if;
end;
/

-- we need a project "Incoming" for random incoming email
insert into ticket_projects (project_id, created_by, title,
        title_long, start_date, code_set, description, default_mode,group_id)
 values (0, system_user_id, 'Incoming', 'Incoming Tickets', sysdate, 'ad', 'Catchall project for incoming tickets','full',ticket_admin_group_id);

insert into ticket_domains (domain_id, title, title_long, created_by, group_id, description)
  values (0, 'Incoming', 'Incoming', system_user_id, ticket_admin_group_id, 'Group to dispatch incoming tickets');

insert into ticket_domain_project_map (project_id, domain_id) values (0,0);


-- Site feedback stuff
insert into ticket_projects (project_id, created_by, title,
        title_long, start_date, code_set, description, default_mode,group_id)
 values (1, system_user_id, 'feedback', 'User feedback', sysdate,
         'ad', 'User feedback', 'feedback',ticket_admin_group_id);

insert into ticket_domains (domain_id, title, title_long, created_by, group_id, description)
  values (1, 'page', 'Page feedback',system_user_id, ticket_admin_group_id, 'Page feedback');

insert into ticket_domains (domain_id, title, title_long, created_by, group_id, description)
  values (2, 'site', 'Site feedback',system_user_id, ticket_admin_group_id, 'Site feedback');

insert into ticket_domain_project_map (project_id, domain_id) values (1,1);
insert into ticket_domain_project_map (project_id, domain_id) values (1,2);

--
-- Autogen code junk
--
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'Defct', 'Defect', 1, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Defct';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Defct';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'Enhnc', 'Enhancement Request', 2, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Enhnc';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Enhnc';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'Task', 'Task', 3, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Task';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Task';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'OEMDef', 'OEM Defect', 4, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'OEMDef';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'Dup', 'Duplicate', 5, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Dup';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'TestErr', 'Test Error', 6, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'TestErr';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'Unrepro', 'Unreproducible', 7, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'type'
 and code = 'Unrepro';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'type', 'Ticket', 'Ticket', 8, '');
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'UI', 'Under Investigation', 5, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'UI';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'open', 'open', 3, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'open';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'open';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'Assigned', 'Assigned', 4, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Assigned';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Assigned';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'need def', 'need clarification', 1, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'need def';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'need def';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'Fix/AA', 'fixed waiting approval', 2, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Fix/AA';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Fix/AA';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'Closed', 'closed', 7, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Closed';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Closed';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'status', 'Defer', 'deferred', 6, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Defer';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'status'
 and code = 'Defer';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'severity', 'SHOW', 'showstopper', 1, '');
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'severity', 'CRIT', 'critical', 2, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'CRIT';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'CRIT';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'severity', 'SER', 'serious', 3, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'SER';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'SER';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'severity', 'MED', 'medium', 4, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'MED';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'MED';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'severity', 'LOW', 'low', 5, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'LOW';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'severity'
 and code = 'LOW';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'severity', 'ENH', 'enhancement', 6, '');
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'Unk', 'Unknown', 1, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'Unk';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'Specs', 'Specification', 2, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'Specs';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'NoSpec', 'No Specification', 3, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'NoSpec';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'Design', 'Design', 4, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'Design';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'NoDesn', 'No Design', 5, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'NoDesn';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'Code', 'Code', 6, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'Code';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'OEM', 'OEM', 7, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'OEM';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'LrnPrd', 'Learning Products', 8, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'LrnPrd';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'cause', 'Other', 'Other', 9, '');
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'cause'
 and code = 'Other';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'priority', 'High', 'high', 1, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'priority'
 and code = 'High';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'priority'
 and code = 'High';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'priority', 'Med', 'medium', 2, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'priority'
 and code = 'Med';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'priority'
 and code = 'Med';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'priority', 'Low', 'low', 3, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'priority'
 and code = 'Low';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'priority'
 and code = 'Low';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'source', 'Int', 'internal', 1, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'source'
 and code = 'Int';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'source'
 and code = 'Int';
insert into ticket_codes_i (code_id,code_type,code,code_long,code_seq,code_help)
  values (ticket_code_id_sequence.nextval,'source', 'Ext', 'external', 2, '');
insert into ticket_code_sets select 'ad', code_id from ticket_codes_i
 where code_type = 'source'
 and code = 'Ext';
insert into ticket_code_sets select 'hp', code_id from ticket_codes_i
 where code_type = 'source'
 and code = 'Ext';

-- set up ticket status info
insert into ticket_status_info select code_id,'active','open','assignees' from ticket_codes_i
 where code_type = 'status'
 and code = 'UI';
insert into ticket_status_info select code_id,'active','open','admin' from ticket_codes_i
 where code_type = 'status'
 and code = 'open';
insert into ticket_status_info select code_id,'active','open','assignees' from ticket_codes_i
 where code_type = 'status'
 and code = 'Assigned';
insert into ticket_status_info select code_id,'active','clarify','user' from ticket_codes_i
 where code_type = 'status'
 and code = 'need def';
insert into ticket_status_info select code_id,'active','approve','user' from ticket_codes_i
 where code_type = 'status'
 and code = 'Fix/AA';
insert into ticket_status_info select code_id,'closed','closed','none' from ticket_codes_i
 where code_type = 'status'
 and code = 'Closed';
insert into ticket_status_info select code_id,'defer','defer','none' from ticket_codes_i
 where code_type = 'status'
 and code = 'Defer';
