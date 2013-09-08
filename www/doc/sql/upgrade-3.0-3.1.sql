alter table users add (
	screen_name varchar(100),
	bio			varchar(4000)
);

alter table users add constraint users_screen_name_unique unique(screen_name);


-- changes to the download module (getting rid of triggers)

drop trigger download_log_user_delete_tr;
drop trigger download_versions_delete_info;
drop trigger downloads_rules_dload_del_tr;
drop trigger downloads_rules_version_del_tr;
drop trigger download_log_version_delete_tr;

alter table downloads drop constraint download_scope_check;
create table downloads_temp (
	download_id		integer primary key,
	-- if scope=public, this is a download for the whole system
        -- if scope=group, this is a download for/from a subcommunity
        scope           varchar(20) not null,
	-- will be NULL if scope=public 
	group_id	references user_groups on delete cascade,
	-- e.g., "Bloatware 2000"
	download_name	varchar(100) not null,
	directory_name	varchar(100) not null,
	description		varchar(4000),
	-- is the description in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	creation_date		date default sysdate not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
        -- state should be consistent
	constraint download_scope_check check ((scope='group' and group_id is not null) 
                                               or (scope='public'))
);

insert into downloads_temp
select download_id, scope, group_id, download_name, directory_name, description, html_p, creation_date, creation_user, creation_ip_address
from downloads;
commit;

create table download_versions_temp (
	version_id	integer primary key,
	download_id	not null references downloads_temp on delete cascade,
	-- when this can go live before the public
	release_date	date not null,
	pseudo_filename	varchar(100) not null,
	-- might be the same for a series of .tar files, we'll serve
	-- the one with the largest version_id
	version		number,
	status		varchar(30) check (status in ('promote', 'offer_if_asked', 'removed')),
	creation_date		date default sysdate not null ,
	creation_user		references users on delete set null,
	creation_ip_address	varchar(50) not null
);

insert into download_versions_temp
select version_id, download_id, release_date, pseudo_filename, version, status, creation_date, creation_user, creation_ip_address
from download_versions;
commit;

alter table download_rules drop constraint download_version_null_check;

create table download_rules_temp (
	rule_id		integer primary key,
	-- one of the following will be not null
	version_id	references download_versions_temp on delete cascade,
	download_id	references downloads_temp on delete cascade,
	visibility	varchar(30) check (visibility in ('all', 'registered_users', 'purchasers', 'group_members', 'previous_purchasers')),
	-- price to purchase or upgrade, typically NULL
	price		number,
	-- currency code to feed to CyberCash or other credit card system
	currency	char(3) default 'USD' references currency_codes,
	constraint download_version_null_check check ( download_id is not null or version_id is not null)
);

insert into download_rules_temp
select rule_id, version_id, download_id, user_scope, price, currency
from download_rules;
commit;

create table download_log_temp (
	log_id		integer primary key,
	version_id	not null references download_versions_temp on delete cascade,
	-- user_id should reference users, but that interferes with
	-- downloadlog_user_delete_tr below.
	user_id		references users on delete set null,
	entry_date	date not null,
	ip_address	varchar(50) not null,
	-- keeps track of why people downloaded this
	download_reasons varchar(4000)
);

insert into download_log_temp 
(log_id, version_id, user_id, entry_date, ip_address)
select log_id, version_id, user_id, entry_date, ip_address
from download_log;

commit;

drop table download_log;
drop table download_rules;
drop table download_versions;
drop table downloads;


alter table download_log_temp rename to download_log;
alter table download_rules_temp rename to download_rules;
alter table download_versions_temp rename to download_versions;
alter table downloads_temp rename to downloads;

create index download_group_idx on downloads ( group_id );

create or replace function download_authorized_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_visibility download_rules.visibility%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select visibility into v_visibility
	from download_rules
	where version_id = v_version_id;
	
	if v_visibility = 'all' 
	then	
		return 'authorized';
	elsif v_visibility = 'group_members' then	

		select group_id into v_group_id
		from downloads d, download_versions dv
		where dv.version_id = v_version_id
		and dv.download_id = d.download_id;

		select decode ( ad_group_member_p ( v_user_id, v_group_id ), 'f', 'not_authorized', 'authorized' )
	        into v_return_value
                from dual;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from user_group_map where user_id = v_user_id 
		and group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from users where user_id = v_user_id;
		
		return v_return_value;
	end if; 

     END download_authorized_p;
