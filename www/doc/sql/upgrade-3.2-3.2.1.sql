--
-- /www/doc/sql/upgrade-3.2-3.2.1.sql
--
-- Script to upgrade an ACS 3.2 database to ACS 3.2.1.
-- 
-- upgrade-3.2-3.2.1.sql,v 3.8 2000/04/07 11:21:38 mbryzek Exp
--

-- BEGIN WIMPYPOINT --
-- jsalz: 03 Apr 2000

alter table wp_presentations modify(page_signature varchar2(4000));

--alter table wp_presentations drop group_id;
--alter table wp_presentations drop public_p;
-- END WIMPYPOINT --


-- BEGIN SURVSIMP --
-- mbryzek: 3/27/2000

create or replace view survsimp_responses_unique as 
select r1.* from survsimp_responses r1
where r1.response_id=(select max(r2.response_id) 
                        from survsimp_responses r2
                       where r1.survey_id=r2.survey_id
                         and r1.user_id=r2.user_id);


create or replace view survsimp_question_responses_un as 
select qr.* 
  from survsimp_question_responses qr, survsimp_responses_unique r
 where qr.response_id=r.response_id;

-- END SURVSIMP --


-- BEGIN INTRANET --
-- mbryzek: 3/27/2000

DECLARE
  v_max integer;
  v_i	integer;

  v_blocks_exist_p integer;
BEGIN
  
  select decode(count(1),0,0,1) into v_blocks_exist_p from im_start_blocks;

  if v_blocks_exist_p = 0 then 
    v_max := 3000;

    FOR v_i IN 0..v_max-1 LOOP
      insert into im_start_blocks
      (start_block) 
      values
      (to_date('1996-01-07','YYYY-MM-DD') + v_i*7);
    END LOOP;
  end if;

END;
/
show errors;


alter table im_offices add 
    public_p		char(1) default 'f'
                        constraint im_offices_public_p_ck check(public_p in ('t','f'));

-- we can safely drop this column because there was no way to add
-- primary contacts

alter table im_partners drop column primary_contact_id;
alter table im_partners add primary_contact_id references address_book;

create sequence im_office_links_seq start with 1;
create table im_office_links (
	link_id			integer
 				constraint iol_group_id_pk primary key,
	-- which office
	group_id		integer 
 				constraint iol_group_id_nn not null 
 				constraint iol_group_id_fk references im_offices,
	-- which user posted this link
	user_id			integer 
 				constraint iol_users_id_nn not null 
 				constraint iol_users_id_fk references users,
	url			varchar(300) 
 				constraint iol_url_nn not null,
	link_title		varchar(100) 
 				constraint iol_link_title_nn not null,
	active_p		char(1) default('t') 
 				constraint iol_active_p_ck check (active_p in ('t','f'))
);

-- END INTRANET --

-- BEGIN ISCHECKER --
-- abe: 3/30/2000

-- ischecker.sql
-- Delphi Enterprise IS Checker
-- by James Buszard-Welcher <james@arsdigita.com>, November 1999
-- mostly synchonized with actual database April 25, 2000 by Dave Abercrombie <abe@arsdigita.com>
-- upgrade-3.2-3.2.1.sql,v 3.8 2000/04/07 11:21:38 mbryzek Exp

--
-- SELF MONITORING
--
create table is_global_state (
        last_system_reboot	date
);

create table is_test_state (
	test_type		varchar(12) primary key,
	last_starttime		date,
	last_stoptime		date,
	run_count		integer,
	enabled_p		char(1) default 't'
                                   check(enabled_p in ('t','f')),
	run_period_secs		integer
);

INSERT INTO is_global_state (last_system_reboot) VALUES (NULL);

INSERT INTO is_test_state ( test_type ) VALUES ('tcp');
INSERT INTO is_test_state ( test_type ) VALUES ('web');
INSERT INTO is_test_state ( test_type ) VALUES ('ping');
INSERT INTO is_test_state ( test_type ) VALUES ('mail');
-- 'notify' isn't really a test, but we want to track the
-- state of the notify schedule process...
INSERT INTO is_test_state ( test_type ) VALUES ('notify');

create sequence is_mail_run_number start with 1;

create sequence is_test_sequence start with 10000;

create table is_test_proc_log (
	test_id			integer not null primary key,
	test_type		not null references is_test_state,
	proc_id			integer,
	num_up                  integer,
	num_down                integer,
	test_starttime		date not NULL,
	test_stoptime		date
);

