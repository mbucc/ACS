-- In the true Arsdigita spirit,
-- the ticket tracker contains parts
-- of code by Eve, Jin, Ben, and Tracy!

-- but this latest release is maintained by Henry Minsky (hqm@arsdigita.com)
-- (from ACS 2.0, July 1999)

-- create an administration group for ticket tracker administration

begin
   administration_group_add ('Ticket Admin Staff', 'ticket', NULL, 'f', '/ticket/admin/');
end;
/


create sequence ticket_project_id_sequence start with 1;

create table ticket_projects (
	project_id	integer not null primary key,
	title		varchar(100),
	-- person who request the project and will be the owner
	customer_id	integer not null references users,
	start_date	date,
	end_date	date,
	-- person who gets defaultly assigned to new tickets in the project	
	default_assignee integer references users
	-- flags for email notification
	notify_on_create_p char(1) check (notify_on_create_p in ('t', 'f')),
	notify_on_assign_p char(1) check (notify_on_assign_p in ('t', 'f')),
	notify_on_add_comment_p char(1) check (notify_on_add_comment_p in ('t', 'f')),
	notify_on_change_status_p char(1) check (notify_on_change_status_p in ('t', 'f'))
);

create sequence ticket_project_admins_sequence;

create table ticket_project_admins (
	assignment_id	integer not null primary key,
	project_id	integer references ticket_projects,
	user_id	 	integer references users
);



-- we need at least one project in any system, "Incoming" for 
-- random incoming email

-- since this has a hard-wired project_id, constrained to be primary 
-- key, we're not in any danger of creating dupe projects

insert into ticket_projects 
(project_id, customer_id, title, start_date)
values
(0, system_user_id, 'Incoming', sysdate);

-- A table to assign people to projects

create sequence ticket_assignment_id_sequence;

create table ticket_assignments (
	assignment_id	integer not null primary key,
	project_id	integer references ticket_projects,
	user_id	 	integer references users,
	rate		integer, -- e.g. 125
	purpose		varchar(4000), -- e.g. "HTML, Java, etc..."
	-- we add this active flag in case someone gets taken off the
	-- project.
	active_p	char(1) check (active_p in ('t','f'))
);


-------------- From The Community System ---------------
-- table state, country_codes, users
--------------------------------------------------------

create table ticket_priorities (
        priority                integer not null primary key,
        name                    varchar(20)
);

insert into ticket_priorities values (3, 'low');
insert into ticket_priorities values (2, 'medium');
insert into ticket_priorities values (1, 'high');

create sequence ticket_issue_id_sequence;

create table ticket_issues (
        msg_id                  integer not null primary key,
        project_id              integer not null references ticket_projects,
        user_id                 references users,
	group_id		references user_groups,
        posting_time            date not null,
        modification_time       date,
	ticket_type		varchar(100), -- {ticket, service_ticket, bug, feature_request}
        one_line                varchar(700),
        message                 clob default empty_clob(),
        indexed_stuff           clob default empty_clob(), -- for context index
        close_date              date,
        closed_by               integer references users,
        -- When it is important for it to be finished.
        deadline                date,
	-- Status: open, waiting assignment, development, fixed waiting approval, closed 
	status			varchar(100),
        priority                integer not null references ticket_priorities,
	severity		varchar(100),
	-- who was responsible for creating this message
        source                  varchar(100), 
	-- user name who last modified 
        last_modified_by        varchar(200), 
	-- When was the last "nag" notification sent 
	last_notification	date,
	-- Ticket author's contact info
	contact_name		varchar(200),
	contact_email		varchar(200),
	contact_info1		varchar(700),
	contact_info2		varchar(700),
	-- product-specific fields
	data1			varchar(700),
	data2			varchar(700),
	data3			varchar(700),
	data4			varchar(700),
	data5			varchar(700),
	-- is this ticket visible to customers
	public_p		char(1) default('t') check(public_p in ('t','f')),
	-- if notify_p is 't', member of that project will receive notification email
	notify_p		char(1) default('t') check(notify_p in ('t','f'))
);


create or replace trigger ticket_modification_time
before insert or update on ticket_issues
for each row
when (new.modification_time is null)
begin
 :new.modification_time :=SYSDATE;
end;
/
show errors

-- the ticket_changes table can reference ticket_issues
-- but only in Oracle 8.1.5 or newer; Oracle 8.0.5 gets 
-- bent out of shape with a mutating trigger from
-- ticket_activity_logger

--- keep track of changes to a ticket
create table ticket_changes (
  msg_id    integer not null, -- references ticket_issues
  who 	    varchar(256),
  what      varchar(256),
  old_value varchar(256),
  new_value varchar(256),
  modification_date  date
);

create index ticket_changes_by_msg_id on ticket_changes(msg_id);