/
show errors

-- getting rid of faq triggers 

drop trigger faq_entry_faq_delete_tr;

create table faq_q_and_a_temp (
	entry_id	integer primary key,
	 -- which FAQ
	faq_id		not null references faqs on delete cascade,
	question	varchar(4000) not null,
	answer		varchar(4000) not null,
	 -- determines the order of questions in a FAQ
	sort_key	integer not null
);

insert into faq_q_and_a_temp
select entry_id, faq_id, question, answer, sort_key
from faq_q_and_a;
commit;

drop table faq_q_and_a;

alter table faq_q_and_a_temp rename to faq_q_and_a;



-- SCOPIFICATION OF THE CALENDAR MODULE

-- added scoping support for calendar module

create sequence calendar_category_id_sequence start with 1;
create table calendar_categories_temp (
	category_id	integer primary key,
	-- if scope=public, this is the address book the whole system
        -- if scope=group, this is the address book for a particular group
 	scope           varchar(20) not null,
	group_id	references user_groups,
	category	varchar(100) not null,
	enabled_p	char(1) default 't' check(enabled_p in ('t','f'))
);

create table calendar_temp (
	calendar_id	integer primary key,
	category_id	not null references calendar_categories_temp,
	title		varchar(100) not null,
	body		varchar(4000) not null,
	-- is the body in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	start_date	date not null,  -- first day of the event
	end_date	date not null,  -- last day of the event (same as start_date for single-day events)
	expiration_date	date not null,  -- day to stop including the event in calendars, typically end_date
	event_url	varchar(200),  -- URL to the event
	event_email	varchar(100),  -- email address for the event
	-- for events that have a geographical location
	country_code	references country_codes(iso),
	-- within the US
	usps_abbrev	references states,
	-- we only want five digits
	zip_code	varchar(10),
	approved_p	char(1) default 'f' check(approved_p in ('t','f')),
	creation_date	date not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null
);


insert into calendar_categories_temp 
(category_id, scope, category, enabled_p)
select calendar_category_id_sequence.nextval, 'public', category, enabled_p
from calendar_categories;

commit;

insert into calendar_temp
(calendar_id, category_id, title, body, html_p, start_date, end_date, expiration_date, event_url, 
event_email, country_code, usps_abbrev, zip_code, approved_p, creation_date, creation_user, creation_ip_address)
select calendar_id, (select category_id from calendar_categories_temp where category=c.category), title, body,
 html_p, start_date, end_date, expiration_date, event_url, event_email, country_code, usps_abbrev, 
zip_code, approved_p, creation_date, creation_user, creation_ip_address
from calendar c;

commit;

drop table calendar;
drop table calendar_categories;

alter table calendar_temp rename to calendar;
alter table calendar_categories_temp rename to calendar_categories;

alter table calendar_categories add constraint calendar_category_scope_check 
check ((scope='group' and group_id is not null) or
       (scope='public'));

alter table calendar_categories add constraint calendar_category_unique_check 
unique(scope, category, group_id);

create index calendar_categories_group_idx on calendar_categories ( group_id );

create or replace trigger calendar_dates
before insert on calendar
for each row
begin
 if :new.creation_date is null then
   :new.creation_date := sysdate;
 end if;
 if :new.end_date is null then
   :new.end_date := :new.start_date;
 end if;
 if :new.expiration_date is null then
   :new.expiration_date := :new.end_date;
 end if;
end;
/
show errors

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)
values
('calendar', 'Calendar', '/calendar', '/calendar/admin', '/admin/calendar', 'system', 't', '/doc/calendar.html', '/doc/sql/calendar.sql', 'A site like photo.net might want to offer a calendar of upcoming events. This has nothing to do with displaying things in a wall-calendar style format, as provided by the calendar widget. In fact, a calendar of upcoming events is usually better presented as a list. ');


-- spam system
alter table users_preferences add 	email_type		varchar(64);