-- This table is to track emails that are sent out
create sequence is_sent_email_seq start with 10000;

create table is_sent_email_log (
	sent_email_id		integer not null primary key,
	sent_date		date not null,
	sent_to			varchar(30),
	subject			varchar(80),
	sent_cc			varchar(1000)
);
	


--
-- SERVICES
-- Tables to record 'what' we are monitoring, with mostly one table per
-- 'test'. i.e. we will be testing vanilla TCP, email, web, and ping
-- (icmp) response.
--
create sequence is_services_seq start with 1000;

create table is_services (
	service_id		integer not null primary key,
	ip_or_hostname		varchar(60) not null,
	port			integer not null,
	protocol		varchar(20),
	name			varchar(100),
	tcp_response		varchar(50),
	first_monitored		date,
	timeout			integer default 20 not null,
	company			varchar(100),
	enabled_p		char(1) default 'f'
                                   check(enabled_p in ('t','f')),
        ping_enabled_p		char(1) default 'f'
                                   check(ping_enabled_p in ('t','f')),
	unique (ip_or_hostname, port)
);

create or replace view is_services_active
as
select *
from is_services
where enabled_p = 't';


create sequence is_mail_services_seq start with 1000;

create table is_mail_services (
	mail_service_id		integer
        	constraint mail_service_id_pk primary key,
	service_id		integer 
		constraint service_id_null not null
		constraint service_id_is_service_ref references is_services,
	bouncer_email		varchar(100) default 'mmon_bouncer'
		constraint bouncer_email_null not null,
	   -- This is the special email address which should exist
	   -- on the monitored server.  Anything sent to that address
	   -- should return to sender.  It can be an address
	   -- without the '@hostname' part if the monitored server
	   -- will recognize it.
	last_unbounced_emailet_id	varchar(70),
	run_period		integer default 1
		constraint run_period_null not null,	
	   -- might not need run_period
	bounce_timeout_secs	integer default 60
		constraint bounce_timeout_secs_null not null,
	smtp_ok_p		char(1) default 't'
		constraint smtp_ok_boolean check(smtp_ok_p in ('t','f')),
	enabled_p		char(1) default 't'
		constraint enabled_boolean check(enabled_p in ('t','f'))
);

create or replace view is_mail_services_active
as
select 
     MAIL_SERVICE_ID,
     SERVICE_ID,
     BOUNCER_EMAIL,
     LAST_UNBOUNCED_EMAILET_ID,
     RUN_PERIOD,
     BOUNCE_TIMEOUT_SECS,
     SMTP_OK_P,
     ENABLED_P
from is_mail_services
where enabled_p = 't';

	
create sequence is_web_services_seq start with 1000;

create table is_web_services (
	web_service_id		integer not null primary key,
	service_id		integer not null references is_services,
	return_string		varchar(100) default 'success' not null,
	url			varchar(200) not null,
	query_string		varchar(200),
	enabled_p		char(1) default 't'
                                   check(enabled_p in ('t','f')),
	unique (service_id,url,return_string,query_string)
);

create or replace view is_web_services_active
as
select *
from is_web_services
where enabled_p = 't';


-- 
-- Logs and Alerts
--
create sequence is_event_log_sequence start with 1000;

create table is_event_log (
	event_id		integer not null primary key,
	service_id		references is_services,
        sub_service_id		integer,
	event_time		date,
	  -- discoverer is either a user_id for a test identification tag
	discoverer		varchar(30),
	event_description	varchar(40),
	test_type		not null references is_test_state,
	error_message		varchar(200),
	status_ok_p		char(1) default 't'
                                   check(status_ok_p in ('t','f'))
);


-- this is a log for the MTA SMTP test
create table is_mail_log (
	event_id		references is_event_log,
	emailet_id		varchar(70)
);

create sequence is_alert_sequence start with 1000;

create table is_alerts (
	alert_id		integer not null primary key,
	service_id		references is_services not null,
        sub_service_id		integer,
	event_id		references is_event_log not null,
	test_type		not null references is_test_state,
	status_ok_p		char(1) default 't'
                                   check(status_ok_p in ('t','f')),
	notified_p		char(1) default 'f'
				   check(notified_p in ('t','f')),
	unique (service_id, sub_service_id, test_type)
);


