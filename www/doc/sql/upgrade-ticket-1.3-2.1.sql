-- upgrades an ACS (v1.3) ticket tracker to the version in 
-- ACS 2.1

alter table ticket_issue_responses add (
	public_p		char(1) default('t') check(public_p in ('t','f'))
);


alter table ticket_issues add (
	group_id		references user_groups,
        modification_time       date,
	ticket_type		varchar(100),
	severity		varchar(100),
        source                  varchar(100), 
        last_modified_by        varchar(200), 
	last_notification	date,
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
	public_p		char(1) default('t') check(public_p in ('t','f'))
);


alter table ticket_projects add (
	default_assignee integer references users
);

insert into ticket_projects 
(project_id, customer_id, title, start_date)
values
(0, system_user_id, 'Incoming', sysdate);

-- end of alter table commands



begin
   administration_group_add ('Ticket Admin Staff', 'ticket', NULL, 'f', '/ticket/admin/');
end;
/



create or replace trigger ticket_modification_time
before insert or update on ticket_issues
for each row
when (new.modification_time is null)
begin
 :new.modification_time :=SYSDATE;
end;
/
show errors

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




-- cross reference table mapping issues to other issues
create table ticket_xrefs (
       from_ticket references ticket_issues(msg_id),
       to_ticket references ticket_issues(msg_id)
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