-- users on vacation...
create sequence user_vacations_vacation_id_seq start with 1;
create table user_vacations (
	vacation_id	integer primary key,
	user_id		integer references users,
	start_date	date constraint user_vacations_start_const not null,
	end_date 	date constraint user_vacations_end_const not null,
	description	varchar(4000),
	contact_info	varchar(4000),
	-- should this user receive email during the vacation?
	receive_email_p char(1) default 't' 
  		constraint user_vacations_email_const check (receive_email_p in ('t','f')),
	last_modified	date,
	vacation_type   varchar(20)
);

create index user_vacations_user_id_idx on user_vacations(user_id);
create index user_vacations_dates_idx on user_vacations(start_date,end_date);
create index user_vacations_type_idx on user_vacations(vacation_type);



create or replace view users_alertable
as
select u.* 
 from users u
 where (u.on_vacation_until is null or 
        u.on_vacation_until < sysdate)
 and u.user_state = 'authorized'
 and (u.email_bouncing_p is null or u.email_bouncing_p = 'f')
 and not exists (select 1 
                   from user_vacations v
                  where v.user_id = u.user_id
                    and sysdate between v.start_date and v.end_date);


create or replace view users_spammable
as
select u.*, up.email_type 
 from users u, users_preferences up
 where u.user_id = up.user_id(+)
 and (on_vacation_until is null or 
      on_vacation_until < sysdate)
 and user_state = 'authorized'
 and (email_bouncing_p is null or email_bouncing_p = 'f')
 and (dont_spam_me_p is null or dont_spam_me_p = 'f')
 and not exists (select 1 
                   from user_vacations v
                  where v.user_id = u.user_id
                    and sysdate between v.start_date and v.end_date);


drop table spam_history;
drop sequence spam_id_sequence;

-- source the new spam.sql file
--
-- spam.sql
--
-- created January 9, 1999 by Philip Greenspun (philg@mit.edu)
-- modified by Tracy Adams on Sept 22, 1999 (teadams@mit.edu)
-- modified by Henry Minsky (hqm@ai.mit.edu)
--
--
-- a system for spamming classes of users and keeping track of 
-- what the publisher said

-- use this to prevent double spamming if user hits submit twice 

drop table spam_history;

create table spam_history (
	spam_id			integer primary key,
	from_address		varchar(100),
	pathname		varchar(700),
	title			varchar(200),
	template_p		char(1) default 'f' check (template_p in ('t','f')),
	-- message body text in multiple formats
	-- text/plain, text/aol-html, text/html
 	body_plain		clob,
 	body_aol		clob,
 	body_html		clob,
	-- query which over users_spammable.* to enumerate the recipients of this spam
	user_class_query	varchar(4000),
	creation_date		date not null,
        cc_emails		varchar(4000),
	-- to which users did we send this?
	user_class_description	varchar(4000),
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
	send_date		date,
	-- we'll increment this after every successful email
	n_sent			integer default 0,
	-- values: unsent, sending, sent, cancelled
	status			varchar(16),
	-- keep track of the last user_id we sent a copy of this spam to
	-- so we can resume after a server restart
	last_user_id_sent	integer references users,
	begin_send_time		date,
	finish_send_time	date
);

drop table daily_spam_files;

-- table for administrator to set up daily spam file locations
create table daily_spam_files (
	file_prefix 		varchar(400),
	subject			varchar(2000),
	target_user_class_id	integer,
	user_class_description	varchar(4000),
	from_address		varchar(200),
	template_p		char(1) default 'f' check (template_p in ('t','f')),
	period			varchar(64) default 'daily' check (period in ('daily','weekly', 'monthly', 'yearly')),
	day_of_week		integer,
	day_of_month		integer,
	day_of_year		integer
);


-- pl/sql proc to guess email type
drop table default_email_types;

create table default_email_types  (
 pattern 	varchar(200),
 mail_type 	varchar(64)
);

-- Here are some default values. Overriden by server startup routine in /tcl/spam-daemon.tcl
insert into default_email_types (pattern, mail_type) values ('%hotmail.com',  'text/html');
insert into default_email_types (pattern, mail_type) values ('%aol.com',      'text/aol-html');
insert into default_email_types (pattern, mail_type) values ('%netscape.net', 'text/html');