--
-- NOTIFICATIONS
--
create sequence is_notification_rules_seq start with 1000;

-- The is_notification_rules table contains the rules and defaults
-- for the creation of a notice.  There is much duplication between
-- the is_notification_rules table and the is_notices table because
-- the 'rules' are 'new notices'.  After a notice is generate, it seems
-- better to allow the attributes of the notice to be changeable as
-- opposed to be controlled by a parent rule.  This way, someone can
-- change the 'notification_mode' of a rule for a service so that 
-- all future notices follow the new mode, but all existing notices
-- remain the same.

create table is_notification_rules (
	rule_id			integer not null primary key,
	service_id		integer not null references is_services,
	sub_service_id		integer,
	user_id			integer not null references users,
	group_id		integer references user_groups,
	test_type		not null references is_test_state,
	  -- does this notification require acknowledgement?
	acknowledge_p		char(1) default 'f'
                                   check(acknowledge_p in ('t','f')),
	  -- should use be informed of server bounces? (quick up/down)
	bounce_notify_p		char(1) default 'f' not null
                                   check(bounce_notify_p in ('t','f')),
	  -- should a trouble ticket be opened?
	open_ticket_p		char(1) default 'f'
                                   check(open_ticket_p in ('t','f')),
	mail_cc			varchar(1000),
  	  -- the following are for people who have beepers
	  -- and need a special tag or something in the subject
	custom_subject	varchar(80),
	custom_body	varchar(500),
	  -- we always send email when the server is down, we can
	  -- also send email when the server comes back up
	notification_mode	varchar(30), 	-- 'down_then_up', 'periodic'
	-- these two are only used when notification_mode is 'periodic'
	notification_interval_hours	number default 2,
	last_notification	date,
	unique (service_id, user_id, group_id, test_type)
);

create sequence is_notices_seq start with 1000;

-- A notice is a reaction to an event created as a result of a
-- notification rule.
create table is_notices (
	notice_id		integer not null primary key,
	rule_id			references is_notification_rules,
	service_id		not NULL references is_services,
        sub_service_id          integer,
	user_id			not NULL references users,
	group_id		references user_groups,
	event_id		references is_event_log,
	test_type		not null references is_test_state,
	note			varchar(500),
	acknowledged_p		char(1) default NULL
				   check(acknowledged_p in ('t','f',NULL)),
	  -- 'f' means it should be acknowledged, but isn't yet
	  -- NULL means it doesn't need acknowledgement
	bounce_notify_p		char(1) default 'f' not null
                                   check(bounce_notify_p in ('t','f')),
	ticket_id		integer,
	mail_cc			varchar(1000),
  	  -- the following are for people who have beepers
	  -- and need a special tag or something in the subject
	custom_subject	varchar(80),
	custom_body	varchar(500),
	acknowledged_id		references users(user_id),
	creation_time		date,
	acknowledged_time	date,
	notification_mode	varchar(30), 	-- 'down_then_up', 'periodic'
	notification_interval_hours	integer default 2,
	last_notification	date
);
	

create table is_users (
     user_id  integer not null,
     disable_is_mail_p char(1) default 'f' not null
                         check( disable_is_mail_p in ('t','f')),
     primary key (user_id)
);
comment on table is_users is 'users who want no IS mail are in here with f, users who want mail have t or are not in table';

alter table is_users add ( foreign key (user_id) references users);

-- we need to add a row to user_group_types
-- I add it in such a way that it will not give 
-- an erro if you do it twice
insert into  user_group_types 
    (GROUP_TYPE,
     PRETTY_NAME,
     PRETTY_PLURAL,
     APPROVAL_POLICY,
     DEFAULT_NEW_MEMBER_POLICY,
     GROUP_MODULE_ADMINISTRATION,
     HAS_VIRTUAL_DIRECTORY_P,
     GROUP_TYPE_PUBLIC_DIRECTORY,
     GROUP_TYPE_ADMIN_DIRECTORY,
     GROUP_PUBLIC_DIRECTORY,
     GROUP_ADMIN_DIRECTORY)
select
     'is_service',
     'IS Checker Service',
     'IS Checker Services',
     'open',
     'open',
     'none',
     'f',
     NULL,
     NULL,
     NULL,
     NULL
from dual
where not exists
    (select x.group_type
     from user_group_types x
     where x.group_type = 'is_service');


-- END ISCHECKER --
