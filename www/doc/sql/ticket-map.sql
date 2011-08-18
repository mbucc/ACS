-- Ticket v3.x

-- Take prexisting tickets and insert into new schema
-- Assumes ticket-save.sql has run and was successful

-- DANGER -- SOME CONFIG REQUIRED BELOW... (search for **magic**)

-- Script assumes the saved versions of all the tables have been set up 
-- and ticket codes has been created.  Furthermore, mappings from
-- ticket_project_domain_map must be 1-1 (or insert below will fail).

-- Generate a project for the server

-- **magic** the project we are going to put all preexisting tickets into
insert into ticket_projects (project_id, created_by, title, title_long,
     start_date, code_set, description, group_id, default_mode)
   select ticket_project_id_sequence.nextval, system_user_id, 'Site', 'Site',
     sysdate, 'ad', 'All old site tickets', ticket_admin_group_id,'full' from dual;


-- **magic** anal retentive fixing of users in ticket changes table 
-- 
-- update ticket_changes_s set who = 'gfouts@lintodd.com' where who = 'gfouts@solnlogic.com';

-- Create domains for all the old projects
insert into ticket_domains (domain_id, title, title_long, created_by,
 default_assignee, group_id, public_p, end_date) 
        select ticket_domain_id_sequence.nextval, substr(title,1,30), title,
          customer_id, default_assignee, ticket_admin_group_id, 't' , null
        from ticket_projects_s where title != 'Incoming';

-- Map all old projects into the the main project

-- **magic** 
insert into ticket_domain_project_map (project_id, domain_id, default_assignee)
   select tp.project_id, td.domain_id, tp_s.default_assignee 
   from ticket_projects tp, ticket_domains td, ticket_projects_s tp_s
   where tp.title = 'Site' and tp_s.title = td.title_long
     and not exists 
       (select 1 from ticket_domain_project_map tm where tm.domain_id = td.domain_id);


--
-- Now actually move the tickets over...
--
drop trigger general_comments_modified;

-- Step 1 move initial message to general comments
insert into general_comments(comment_id, on_what_id, on_which_table,
        user_id, comment_date, IP_address, modified_date, content,
        html_p, approved_p,scope,one_line_item_desc) 
  select comment_id_sequence.nextval, 
        msg_id, 'ticket_issues_i',user_id, posting_time,
        '127.0.0.1',posting_time,message, 't','t','public','ticket description'
  from ticket_issues_s ;

-- now the responses...
insert into general_comments(comment_id, on_what_id, on_which_table,
        user_id, comment_date, IP_address, modified_date, content,
        html_p, approved_p, scope, one_line_item_desc)
  select comment_id_sequence.nextval, 
        response_to, 'ticket_issues', user_id, posting_time,
        '127.0.0.1',posting_time,message, 't','t','public','ticket comment'
  from ticket_issue_responses_s ;

-- replace the trigger
create trigger general_comments_modified
before insert or update on general_comments
for each row
begin
 :new.modified_date :=SYSDATE;
end;
/
show errors


-- now the tickets themselves
-- we have to look up all the comment_id and ticket_codes
-- probably would have been better to do this one in steps...

insert into ticket_issues_i(
 MSG_ID,
 PROJECT_ID,
 VERSION,
 DOMAIN_ID,
 USER_ID,
 ONE_LINE,
 COMMENT_ID,
 FROM_HOST,
 FROM_URL,
 FROM_QUERY,
 FROM_PROJECT,
 TICKET_TYPE_ID,
 PRIORITY_ID,
 STATUS_ID,
 SEVERITY_ID,
 SOURCE_ID,
 CAUSE_ID,
 POSTING_TIME,
 CLOSED_DATE,
 CLOSED_BY,
 DEADLINE,
 LAST_NOTIFICATION,
 PUBLIC_P,
 NOTIFY_P,
 LAST_MODIFIED,
 LAST_MODIFYING_USER,
 MODIFIED_IP_ADDRESS)