-- function to guess an email type, using the default_email_types patterns table
CREATE OR REPLACE FUNCTION guess_user_email_type (v_email varchar)
RETURN varchar
IS
cursor mail_cursor is select * from default_email_types;
BEGIN
  FOR mail_val IN mail_cursor LOOP
    IF upper(v_email) LIKE upper(mail_val.pattern)  THEN
	    RETURN mail_val.mail_type;
    END IF;
  END LOOP;
-- default 
  RETURN 'text/html';
END guess_user_email_type;
/
show errors

-- Trigger on INSERT into users which guesses users preferred email type
-- based on their email address
-- CREATE OR REPLACE TRIGGER guess_email_pref_tr 
-- AFTER INSERT ON users
-- FOR each row
-- BEGIN
--   UPDATE users_preferences set email_type = guess_user_email_type(:new.email) where user_id = :new.user_id;
--   IF SQL%NOTFOUND THEN
--    INSERT INTO users_preferences (user_id, email_type) VALUES (:new.user_id, guess_user_email_type(:new.email));
--   END IF;
-- END;
-- /
-- show errors
-- 
-- 
-- loop over all users, lookup users_prefs.email_type.
-- if email_type is null, set it to default guess based on email addr.
CREATE OR REPLACE PROCEDURE init_email_types 
IS
   CURSOR c1 IS
      SELECT up.user_id as prefs_user_id, users.email, users.user_id from users, users_preferences up
	WHERE users.user_id = up.user_id(+);
   prefs_user_id users_preferences.user_id%TYPE;

BEGIN
   FOR c1_val IN c1 LOOP
	-- since we did an outer join, if the user_prefs user_id field is null, then
	-- no record exists, so do an insert. Else do an update
	IF c1_val.prefs_user_id IS NULL THEN
	 INSERT INTO users_preferences (user_id, email_type) 
		values (c1_val.user_id, guess_user_email_type(c1_val.email));
	ELSE UPDATE users_preferences set email_type = guess_user_email_type(c1_val.email)
	 	WHERE user_id = c1_val.user_id;
	END IF;
   END LOOP;
   COMMIT;
END init_email_types;
/
show errors






-- ADDED COLUMNS TO SUPPORT GROUP TYPE VIRTUAL DIRECTORIES TO THE USER_GROUP_TYPE TABLE

alter table user_group_types add (
	-- does this group type support virtual group directories 	
	-- if has_virtual_directory_p is t, then virtual url /$group_type can be used instead of /groups 
	-- to access the groups of this type
	has_virtual_directory_p		char(1) default 'f' check(has_virtual_directory_p in ('t','f')),
	-- if has_virtual_directory_p is t and group_type_public_directory is not null, then files in 
	-- group_type_public_directory will be used instead of files in default /groups directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_type_public_directory     varchar(200),
	-- if has_virtual_directory_p is t and group_type_admin_directory is not null, then files in 
	-- group_type_admin_directory will be used instead of files in default /groups/admin directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_type_admin_directory      varchar(200),
	-- if has_virtual_directory_p is t and group_public_directory is not null, then files in 
	-- group_public_directory will be used instead of files in default /groups/group directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_public_directory          varchar(200),
	-- if has_virtual_directory_p is t and group_admin_directory is not null, then files in 
	-- group_admin_directory will be used instead of files in default /groups/admin/group directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_admin_directory           varchar(200)
);

-- small fix to the faq constraint check 
alter table faqs drop constraint faq_scope_check;
alter table faqs add constraint faq_scope_check check ((scope='group' and group_id is not null) 
                                                       or (scope='public' and group_id is null));


--
-- SYSTEM FOR SPAMMING MEMBERS OF A USER GROUP
--

-- added spam policy to the user_groups table

alter table user_groups add
(spam_policy varchar(30) default 'open' not null,
 constraint user_groups_spam_policy_check check(spam_policy in ('open','closed','wait')));

-- group_member_email_preferences table retains email preferences of members 
-- that belong to a particular group 

alter table user_group_map modify role	varchar(200);

create table group_member_email_preferences (
	group_id		references user_groups not null,
	user_id			references users not null ,
	dont_spam_me_p		char (1) default 'f' check(dont_spam_me_p in ('t','f')),
	primary key (group_id, user_id)  
);

