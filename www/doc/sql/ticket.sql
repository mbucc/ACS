-- Ticket tracker v3.0
--
-- Data model
--


--This table holds all the states, severities, etc
create sequence ticket_code_id_sequence;

-- 
-- The master table of ticket codes                
--
create table ticket_codes_i (
        code_id         integer not null primary key,
        -- ascii key for the code set constrain since code depends on it
        code_type       varchar2(20) constraint c_tkt_code_type check (code_type in ('severity','priority','status','type','cause','source')),
        -- the short name: Displayed in tables usually
        code            varchar2(100) not null,
        -- the long name: Displayed in reports and selects
        code_long       varchar2(400) not null,
        -- sort key for ordering non alphabetically
        code_seq        integer not null, 
        -- html fragment defining code...
        code_help       varchar2(4000),
        unique (code_type, code)
);



-- Code set collections
--    a code set is the collection of codes that a Project or set of
--    projects use on their tickets (so for example aD can have a
--    small set suited to small groups and HP can have a large set
--    which reflects their formalized ticket resolution process.
--
create table ticket_code_sets ( 
        code_set        varchar2(20) not null,
        code_id         integer not null references ticket_codes_i on delete cascade,
        primary key (code_set, code_id)
);


-- Specifically for dealing with "status" field
-- equivalence ticket status as active defered closed

create table ticket_status_info (
        code_id         integer references ticket_codes_i primary key,
        -- this is active closed defered.
        status_class    varchar(30),
        -- tickets requiring action have this set (eg clarify and approve)
        status_subclass varchar(30),
        -- who is responsible for a ticket in this state
        -- code supports user admin assignees and none (for terminal states)
        responsibility  varchar(30)
);


-- a view of convenience, remove maybe?

create or replace view ticket_codes 
as
  select tcs.code_set,
        tci.code_id,
        tci.code_type,
        tci.code,
        tci.code_long,
        tci.code_seq,
        tci.code_help
  from ticket_codes_i tci, ticket_code_sets tcs
  where tcs.code_id = tci.code_id;




-- The difference between a project and a domain in these tables 
-- is that a project is something like minipress or acs 
-- and domain is a feature area like layout, content, admin.
-- the ticket_project_domain_map is a many-to-many relationship.


-- This will fail on an upgrade since we do not drop it 
-- so we can preserve ticket IDs
create sequence ticket_project_id_sequence start with 100;

create table ticket_projects (
	project_id	integer not null primary key,
	title		varchar2(30) not null,
	title_long	varchar2(100) not null,
	version		varchar2(100),
	-- person who request the project and will be the owner
        created_by	integer not null references users,
	start_date	date not null,
	end_date	date,
        -- group responsible for this project
	group_id	references user_groups,
	public_p	char(1) default('f') check (public_p in ('t','f')),
	description	varchar2(700),
        -- the set of codes used for this project
	code_set        varchar2(80) not null,
        -- the ticket entry mode
        default_mode    varchar2(80) not null,
        message_template varchar2(4000)        
);


-- SHould have named this ticket_project_milestones, nobody likes deadlines
create table ticket_deadlines ( 
        project_id integer not null references ticket_projects,
        name       varchar2(100) not null,
        deadline   date not null,
        primary key (project_id, name)
);
     
        
create sequence ticket_domain_id_sequence start with 100;

create table ticket_domains (
        domain_id	integer not null primary key,
	title		varchar2(30) not null,
	title_long	varchar2(100) not null,
	-- person who request the project and will be the owner
        created_by	integer not null references users,
	-- person who gets defaultly assigned to new tickets in the project	
        default_assignee integer references users,
        -- group responsible for this domain
	group_id	references user_groups,
        -- Should this domain be visible to non project members
        public_p	char(1) default('f') check (public_p in ('t','f')),
	description	varchar2(700),
        -- The default notifications for this domain
        notify_admin_p		char(1) default('f') check(notify_admin_p in ('t','f')),
        notify_comment_p	char(1) default('t') check(notify_comment_p in ('t','f')),
        notify_status_p 	char(1) default('t') check(notify_status_p in ('t','f')),
        -- date after which this domain is inactive.
        end_date                date,
        -- the new message template for the given domain
        -- takes precedence over the template for the project 
        -- in the event both exist
        message_template        varchar2(4000)
);



-- This is the table which maps strings to projects and domains. The mapping_key
-- can be a module_key (references acs_modules table) so that we can log
-- tickets for a particular module.

create table ticket_domain_project_map (
        project_id      integer not null references ticket_projects,
        domain_id       integer not null references ticket_domains,
        -- takes precedence over ticket_domains 
        default_assignee integer references users,
        -- The group from which assignments are made.
        -- typically the same as owning group on feature area
        assignment_group_id references user_groups,
	mapping_key	varchar(200) unique,
        primary key (project_id, domain_id)
);





create or replace function ticket_admin_group_id
return integer
as 
  v_group_id     integer;
begin 
 select group_id into v_group_id
   from administration_info
   where module = 'ticket'
         and submodule is null;
  return v_group_id;
end;
/



-- A table to assign people to feature areas -- NOT USED 
-- use groups instead, rate, purpose, et al should be from 
-- intranet.

create sequence ticket_assignment_id_seq;

create table ticket_assignments (
        assignment_id	integer not null primary key,
        domain_id	integer references ticket_domains,
        user_id	 	integer references users,
        rate		integer, -- e.g. 125
        purpose		varchar2(400), -- e.g. "HTML, Java, etc..."
        -- we add this active flag in case someone gets taken off the
        -- project.
        active_p	char(1) default('t') check (active_p in ('t','f'))
);


create sequence ticket_issue_id_sequence start with 1000;

create table ticket_issues_i (
        msg_id                  integer not null primary key,
        project_id              integer not null references ticket_projects,
        -- so we can track bug identified in version x.
        version                 varchar2(100),
        domain_id               integer not null references ticket_domains,
        -- the submitting user
        user_id                 integer references users,
        -- will only work acs 3.0 where we have a keyed address_book
        -- address_book_id         integer references address_book,
        -- bug report
        one_line                varchar2(200),
        comment_id              integer references general_comments,
        --
        -- stuff for remotely submitted tickets
        from_host               varchar2(200),
        from_url                varchar2(700),
        from_query              varchar2(4000),
        from_project            varchar2(80),
        -- the browser string of the user submitting the ticket
        from_user_agent         varchar2(300),
        from_ip                 varchar2(50),
        --
        -- Various state variables
	ticket_type_id          integer references ticket_codes_i(code_id),
        priority_id             integer references ticket_codes_i(code_id),
        status_id               integer references ticket_codes_i(code_id),
	severity_id		integer references ticket_codes_i(code_id),
        source_id               integer references ticket_codes_i(code_id),
        cause_id                integer references ticket_codes_i(code_id),
        --
        posting_time            date not null,
        last_status_change      date, 
        closed_date             date,
        closed_by               integer references users,
        deadline                date,
        -- When was the last "nag" notification sent 
	last_notification	date,
	-- is this ticket visible to non project group members?
	public_p		char(1) default('t') check(public_p in ('t','f')),
	-- if notify_p is 't', member of that project will receive
        -- notification email.  NB: NO LONGER USED
        notify_p		char(1) default('t') check(notify_p in ('t','f')),
        --
        -- The auditing information
        -- the user ID and IP address of the last modifier of the product
        last_modified           date not null,
        last_modifying_user     not null references users(user_id),
        modified_ip_address     varchar2(20) not null
);


--
-- The audit table
--
create table ticket_issues_i_audit as select * from ticket_issues_i where 1 = 0;
alter table ticket_issues_i_audit add (
        delete_p    char(1) default('f') check (delete_p in ('t','f'))
);

--
-- create this outside ticket_issues_i since
-- the we can say ticket_issues_i.* in queries and not
-- have terabytes of dup information coming back to the server
-- I know I could just change the view but the we would have to list
-- all the columns on the view which I hate
--
-- After creating it I promptly discarded it since I think it 
-- is better to hit general_comments directly.
--
-- Still here since it might be useful later (and is populated on
-- insert but not on comment add 
--

create table ticket_index (
        msg_id          integer not null primary key references ticket_issues_i,
        indexed_stuff   clob default empty_clob(),
        last_modified   date not null 
);


create sequence ticket_alert_id_sequence; 

create table ticket_email_alerts ( 
        alert_id        integer not null primary key,
        user_id         not null references users,
        msg_id          references ticket_issues_i,
        domain_id       references ticket_domains,
        project_id      references ticket_projects,
        established     date,
	active_p	char(1) default 't' check (active_p in ('t','f'))
);                          


--
-- The two views to hide the code table lookups
-- and get us our fancy versions of the output data
--
create or replace view ticket_issues
as 
  select 
   ti.*,         -- FIX THIS IN PROD no select star
   to_char(ti.last_modified, 'mm/dd/yy') as modification_mdy,
   to_char(ti.posting_time, 'mm/dd/yy') as creation_mdy,
   to_char(ti.closed_date, 'mm/dd/yy') as close_mdy,
   to_char(ti.deadline, 'mm/dd/yy') as deadline_mdy,
   to_char(trunc(sysdate - deadline)) as pastdue_days,
    sev.code as severity, sev.code_seq as severity_seq, sev.code_long as severity_long,
    pri.code as priority, pri.code_seq as priority_seq, pri.code_long as priority_long, 
    stat.code as status, stat.code_seq as status_seq, stat.code_long as status_long,
    src.code as source, src.code_seq as source_seq, src.code_long as source_long,
    def.code as cause, def.code_seq as cause_seq, def.code_long as cause_long,
    type.code as ticket_type, type.code_seq as ticket_type_seq, type.code_long as ticket_type_long,
    tsi.status_class, tsi.status_subclass, tsi.responsibility
  from 
    ticket_issues_i ti, 
    ticket_codes_i sev, 
    ticket_codes_i pri, 
    ticket_codes_i stat, 
    ticket_codes_i src, 
    ticket_codes_i def,
    ticket_codes_i type,
    ticket_status_info tsi
  where 
        sev.code_id(+) = ti.severity_id
    and pri.code_id(+) = ti.priority_id
    and stat.code_id(+) = ti.status_id
    and src.code_id(+) = ti.source_id
    and def.code_id(+) = ti.cause_id
    and type.code_id(+) = ti.ticket_type_id
    and tsi.code_id(+) = ti.status_id;
        

create or replace view ticket_issues_audit
as 
  select 
   ti.*,         -- FIX THIS IN PROD no select star
   to_char(ti.last_modified, 'mm/dd/yy') as modification_mdy,
   to_char(ti.posting_time, 'mm/dd/yy') as creation_mdy,
   to_char(ti.closed_date, 'mm/dd/yy') as close_mdy,
   to_char(ti.deadline, 'mm/dd/yy') as deadline_mdy,
   to_char(trunc(sysdate - deadline)) as pastdue_days,
    sev.code as severity, sev.code_seq as severity_seq, sev.code_long as severity_long,
    pri.code as priority, pri.code_seq as priority_seq, pri.code_long as priority_long, 
    stat.code as status, stat.code_seq as status_seq, stat.code_long as status_long,
    src.code as source, src.code_seq as source_seq, src.code_long as source_long,
    def.code as cause, def.code_seq as cause_seq, def.code_long as cause_long,
    type.code as ticket_type, type.code_seq as ticket_type_seq, type.code_long as ticket_type_long,
    tsi.status_class, tsi.status_subclass, tsi.responsibility
  from 
    ticket_issues_i_audit ti, 
    ticket_codes_i sev, 
    ticket_codes_i pri, 
    ticket_codes_i stat, 
    ticket_codes_i src, 
    ticket_codes_i def,
    ticket_codes_i type,
    ticket_status_info tsi
  where 
        sev.code_id(+) = ti.severity_id
    and pri.code_id(+) = ti.priority_id
    and stat.code_id(+) = ti.status_id
    and src.code_id(+) = ti.source_id
    and def.code_id(+) = ti.cause_id
    and type.code_id(+) = ti.ticket_type_id
    and tsi.code_id(+) = ti.status_id;




create or replace trigger ticket_modification_time
before insert or update on ticket_issues_i
for each row
when (new.last_modified is null)
begin
 :new.last_modified := SYSDATE;
end;
/


--- a table to assign users to  issues
--- the selection list for this will be the
--- ticket_assignments table constrained by the appropriate project

create table ticket_issue_assignments (
	msg_id		integer not NULL references ticket_issues_i,
	user_id		integer not null references users,
        -- why assigned e.g. "code review, spec compliance, etc."
	purpose		varchar2(4000), 
	-- we add this active flag in case someone gets taken off the
	-- issue.  Not really used now.  
	active_p	char(1) default 't' check (active_p in ('t','f')),
        primary key (msg_id, user_id)
);

-- cross reference table mapping issues to other issues
create table ticket_xrefs (
       from_ticket references ticket_issues_i(msg_id),
       to_ticket references ticket_issues_i(msg_id)
);



-- Nuke this and use general comments instead
-- 
-- create sequence ticket_response_id_sequence;
-- 
-- create table ticket_issue_responses (
--         response_id             integer not null primary key,
--         response_to             integer not null references ticket_issues_i,
--         user_id                 references users,
--         posting_time            date not null,
-- 	public_p		char(1) default('t') check(public_p in ('t','f')),
--         message                 clob default empty_clob(),
--         html_p                  char(1) default('f') check(html_p in ('t','f'))
-- );
-- 


-- update the tickets comment timestamp

create or replace trigger ticket_response_mod_time
after insert or update on general_comments
for each row
begin
  update ticket_index set last_modified = SYSDATE 
  where msg_id = :new.on_what_id and :new.on_which_table = 'ticket_issues';
end;
/
show errors

-- NOT USED YET...current notify scheme embeded in code.

create table ticket_issue_notifications (
        msg_id                  integer not null references ticket_issues_i,
        user_id                 integer not null references users,
        role                    varchar2(60) default 'assignee',
        notify_on               varchar2(200) default 'all',                  
        primary key (msg_id, user_id)
);



-- -- Cant triggerize this?
-- -- I tried but got:  
-- --   ORA-04091: table PS.GENERAL_COMMENTS is mutating, trigger/function may not see it
-- --
-- -- in any case I just discarded this since it turned out to be as easy 
-- -- to search directly in the general_comments table.
-- 
-- create or replace procedure ticket_build_index(v_response_id IN integer)
-- AS
--  v_response_row general_comments%ROWTYPE;
--  v_indexed_stuff clob;
-- BEGIN
--  select general_comments.* into v_response_row
--    from general_comments
--    where comment_id = v_response_id;
-- 
--  if v_response_row.content is not null then 
--    select indexed_stuff into v_indexed_stuff
--      from ticket_index
--      where msg_id = v_response_row.on_what_id
--      for update;
--    dbms_lob.append(v_indexed_stuff, v_response_row.content);
--  end if;
-- END;
-- /
-- show errors


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


create or replace trigger TICKET_ISSUES_I_audit_tr
before update or delete on TICKET_ISSUES_I
for each row
begin
 insert into TICKET_ISSUES_I_audit (
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
  FROM_USER_AGENT,
  FROM_IP,
  TICKET_TYPE_ID,
  PRIORITY_ID,
  STATUS_ID,
  SEVERITY_ID,
  SOURCE_ID,
  CAUSE_ID,
  POSTING_TIME,
  LAST_STATUS_CHANGE,
  CLOSED_DATE,
  CLOSED_BY,
  DEADLINE,
  LAST_NOTIFICATION,
  PUBLIC_P,
  NOTIFY_P,
  LAST_MODIFIED,
  LAST_MODIFYING_USER,
  MODIFIED_IP_ADDRESS
 ) values (
  :old.MSG_ID,
  :old.PROJECT_ID,
  :old.VERSION,
  :old.DOMAIN_ID,
  :old.USER_ID,
  :old.ONE_LINE,
  :old.COMMENT_ID,
  :old.FROM_HOST,
  :old.FROM_URL,
  :old.FROM_QUERY,
  :old.FROM_PROJECT,
  :old.FROM_USER_AGENT,
  :old.FROM_IP,
  :old.TICKET_TYPE_ID,
  :old.PRIORITY_ID,
  :old.STATUS_ID,
  :old.SEVERITY_ID,
  :old.SOURCE_ID,
  :old.CAUSE_ID,
  :old.POSTING_TIME,
  :old.LAST_STATUS_CHANGE,
  :old.CLOSED_DATE,
  :old.CLOSED_BY,
  :old.DEADLINE,
  :old.LAST_NOTIFICATION,
  :old.PUBLIC_P,
  :old.NOTIFY_P,
  :old.LAST_MODIFIED,
  :old.LAST_MODIFYING_USER,
  :old.MODIFIED_IP_ADDRESS);
end;
/
show errors
-- thats all

-- 
-- This is to get human decipherable audit trails.
--
create or replace view ticket_pretty 
as 
select 
 t.msg_id,
 u.email as submitted_by, 
 tp.title_long as project, 
 td.title_long as feature_area, 
 t.version, 
 t.one_line as subject, 
 t.from_url as from_url, 
 t.severity_long as severity, 
 t.priority_long as priority, 
 t.status_long as status, 
 t.cause_long as cause, 
 t.LAST_MODIFIED, 
 t.LAST_MODIFYING_USER, 
 t.MODIFIED_IP_ADDRESS
from ticket_issues t, users u, ticket_domains td, ticket_projects tp
where t.user_id = u.user_id
  and td.domain_id = t.domain_id  
  and tp.project_id = t.project_id;

create or replace view ticket_pretty_audit
as 
select 
 t.msg_id,
 u.email as submitted_by, 
 tp.title_long as project, 
 td.title_long as feature_area, 
 t.version, 
 t.one_line as subject, 
 t.from_url as from_url, 
 t.severity_long as severity, 
 t.priority_long as priority, 
 t.status_long as status, 
 t.cause_long as cause, 
 t.LAST_MODIFIED, 
 t.LAST_MODIFYING_USER, 
 t.MODIFIED_IP_ADDRESS,
 t.delete_p
from ticket_issues_audit t, users u, ticket_domains td, ticket_projects tp
where t.user_id = u.user_id
  and td.domain_id = t.domain_id  
  and tp.project_id = t.project_id;



-- view public tickets or tickets for which user is in project or
-- domain group.
create or replace view ticket_viewable as 
select u.user_id, ti.msg_id
from ticket_issues_i ti, ticket_domains td, ticket_projects tp, users u 
where tp.project_id = ti.project_id 
 and td.domain_id = ti.domain_id
 and ((tp.public_p = 't' and ti.public_p = 't' and td.public_p = 't')
   or exists (select 1 
              from user_group_map 
              where (group_id = tp.group_id or group_id = ticket_admin_group_id)
                and user_id = u.user_id)
   or exists (select 1 
              from user_group_map 
              where group_id = td.group_id
                and user_id = u.user_id));


-- edit for which user is in project or domain group.
create or replace view ticket_editable as 
select u.user_id, ti.msg_id
from ticket_issues_i ti, ticket_domains td, ticket_projects tp, users u 
where tp.project_id = ti.project_id 
 and td.domain_id = ti.domain_id
 and (exists (select 1 
              from user_group_map 
              where (group_id = tp.group_id or group_id = ticket_admin_group_id)
                and user_id = u.user_id)
   or exists (select 1 
              from user_group_map 
              where group_id = td.group_id 
                and user_id = u.user_id));