-- track changes to tickets
create or replace trigger ticket_activity_logger
after update on ticket_issues
for each row
begin
  if (:old.project_id <> :new.project_id) then
   insert into ticket_changes (msg_id, who, what, old_value, new_value, modification_date)
   values
   (:new.msg_id, :new.last_modified_by, 'Project ID', :old.project_id, :new.project_id, sysdate);
  end if;

  if (:old.ticket_type <> :new.ticket_type) then
   insert into ticket_changes (msg_id, who, what, old_value, new_value, modification_date)
   values
   (:new.msg_id, :new.last_modified_by, 'Ticket Type', :old.ticket_type, :new.ticket_type, sysdate);
  end if;

  if (:old.one_line <> :new.one_line) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Synopsis', :old.one_line, :new.one_line, sysdate);
  end if;

  if (:old.deadline <> :new.deadline) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Deadline', :old.deadline, :new.deadline, sysdate);
  end if;

  if (:old.status <> :new.status) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Status', :old.status, :new.status, sysdate);
  end if;

  if (:old.priority <> :new.priority) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Priority', :old.priority, :new.priority, sysdate);
  end if;

  if (:old.severity <> :new.severity) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Severity', :old.severity, :new.severity, sysdate);
  end if;

-- These are custom fields -- the column title will need  to
--  be kept up to date 
-- manually 


  if (:old.data1 <> :new.data1) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Hardware_model', :old.data1, :new.data1, sysdate);
  end if;

  if (:old.data2 <> :new.data2) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Software_version', :old.data2, :new.data2, sysdate);
  end if;

  if (:old.data3 <> :new.data3) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Software_version', :old.data2, :new.data2, sysdate);
  end if;

  if (:old.data4 <> :new.data4) then
   insert into ticket_changes (msg_id, who,what, old_value, new_value, modification_date) 
   values
   (:new.msg_id, :new.last_modified_by, 'Build', :old.data4, :new.data4, sysdate);
  end if;
end;
/
show errors





--- a table to assign users to  issues
--- the selection list for this will be the
--- ticket_assignments table constratained by the appropriate project


create table ticket_issue_assignments (
	msg_id		integer not NULL references ticket_issues,
	user_id		integer not null references users,
	purpose		varchar(4000), -- e.g. "HTML, Java, etc..."
	-- we add this active flag in case someone gets taken off the
	-- issue.
	active_p	char(1) check (active_p in ('t','f')),
	unique (msg_id, user_id)
);

-- cross reference table mapping issues to other issues
create table ticket_xrefs (
       from_ticket references ticket_issues(msg_id),
       to_ticket references ticket_issues(msg_id)
);


create sequence ticket_response_id_sequence;

create table ticket_issue_responses (
        response_id             integer not null primary key,
        response_to             integer not null references ticket_issues,
        user_id                 references users,
        posting_time            date not null,
	public_p		char(1) default('t') check(public_p in ('t','f')),
        message                 clob default empty_clob()
);


-- update the ticket's modification timestamp
create or replace trigger response_modification_time
before insert or update on ticket_issue_responses
for each row
begin
  update ticket_issues set modification_time = SYSDATE 
  where msg_id = :new.response_to;
end;
/
show errors


create table ticket_issue_notifications (
        msg_id                  integer not null references ticket_issues,
        user_id                 integer not null references users,
        primary key (msg_id, user_id)
);


-- called by /tcl/email-queue.tcl 
-- and /ticket/issue-response-2.tcl 
create or replace procedure ticket_update_for_response(v_response_id IN integer)
AS
 v_response_row ticket_issue_responses%ROWTYPE;
 v_indexed_stuff clob;
BEGIN
 select ticket_issue_responses.* into v_response_row
   from ticket_issue_responses
   where response_id = v_response_id;

 if v_response_row.message is not null then 
   select indexed_stuff into v_indexed_stuff
     from ticket_issues
     where msg_id = v_response_row.response_to
     for update;
   dbms_lob.append(v_indexed_stuff, v_response_row.message);
 end if;
END;
/
show errors


create or replace function ticket_one_if_high_priority (priority IN integer, status IN varchar)
return integer
is
BEGIN
  IF ((priority = 1) AND (status <> 'closed') AND (status <> 'deferred')) THEN
    return 1;
  ELSE 
    return 0;   
  END IF;
END ticket_one_if_high_priority;
/
show errors

create or replace function ticket_one_if_blocker (severity IN varchar, status IN varchar)
return integer
is
BEGIN
  IF ((severity = 'showstopper') AND (status <> 'closed') AND (status <> 'deferred')) THEN
    return 1;
  ELSE 
    return 0;   
  END IF;
END ticket_one_if_blocker;
/
show errors