-- user_user_bozo_filter table contains information to implement a personalized "bozo filter"
-- any user ( origin_user_id) can restrain any emails from some other user ( target_user_id )
-- this is not group specific


create table user_user_bozo_filter (
	origin_user_id	references users not null,
	target_user_id	references users not null,
	primary key (origin_user_id, target_user_id)
);


-- group_spam_history table holds the spamming log for this group 

create sequence group_spam_id_sequence  start with 1;

create table group_spam_history (
	spam_id			integer primary key,
	group_id		references user_groups not null,
	sender_id		references users(user_id) not null,
	sender_ip_address	varchar(50) not null,
	from_address		varchar(100),
	subject			varchar(200),
 	body			clob,
	send_to			varchar (50) default 'members' check (send_to in ('members','administrators')), 
	creation_date		date not null,
	-- approved_p matters only for spam policy='wait'
	-- approved_p = 't' indicates administrator approved the mail 
	-- approved_p = 'f' indicates administrator disapproved the mail, so it won't be listed for approval again
	-- approved_p = null indicates the mail is not approved/disapproved by the administrator yet 
	approved_p		char(1) default null check (approved_p is null or approved_p in ('t','f')),
	send_date		date,
	-- this holds the number of intended recipients
	n_receivers_intended	integer default 0,
	-- we'll increment this after every successful email
	n_receivers_actual	integer default 0
);



-- SCOPIFICATION OF THE CHAT MODULE

-- added scoping support for chat module
alter table chat_rooms add ( 
	scope 		varchar(20),
	group_id	references user_groups
);

update chat_rooms set scope='public';

commit;

alter table chat_rooms add constraint chat_scope_not_null_check 
check (scope is not null);

alter table chat_rooms add constraint chat_rooms_scope_check 
check ((scope='group' and group_id is not null) or
       (scope='public'));

create index chat_rooms_group_idx on chat_rooms ( group_id );


insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)
values
('chat', 'Chat', '/chat', '/chat/admin', '/admin/chat', 'system', 't', '/doc/chat.html', '/doc/sql/chat.sql', 'Why is a chat server useful? As traditionally conceived, it isnt. The Internet is good at coordinating people who are separated in space and time. If a bunch of folks could all
agree to meet at a specific time, the telephone would probably be a better way to support their interaction.');



-- update table_acs_properties, so that it uses module_key.
-- this way we can connect tables with their corresponding modules. 

alter table table_acs_properties add (
	 module_key      	    references acs_modules,
         group_public_file          varchar(200),
	 group_admin_file           varchar(200)
);

update table_acs_properties set module_key='news' where table_name='news';
update table_acs_properties set module_key='calendar' where table_name='calendar';
update table_acs_properties set admin_url_stub='/news/admin/item.tcl?news_id=' where table_name='news';
update table_acs_properties set admin_url_stub='/calendar/admin/item.tcl?calendar_id=' where table_name='calendar';
update table_acs_properties set group_public_file='item.tcl?news_id=' where table_name='news';
update table_acs_properties set group_admin_file='item.tcl?news_id=' where table_name='news';
update table_acs_properties set group_public_file='item.tcl?calendar_id=' where table_name='calendar';
update table_acs_properties set group_admin_file='item.tcl?calendar_id=' where table_name='calendar';
commit;





-- updates for the new file system code

-- for every folder and url, lets create a version record

alter table fs_versions add (url varchar(200));

-- create the version record for urls
insert into fs_versions
(version_id, file_id, creation_date, author_id, url)
select fs_version_id_seq.nextval, file_id, sysdate, owner_id, url from fs_files where url is not null;

-- create the version record for folders
insert into fs_versions
(version_id, file_id, creation_date, author_id)
select fs_version_id_seq.nextval, file_id, sysdate, owner_id from fs_files where folder_p = 't';


-- create a permissions_id for every version
insert into general_permissions (permissions_id, on_what_id, on_which_table, public_read_p, public_write_p, public_comment_p)
select gp_id_sequence.nextval, version_id, 'FS_VERSIONS', decode(public_read_p,'t','t','f'), decode(public_write_p,'t','t','f'), decode(public_read_p,'t','t','f') from fs_versions, fs_files where fs_versions.file_id = fs_files.file_id;


-- insert a permissions record for every group

insert into permissions_ug_map (permissions_id, group_id, role,
read_p, write_p, comment_p, owner_p) select permissions_id,
       	group_id, 
	'', 
	decode(group_read_p,'t','t','f'), 
	decode(group_write_p,'t','t','f'), 
	decode(group_read_p,'t','t','f'), 
	't' 
 from fs_files, 
	fs_versions, 
	general_permissions 
where on_which_table = 'FS_VERSIONS' 
	and on_what_id = fs_versions.version_id 
 	and fs_versions.file_id = fs_files.file_id 
 	and group_id is not null;


-- insert a permissions record for every file owner
insert into permissions_ug_map(permissions_id, user_id, read_p, write_p, comment_p, owner_p)
select 	permissions_id, 
	owner_id, 
	't', 
	't', 
	't', 
	't' 
   from fs_files, 
	fs_versions, 
	general_permissions 
  where on_which_table = 'FS_VERSIONS' 
    and on_what_id = fs_versions.version_id 
    and fs_versions.file_id = fs_files.file_id; 



-- drop the unwanted columns

alter table fs_files drop (group_read_p);
alter table fs_files drop (group_write_p);
alter table fs_files drop (public_read_p);
alter table fs_files drop (public_write_p);
alter table fs_files drop (url);


-- create the new view

create or replace view fs_versions_latest 
as
select * from fs_versions where superseded_by_id is null;


-- lets create an easy way to walk the tree so that we can join the connect by
-- with the permissions tables

create or replace view fs_files_tree
as
select
   file_id,	
   file_title,
   sort_key,
   depth,   
   folder_p,
   owner_id,
   deleted_p,
   group_id,
   public_p,
   parent_id,
   level as the_level
from fs_files
connect by prior fs_files.file_id = parent_id
start with parent_id is null;



------------------------------------------------------------
-- SUPPORT FOR USER SUBGROUPS. ADDED IN ACS 3.1
------------------------------------------------------------

-- add a parent_group_id to user_groups to support subgroups
alter table user_groups add ( 
	modification_date   date,
        modifying_user      integer references users,
        parent_group_id  references user_groups
);

-- index it to make parent lookups quick!
create index user_groups_parent_grp_id_idx on user_groups(parent_group_id);

-- This function returns the number of members all of the subgroups of
-- one group_id has. Note that since we made subgroups go 1 level down
-- only, this function only looks for groups whose parent is the specified
-- v_parent_group_id
create or replace function user_groups_number_subgroups (v_group_id IN integer)
return integer
IS
  v_count   integer;
BEGIN
  select count(1) into v_count from user_groups where parent_group_id = v_group_id;
  return v_count;
END;
/
show errors;


-- We need to be able to answer "How many total members are there in all 
-- of my subgroups?" 
create or replace function user_groups_number_submembers (v_parent_group_id IN integer)
return integer
IS
  v_count   integer;
BEGIN
  select count(1) into v_count 
    from user_group_map 
   where group_id in (select group_id 
                        from user_groups 
                       where parent_group_id=v_parent_group_id);
  return v_count;
END;
/
show errors;


-- While doing a connect by, we need to count the number of members in 
-- user_group_map. Since we can't join with a connect by, we create 
-- this function
create or replace function user_groups_number_members (v_group_id IN integer)
return integer
IS
  v_count   integer;
BEGIN
  select count(1) into v_count 
    from user_group_map 
   where group_id=v_group_id;
  return v_count;
END;
/
show errors;


-- easy way to get the user_group from an id. This is important when
-- using connect by in your table and it also makes the code using 
-- user subgroups easier to read (don't have to join an additional
-- user_groups tables). However, it is recommended that you only
-- use this pls function when you have to or when it truly saves you
-- from some heinous coding
create or replace function user_group_name_from_id (v_group_id IN integer)
return varchar
IS
  v_group_name    user_groups.group_name%TYPE;
BEGIN
  if v_group_id is null
     then return '';
  end if;
  
  select group_name into v_group_name from user_groups where group_id = v_group_id;
  return v_group_name;
END;
/
show errors;



-- With subgroups, we needed an easy way to add adminstration groups
-- and tie them to parents
create or replace procedure administration_subgroup_add (pretty_name IN
varchar, v_short_name IN varchar, v_module IN varchar, v_submodule IN
varchar, v_multi_role_p IN varchar, v_url IN varchar, 
v_parent_module IN varchar) 
IS
  v_group_id	integer;
  n_administration_groups integer;
  v_system_user_id integer; 
  v_parent_id integer;
BEGIN
  if v_submodule is null then
      select count(group_id) into n_administration_groups
        from administration_info 
        where module = v_module 
        and submodule is null;
      else
	select count(group_id) into n_administration_groups
         from administration_info
         where module = v_module 
         and submodule = v_submodule;
  end if;
  if n_administration_groups = 0 then 
     -- call procedure defined in community-core.sql to get system user
     v_system_user_id := system_user_id;
     select user_group_sequence.nextval into v_group_id from dual;
     insert into user_groups 
      (group_id, group_type, short_name, group_name, creation_user, creation_ip_address, approved_p, existence_public_p, new_member_policy, multi_role_p)
      values
      (v_group_id, 'administration', v_short_name, pretty_name, v_system_user_id, '0.0.0.0', 't', 'f', 'closed', v_multi_role_p);
     insert into administration_info (group_id, module, submodule, url) values (v_group_id, v_module, v_submodule, v_url);
   end if;

   Begin
      select ai.group_id into v_parent_id
      from administration_info ai, user_groups ug
      where ai.module = v_parent_module
      and ai.group_id != v_group_id
      and ug.group_id = ai.group_id
      and ug.parent_group_id is null;
   Exception when others then null;
   End;
   
   update user_groups
   set parent_group_id = v_parent_id
   where group_id = v_group_id;
end;
/
show errors




-- Adds the specified field_name and field_type to a group with group id v_group_id
-- if the member field already exists for this group, does nothing
-- if v_sort_key is not specified, the member_field will be added with sort_key
--   1 greater than the current max
create or replace procedure user_group_member_field_add (v_group_id   IN integer,
                                                         v_field_name IN varchar, 
                                                         v_field_type IN varchar,
                                                         v_sort_key   IN integer)
IS
  n_groups          integer;
BEGIN
  -- make sure we don't violate the unique constraint of user_groups_member_fields
  select decode(count(1),0,0,1) into n_groups
    from all_member_fields_for_group
   where group_id = v_group_id
     and field_name = v_field_name;

  if n_groups = 0 then 
     -- member_field is new - add it

     insert into user_group_member_fields 
     (group_id, field_name, field_type, sort_key)
     values
     (v_group_id, v_field_name, v_field_type, v_sort_key);

   end if;
end;
/
show errors;





-- function to create new groups of a specified type 
-- This is useful mostly when loading your modules - simply use this 
-- function to create the groups you need
create or replace procedure user_group_add (v_group_type IN varchar,
                                            v_pretty_name IN varchar, 
                                            v_short_name IN varchar,
                                            v_multi_role_p IN varchar)
IS
  n_groups          integer;
  v_system_user_id  integer; 
BEGIN
  -- make sure we don't violate the unique constraint of user_groups.short_name
  select decode(count(1),0,0,1) into n_groups
    from user_groups
   where upper(short_name)=upper(v_short_name);

  if n_groups = 0 then 
     -- call procedure defined in community-core.sql to get system user
     v_system_user_id := system_user_id;
     -- create the actual group
     insert into user_groups 
      (group_id, group_type, short_name, group_name, creation_user, creation_ip_address, approved_p, existence_public_p, new_member_policy, multi_role_p)
      values
      (user_group_sequence.nextval, v_group_type, v_short_name, v_pretty_name, v_system_user_id, '0.0.0.0', 't', 'f', 'closed', v_multi_role_p);
   end if;
end;
/
show errors


-- source the new intranet file
<<<<<<< upgrade-3.0-3.1.sql
@intranet.sql


-- upgrade the news body column to be a clob :)
-- I don't know how to rename a clob, so it takes two steps
-- to change the column type and to populate the new clob
-- column
alter table news add body_temp clob;
update news set body_temp=body;
alter table news drop column body;
alter table news add body clob;
update news set body=body_temp;
alter table news drop column body_temp;

-- and we found that a varchar(100) is not enough for a news title
alter table news modify title varchar(300);

commit;

@intranet.sql