select 
 ts.MSG_ID,
 tgpm.PROJECT_ID,
 tp.VERSION,
 td.DOMAIN_ID,
 ts.USER_ID,
 ts.ONE_LINE,
 gc.COMMENT_ID,
 null, -- FROM_HOST
 null, -- FROM_URL
 null, -- FROM_QUERY
 null, -- FROM_PROJECT
 type.code_id, -- TICKET_TYPE_ID
 pri.code_id, -- PRIORITY_ID
 stat.code_id, -- STATUS_ID
 sev.code_id, -- SEVERITY_ID
 src.code_id, -- SOURCE_ID
 null, -- CAUSE_ID
 ts.POSTING_TIME,
 ts.CLOSE_DATE,
 ts.CLOSED_BY,
 ts.DEADLINE,
 ts.LAST_NOTIFICATION,
 ts.PUBLIC_P,
 ts.NOTIFY_P,
 ts.MODIFICATION_TIME, -- LAST_MODIFIED
 ts.USER_ID, -- LAST_MODIFYING_USER
 '127.0.0.1' -- MODIFIED_IP_ADDRESS
from ticket_issues_s ts, ticket_domains td, 
 general_comments gc, ticket_projects_s tps,
 ticket_domain_project_map tgpm,
 ticket_projects tp,
 ticket_codes_i type,
 ticket_codes_i pri,
 ticket_codes_i stat,
 ticket_codes_i sev,
 ticket_codes_i src,
 ticket_priorities_s pris
where ts.project_id = tps.project_id 
  and td.title_long(+) = tps.title
  and tgpm.domain_id = td.domain_id
  and tp.project_id = tgpm.project_id
  and gc.on_what_id = ts.msg_id and gc.on_which_table = 'ticket_issues_i'
  and type.code_long(+) = ts.ticket_type and type.code_type = 'type'
  and stat.code_long(+) = ts.status and stat.code_type = 'status'
  and sev.code_long(+) = ts.severity and sev.code_type = 'severity'
  and src.code_long(+) = ts.source and src.code_type = 'source'
  and pris.priority = ts.priority
  and pri.code_long(+) = pris.name 
  and pri.code_type = 'priority';

--
-- Now snarf the xref stuff.  Do an integrity check since
--  there are some dangling xrefs out there 
--
insert into ticket_xrefs tx select * from ticket_xrefs_s tx
  where exists  (select 1 from ticket_issues_i ti where ti.msg_id = tx.from_ticket) 
        and exists  (select 1 from ticket_issues_i ti where ti.msg_id = tx.to_ticket);


--
-- Now the actual assignments 
-- 
insert into ticket_issue_assignments select * from ticket_issue_assignments_s tx
   where exists  (select 1 from ticket_issues_i  ti where ti.msg_id = tx.msg_id);


drop trigger ticket_response_mod_time right

-- jump though some hoops to get the modified time...

create table xxx as select msg_id, max(modification_date) x from ticket_changes_s group by msg_id;

create table yyy as select xxx.msg_id, x , min(user_id) as user_id
from xxx, ticket_changes_s s, users u where modification_date = x and
u.email =  s.who group by xxx.msg_id, x;

update ticket_issues_i set last_modified = (select x from yyy where yyy.msg_id = ticket_issues_i.msg_id);

update ticket_issues_i set last_modifying_user = nvl(
  (select user_id from yyy where yyy.msg_id = ticket_issues_i.msg_id and user_id is not null),
  (select user_id from ticket_issues_i t where t.msg_id = ticket_issues_i.msg_id));

update ticket_issues_i set last_modifying_user = closed_by,
         last_modified = closed_date 
where closed_date > last_modified; 

drop table xxx;
drop table yyy;

-- FOR HP ONLY 
-- -- fix status UnAssn for assigned tickets.
-- 
-- update ticket_issues_i set status_id = (
--    select code_id 
--    from ticket_codes_i tc
--    where code = 'Assigned' and code_type = 'status')
-- where msg_id in ( 
--    select msg_id
--    from ticket_issues_i ti,
--         ticket_codes_i tc2
--    where tc2.code_id = ti.status_id 
--       and tc2.code = 'UnAssn' 
--       and tc2.code_type = 'status'
--       and exists ( select 1 
--                    from ticket_issue_assignments tia
--                    where tia.msg_id = ti.msg_id));
--         
-- 


-- put the trigger back

create or replace trigger ticket_response_mod_time
after insert or update on general_comments
for each row
begin
  update ticket_index set last_modified = SYSDATE 
  where msg_id = :new.on_what_id and :new.on_which_table = 'ticket_issues';
end;
/
show errors

