--
-- /www/doc/sql/upgrade-3.1-3.2.sql
--
-- Script to upgrade an ACS 3.1 database to ACS 3.2
-- 
-- $Id: upgrade-3.1-3.2.sql,v 3.17.2.24 2000/03/28 09:41:10 carsten Exp $
--

-- BEGIN SECURITY --
create table sec_sessions (
    -- Unique ID (don't care if everyone knows this)
    session_id            integer primary key,
    user_id               references users,
    -- A secret used for unencrypted connections
    token                 varchar(50) not null,
    -- A secret used for encrypted connections only. not generated until needed
    secure_token          varchar(50),
    browser_id            integer not null,
    -- Make sure all hits in this session are from same host
    last_ip               varchar(50) not null,
    -- When was the last hit from this session? (seconds since the epoch)
    last_hit              integer not null
);

create table sec_login_tokens (
    -- A table to track tokens assigned for permanent login. The login_token
    -- is isomorphic to the password, i.e., the user can use the login_token
    -- to log back in.
    user_id	references users not null,
    password    varchar(30) not null,
    login_token varchar2(50) not null,
    primary key(user_id, password)
);

-- When a user changes his password, delete any login tokens associated
-- with the old password.
create or replace trigger users_update_login_token
before update on users
for each row
begin
    delete from sec_login_tokens
    where user_id = :new.user_id and password != :new.password;
end;
/
show errors

create table sec_session_properties (
    session_id     references sec_sessions not null,
    module         varchar2(50) not null,
    property_name  varchar2(50) not null,
    property_value clob,
    -- transmitted only across secure connections?
    secure_p       char(1) check(secure_p in ('t','f')),
    primary key(session_id, module, property_name),
    foreign key(session_id) references sec_sessions on delete cascade
);

create table sec_browser_properties (
    browser_id     integer not null,
    module         varchar2(50) not null,
    property_name  varchar2(50) not null,
    property_value clob,
    -- transmitted only across secure connections?
    secure_p       char(1) check(secure_p in ('t','f')),
    primary key(browser_id, module, property_name)
);

create sequence sec_id_seq;

create or replace procedure sec_rotate_last_visit(
    v_browser_id IN sec_browser_properties.browser_id%TYPE,
    v_time IN integer
) is
begin
    delete from sec_browser_properties
        where browser_id = v_browser_id and module = 'acs' and property_name = 'second_to_last_visit';
    update sec_browser_properties
        set property_name = 'second_to_last_visit'
        where module = 'acs' and property_name = 'last_visit' and browser_id = v_browser_id;
    insert into sec_browser_properties(browser_id, module, property_name, property_value, secure_p)
        values(v_browser_id, 'acs', 'last_visit', to_char(v_time), 'f');
end;
/
show errors

-- END SECURITY --

-- BEGIN USER GROUPS --

-- Drop user_group_map's primary key (user_id + group_id),
-- and replace it with a unique constraint on user_id +
-- group_id + role.

alter table user_group_map drop primary key;
alter table user_group_map add unique (user_id, group_id, role);

-- Drop user_group_type_member_fields's primary key (user_id +
-- group_id), and replace it with a unique constraint on user_id +
-- group_id + role, which is a new column.

alter table user_group_type_member_fields add (role varchar(200));
alter table user_group_type_member_fields drop primary key;
alter table user_group_type_member_fields add unique (group_type, role, field_name);

-- Rename user_group_regdate trigger to user_group_approved_p_tr

drop trigger user_group_regdate;

create or replace trigger user_group_approved_p_tr
before insert on user_groups
for each row
declare
  group_type_row user_group_types%ROWTYPE;
begin
  if :new.approved_p is null then 
    select * into group_type_row from user_group_types ugt 
      where ugt.group_type = :new.group_type;
    if group_type_row.approval_policy = 'open' then
      :new.approved_p := 't';
    else 
      :new.approved_p := 'f';
    end if;
  end if;  
end;
/
show errors

-- new proc ad_user_has_role_p

create or replace function ad_user_has_role_p
  (v_user_id	IN user_group_map.user_id%TYPE,
   v_group_id	IN user_group_map.group_id%TYPE,
   v_role	IN user_group_map.role%TYPE)
return char
IS
  ad_user_has_role_p char(1);
BEGIN
  -- maybe we should check the validity of user_id and group_id;
  -- we're not doing it for now, because it would slow this function
  -- down with 2 extra queries

  select decode(count(*), 0, 'f', 't')
  into ad_user_has_role_p
  from user_group_map 
  where user_id = v_user_id
  and group_id = v_group_id
  and role = v_role;

  return ad_user_has_role_p;
END ad_user_has_role_p;
/
show errors

-- Replace superfluous triggers with default values

alter table user_groups modify (
	registration_date       date default sysdate
);

drop trigger user_group_map_regdate;
alter table user_group_map modify (
	registration_date	date default sysdate
);

drop trigger user_group_roles_creation_date;
alter table user_group_roles modify (
	creation_date	date default sysdate
);

drop trigger user_group_actions_create_date;
alter table user_group_actions modify (
	creation_date	date default sysdate
);

drop trigger user_gr_action_role_map_date;
alter table user_group_action_role_map modify (
	creation_date	date default sysdate
);

drop trigger user_group_map_queue_date;
alter table user_group_map_queue modify (
	queue_date	date default sysdate
);

-- END USER GROUPS --

-- BEGIN DOWNLOAD MODULE --
 
-- Change the data type of version column from number to varchar

alter table download_versions add ( temp_version varchar(30));

update download_versions 
set temp_version = to_char(version)
where version is not null;

alter table download_versions drop column version;

alter table download_versions add ( version varchar(30));

update download_versions
set version = temp_version;

alter table download_versions drop column temp_version;

-- Add new columns

alter table download_versions add (
	version_description 	varchar(4000),
	version_html_p		char(1) default 'f'
				check (version_html_p in ('t','f'))
);

commit;

-- END DOWNLOAD MODULE --

-- BEGIN INTRANET MODULE --

-- add partner status information to the intranet
create sequence im_partner_status_id_seq start with 1;
create table im_partner_status (
	partner_status_id	integer primary key,
	partner_status		varchar(100) not null unique,
	display_order		integer default 1
);

alter table im_partners add partner_status_id references im_partner_status;

-- populate the intranet partner status table
insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Targeted', 1);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'In Discussion', 2);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Active', 3);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Announced', 4);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Dormant', 5);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Dead', 6);

alter table im_employee_info add referred_by references users;
create index im_employee_info_referred_idx on im_employee_info(referred_by);

create or replace function im_project_ticket_project_id ( v_group_id IN integer )
RETURN integer
IS
  v_project_id    ticket_projects.project_id%TYPE;
BEGIN
  v_project_id := 0;
  BEGIN
    select project_id
    into v_project_id
    from ticket_projects
    where group_id = v_group_id;

    EXCEPTION WHEN OTHERS THEN NULL;
  END;
  return v_project_id;
END;
/
show errors;

begin
   user_group_add ('intranet', 'Partners', 'partner', 'f'); 
   user_group_add ('intranet', 'Authorized Users', 'authorized_users', 'f'); 
end;
/
show errors;

alter table im_employee_info add (
        featured_employee_approved_p char(1) 
              constraint featured_employee_p_con check(featured_employee_approved_p in ('t','f')),
        featured_employee_approved_by integer references users,
        featured_employee_blurb clob,
        featured_employee_blurb_html_p char(1) default 'f'
              constraint featured_emp_blurb_html_p_con check (featured_employee_blurb_html_p in ('t','f'))
);


-- END INTRANET MODULE --

-- BEGIN EVENTS MODULE --

-- create a procedure for initializing a new sequence initialized
-- to start with values from another sequence.

create or replace procedure init_sequence (new_seq IN varchar, old_seq IN varchar)
IS
	i_seq_val	integer;
	tmp_seq_val	integer;
	sql_stmt	varchar(500);
	i		integer;
BEGIN
	-- get the old sequence's value
	sql_stmt := 'select ' || old_seq || '.nextval from dual';
	EXECUTE IMMEDIATE sql_stmt INTO i_seq_val;

	-- set the new sequence to be the old sequence's value
	i := 0;
        FOR i IN 0..i_seq_val LOOP
	      EXECUTE IMMEDIATE
               'select ' || new_seq || '.nextval from dual'
              INTO tmp_seq_val;
	END LOOP;
END init_sequence;
/
show errors;

---------------------------------------------
-- create the new events module data model
---------------------------------------------

-- we store the ISO code in lower case, e.g,. 'us'

-- if detail_url does not start with "HTTP://" then we assume
-- it is a stub for information on our server and we grab it
-- from the file system, starting at [ns_info pageroot]

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


--- create the administration group for the Events module
begin
   administration_group_add ('Events Administration', 'events', 'events', '', 'f', '/admin/events/'); 
end;
/

-- create a group type of "events"
insert into user_group_types 
(group_type, pretty_name, pretty_plural, approval_policy, group_module_administration)
values
('events_group', 'Event', 'Events', 'closed', 'full');

create table events_group_info (
       group_id primary key references user_groups
);

-- can't ever delete an event/activity because it might have been
-- ordered and therefore the row in events_registrations would be hosed
-- so we flag it

create sequence events_activity_id_sequence;

-- the activities
create table events_activities (
	activity_id	integer primary key,
	-- activities are owned by user groups
	group_id	integer references user_groups,
	user_id		integer references users,
        creator_id      integer not null references users,
	short_name	varchar(100) not null,
	default_price   number default 0 not null,
	currency	char(3) default 'USD',
	description	clob,
        -- Is this activity occurring? If not, we can't assign
        -- any new events to it.
        available_p	char(1) default 't' check (available_p in ('t', 'f')),
        deleted_p	char(1) default 'f' check (deleted_p in ('t', 'f')),
        detail_url 	varchar(256) -- URL for more details,
);

create sequence events_venues_id_sequence;

-- where the events occur
create table events_venues (
       venue_id		  integer primary key,
       venue_name	  varchar(200) not null,
       address1		  varchar(100),
       address2		  varchar(100),
       city		  varchar(100) not null,
       usps_abbrev	  char(2),
       postal_code	  varchar(20),
       iso		  char(2) default 'us' references country_codes,
       time_zone	  varchar(50),
       needs_reserve_p	  char(1) default 'f' check (needs_reserve_p in ('t', 'f')),
       max_people	  number,	
       description	  clob
);

create sequence events_event_id_sequence;

-- the events (instances of activities)
create table events_events (
        event_id              integer not null primary key,
        activity_id	      integer not null references events_activities,
	venue_id	      integer not null references events_venues,
	-- the user group that is created for this event's registrants
	group_id	      integer not null references user_groups,
	creator_id	      integer not null references users,
        -- HTML to be displayed after a successful order.
        display_after         varchar(4000),
        -- Date and time.
        start_time            date not null,
        end_time              date not null,
	reg_deadline	      date not null,
        -- An event may have been cancelled.
        available_p	      char(1) default 't' check (available_p in ('t', 'f')),	
        deleted_p	      char(1) default 'f' check (deleted_p in ('t', 'f')),
        max_people	      number,
	-- can someone cancel his registration?		
	reg_cancellable_p     char(1) default 't' check (reg_cancellable_p in ('t', 'f')),
	-- does a registration need approval to become finalized?
	reg_needs_approval_p  char(1) default 'f' check (reg_needs_approval_p in ('t', 'f')),
	-- notes for doing av setup
	av_note		      clob,
	-- notes for catering
	refreshments_note     clob,
	-- extra info about this event
	additional_note	      clob,
	-- besides the web, is there another way to register?
	alternative_reg	      clob,
        check (start_time < end_time),
	check (reg_deadline <= start_time)
);

-- Each activity can have default custom fields registrants should enter.  
create table events_activity_fields (
	activity_id	not null references events_activities,
	column_name	varchar(30) not null,
	pretty_name	varchar(50) not null,
	-- something generic and suitable for handing to AOLserver, 
	-- e.g., boolean or text
	column_type	varchar(50) not null,
	-- something nitty gritty and Oracle-specific, e.g.,
	-- char(1) instead of boolean
	-- things like "not null"
	column_actual_type	varchar(100) not null,
	column_extra	varchar(100),
	-- Sort key for display of columns.
	sort_key	integer not null
);


-- Each event can have custom fields registrants should enter.  The
-- event's custom fields are actually stored in the table,
-- event_{$event_id}_info.  For example, the event with event_id == 5
-- would have a corresponding table of event_5_info.  Furthermore, this
-- table will contain a "user_id not null references users" column

-- This table describes the columns that go into event_{$event_id}_info
create table events_event_fields (
	event_id	not null references events_events,
	column_name	varchar(30) not null,
	pretty_name	varchar(50) not null,
	-- something generic and suitable for handing to AOLserver, 
	-- e.g., boolean or text
	column_type	varchar(50) not null,
	-- something nitty gritty and Oracle-specific, e.g.,
	-- char(1) instead of boolean
	-- things like "not null"
	column_actual_type	varchar(100) not null,
	column_extra	varchar(100),
	-- Sort key for display of columns.
	sort_key	integer not null
);

-- the organizers for events
create table events_organizers_map (
       event_id		      integer not null references events_events,  
       user_id		      integer not null references users,
       role		      varchar(200) default 'organizer' not null,
       responsibilities	      clob
);

create sequence events_price_id_sequence;

create table events_prices (
    price_id            integer primary key,
    event_id            integer not null references events_events,
    -- e.g., "Developer", "Student"
    description         varchar(100) not null,
    -- we also store the price here too in case someone doesn't want
    -- to use the ecommerce module but still wants to have prices
    price		number not null,
    -- This is for hooking up to ecommerce.	
    -- Each product is a different price for this event.  For example,
    -- student price and normal price products for an event.
--  product_id          integer references ec_products,
    -- prices may be different for early, normal, late, on-site
    -- admission,
    -- depending on the date
    expire_date	      date not null,
    available_date    date not null
);

create sequence events_orders_id_sequence;

create table events_orders (
       order_id		integer not null primary key,
--       ec_order_id	integer references ec_orders,
       -- the person who made the order
       user_id		integer not null references users,
       paid_p		char(1) default null check (paid_p in ('t', 'f', null)),
	payment_method	varchar(50),
	confirmed_date	date,
	price_charged	number,
	-- the date this registration was refunded, if it was refunded
	refunded_date	date,
	price_refunded	number,	
       	ip_address	varchar(50) not null
);

create sequence events_reg_id_sequence;

create table events_registrations(
        -- Goes into table at confirmation time:
	reg_id		integer not null primary key,
	order_id	integer not null references events_orders,
	price_id	integer not null references events_prices,
	-- the person registered for this reg_id (may not be the person
	-- who made the order)
	user_id		integer not null references users,
	-- reg_states: pending, shipped, canceled, refunded
	--pending: waiting for approval
	--shipped: registration all set 
	--canceled: registration canceled
	--waiting: registration is wait-listed
	reg_state	varchar(50) not null check (reg_state in ('pending', 'shipped', 'canceled',  'waiting')),
	-- when the registration was made
	reg_date	date,
	-- when the registration was shipped
	shipped_date	date,
	org		varchar(4000),
	title_at_org	varchar(4000),
	attending_reason  clob,
	where_heard	varchar(4000),
	-- does this person need a hotel?
        need_hotel_p	char(1) default 'f' check (need_hotel_p in ('t', 'f')),
	-- does this person need a rental car?
        need_car_p	char(1) default 'f' check (need_car_p in ('t', 'f')),
	-- does this person need airfare?
	need_plane_p	char(1) default 'f' check (need_plane_p in ('t', 'f')),
	comments	clob
);

-- trigger for recording when a registration ships
create or replace trigger event_ship_date_trigger
before insert or update on events_registrations
for each row
when (old.reg_state <> 'shipped' and new.reg_state = 'shipped')
begin
	:new.shipped_date := sysdate;
end;
/
show errors

-- create a view that shows order states based upon each order's 
-- registrations.  The order states are:
-- void: All registrations canceled
-- incomplete: This order is not completely fulfilled--some registrations
-- are either canceled, waiting, or pending
-- fulfilled: This order is completely fulfilled
create or replace view events_orders_states 
as
select  o.*,
o_states.order_state
from events_orders o,
 (select
 order_id,
 decode (floor(avg (decode (reg_state, 
 		   'canceled', 0,
		   'waiting', 1,
		   'pending', 2,
		   'shipped', 3,
		   0))),
	     0, 'canceled',
	     1, 'incomplete',
	     2, 'incomplete',
	     3, 'fulfilled',
	     'void') as order_state
 from events_registrations
 group by order_id) o_states
where o_states.order_id = o.order_id;

create or replace view events_reg_not_canceled
as 
select * 
from events_registrations
where reg_state <> 'canceled';

create or replace view events_reg_canceled
as 
select * 
from events_registrations
where reg_state = 'canceled';

create or replace view events_reg_shipped
as
select *
from events_registrations
where reg_state = 'shipped';

create sequence events_fs_file_id_seq start with 1;

create table events_file_storage (
	file_id			integer primary key,
	file_title		varchar(300),
	file_content		blob not null,
	client_file_name		varchar(500),
	file_type		varchar(100),
	file_extension		varchar(50),
	on_which_table		varchar(100) not null,
	on_what_id		integer not null,
	-- the size (kB) of the fileument
	file_size		integer, 
	created_by		references users,
	creation_ip_address	varchar(100),
	creation_date		date default sysdate 
);
	
create index events_file_storage_id_idx on events_file_storage(on_which_table, on_what_id);

-- Sync up the new sequences with the old ones.

execute	init_sequence('events_activity_id_sequence', 'evreg_activity_id_sequence');
execute	init_sequence('events_venues_id_sequence', 'evreg_venues_id_sequence');
execute	init_sequence('events_event_id_sequence', 'evreg_event_id_sequence');

----------------------------------
-- copy the old events data
----------------------------------

--function for creating a user group for an event
create or replace function create_event_group(
 event_id_in integer
)
return integer
IS
	event_group_name	varchar(100);
	event_short_name	varchar(100);
	event_group_id		integer;
	event_start		varchar(25);
	short_name		varchar(100);
	city varchar(100);
	usps_abbrev		char(2);
	iso			char(2);
	pretty_location		varchar(100);
BEGIN

--	select 
--	to_char(e.start_time, 'YYYY-MM-DD HH:MM:SS') into event_start,
--	a.short_name into short_name,
--	v.city into city,
--	v.usps_abbrev into usps_abbrev,
--	v.iso into iso

	select 
	to_char(e.start_time, 'YYYY-MM-DD HH:MM:SS'),
	a.short_name, v.city, v.usps_abbrev, v.iso
	into event_start, short_name, city, usps_abbrev, iso
	from evreg_events e, evreg_activities a, evreg_venues v
	where a.activity_id = e.activity_id
	and v.venue_id = e.venue_id
	and e.event_id = event_id_in;

	IF iso = 'us' THEN
	   pretty_location := city || ', ' || usps_abbrev;
	ELSE
	   pretty_location := city || ', ' || iso;
	END IF;
	
	event_group_name := short_name || ' in ' || pretty_location || ' on ' || event_start;
	event_short_name := short_name_from_group_name(event_group_name);

	--create the user group now
	user_group_add('events_group', event_group_name, 
		       event_short_name, 't');

        --get the group id
	select group_id
	into event_group_id
	from user_groups
	where short_name = event_short_name;

	return event_group_id;
end create_event_group;
/
show errors

--procedure for creating the appropriate prices for events
create or replace procedure create_event_prices
IS
	price_avail_time	date;
	
	cursor c1 is
	select event_id, end_time, start_time
	from events_events;
BEGIN
	FOR e IN c1 LOOP

	    --see what to put for when this price is available
	    IF sysdate < e.start_time THEN
	       --this event hasn't taken place yet, so the price is
	       --available now
	       price_avail_time := sysdate;
	    ELSE
	       --event has already taken place, so arbitrarily 
	       --use the start time - 1 day
	       price_avail_time := e.start_time - 1;
	    END IF;

	    INSERT into events_prices
	    (price_id, event_id, description, price, expire_date,
	    available_date)
	    VALUES
	    (events_price_id_sequence.nextval, e.event_id,
	    'Normal Price', 0, e.end_time, price_avail_time);

	END LOOP;
END create_event_prices;
/
show errors;

--procedure to copy the registrations over
create or replace procedure copy_registrations
IS
	i_order_id	integer;
	v_reg_state	varchar(50);
	i_price_id	integer;

	cursor c1 is
	select 
	event_id, user_id, paid_p,
	confirmed_date, ip_address, order_state,
	org, title_at_org, attending_reason,
	where_heard, need_hotel_p, need_car_p, 
	need_plane_p, comments, canceled_p
	from evreg_orders;
BEGIN
	FOR o in c1 LOOP

	    --this depends on events_events having the same
	    --event_id's as evreg_events
	    select price_id into i_price_id
	    from events_prices
	    where event_id = o.event_id;

	    --create the event order
	    select events_orders_id_sequence.nextval into i_order_id
	    from dual;

	    INSERT into events_orders 
	    (order_id, user_id, paid_p, confirmed_date,
	    ip_address)
	    VALUES
	    (i_order_id, o.user_id, o.paid_p,
	    o.confirmed_date, o.ip_address);

	    --figure out the reg_state
	    IF o.canceled_p = 't' THEN
	       v_reg_state := 'canceled';
	    ELSIF o.order_state = 'shipped' THEN
	       v_reg_state := 'shipped';
	    ELSE
	       v_reg_state := 'pending';
	    END IF;

	    --copy the registration
	    INSERT into events_registrations 
	    (reg_id, order_id, price_id, user_id, reg_state, org,
	    title_at_org, attending_reason, where_heard, need_hotel_p,
	    need_car_p, need_plane_p, reg_date)
	    VALUES
	    (events_reg_id_sequence.nextval, i_order_id, i_price_id,
	    o.user_id, v_reg_state, o.org, o.title_at_org,
	    o.attending_reason, o.where_heard, o.need_hotel_p,
	    o.need_car_p, o.need_plane_p, o.confirmed_date);

	END LOOP;
END copy_registrations;
/
show errors; 

insert into events_activities
(activity_id, group_id, creator_id, short_name,
default_price, currency, description, available_p, deleted_p,
detail_url)
select activity_id, group_id, creator_id, short_name,
0, 'USD', description, available_p, 'f', detail_url
from evreg_activities;

insert into events_venues
(venue_id, venue_name, address1, address2,
city, usps_abbrev, postal_code, iso, 
needs_reserve_p, max_people, description)
select venue_id, venue_name, address1, address2,
city, usps_abbrev, postal_code, iso, 
needs_reserve_p, max_people, description
from evreg_venues;

insert into events_events
(event_id, activity_id, venue_id, display_after,
max_people, av_note, refreshments_note, additional_note,
start_time, end_time, reg_deadline, reg_cancellable_p, group_id,
reg_needs_approval_p, creator_id)
SELECT
event_id, activity_id, venue_id, display_after,
max_people, av_note, refreshments_note, additional_note,
start_time, end_time, start_time, 't',
create_event_group(event_id),
'f', system_user_id
from evreg_events;	

insert into events_organizers_map
(event_id, user_id, role, responsibilities)
select event_id, user_id, role, responsibilities
from evreg_organizers_map;

execute create_event_prices();

execute copy_registrations();

INSERT into events_file_storage
(file_id, file_title, file_content, client_file_name,
file_type, file_extension, on_which_table, on_what_id,
file_size, created_by, creation_ip_address, creation_date)
SELECT
file_id, file_title, file_content, client_file_name,
file_type, file_extension, on_which_table, on_what_id,
file_size, created_by, creation_ip_address, creation_date
FROM evreg_file_storage;

------------------------------------------
-- delete the old events data model
------------------------------------------
drop sequence evreg_file_storage_file_id_seq;
drop table evreg_file_storage;

drop sequence evreg_order_id_sequence;
drop view evreg_orders_not_canceled;
drop view evreg_orders_canceled;
drop table evreg_orders;

drop table evreg_organizers_map; 

drop sequence evreg_event_id_sequence;
drop table evreg_events;

drop table evreg_venues;
drop sequence evreg_venues_id_sequence;

drop table evreg_activities;
drop sequence evreg_activity_id_sequence;

--drop the helper procedures/function
drop procedure init_sequence;
drop function create_event_group;
drop procedure create_event_prices;
drop procedure copy_registrations;

-- END EVENTS MODULE --


-- BEGIN GENERAL-PERMISSIONS --

-- The general-permissions data model has changed substantially,
-- going from two tables to just one.

-- First, we create a temporary table into which we migrate the
-- legacy data. Then, we drop all the existing data model,
-- create the new one (incl. triggers, view, package), copy data
-- from the temporary table into the new table, and finally
-- drop the temporary table.
--
create table general_permissions_temp (
	permission_id		integer not null primary key,
	on_what_id		integer not null,
	on_which_table		varchar(30) not null,
        scope           	varchar(20),
	user_id			references users,
	group_id		references user_groups,
	role			varchar(200),
	permission_type		varchar(20) not null,
	check ((scope = 'user' and user_id is not null
                and group_id is null and role is null) or
	       (scope = 'group_role' and user_id is null
                and group_id is not null and role is not null) or
	       (scope = 'group' and user_id is null
                and group_id is not null and role is null) or
	       (scope in ('registered_users', 'all_users')
                and user_id is null
                and group_id is null and role is null)),
	unique (on_what_id, on_which_table,
                scope, user_id, group_id, role, permission_type)
);

declare
 v_scope general_permissions_temp.scope%TYPE;
begin
 -- Turn each row in general_permissions into as many as three rows
 -- in general_permissions_temp: public_read_p, public_write_p, and/or
 -- public_comment_p. For all, the scope will be 'all_users'.
 --
 for perm in (select * from general_permissions) loop
  if perm.public_read_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table, 'all_users', 'read');
  end if;

  if perm.public_write_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table, 'all_users', 'write');
  end if;

  if perm.public_comment_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table, 'all_users', 'comment');
  end if;
 end loop;

 -- Turn each row in permissions_ug_map into as many as four rows
 -- in general_permissions_temp: read_p, write_p, comment_p, and/or
 -- owner_p (which we will turn into 'administer' permission_type).
 -- We will need to determine the scope for each row.
 --
 for perm in (select
               p.on_what_id, p.on_which_table, pgm.user_id, pgm.group_id,
               pgm.role, pgm.read_p, pgm.write_p, pgm.comment_p, pgm.owner_p
              from permissions_ug_map pgm, general_permissions p
              where pgm.permissions_id = p.permissions_id)
 loop
  if perm.user_id is not null then
   v_scope := 'user';
  elsif perm.group_id is not null then
   if perm.role is not null then
    v_scope := 'group_role';
   else
    v_scope := 'group';
   end if;
  end if;

  if perm.read_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table,
     user_id, group_id, role, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table,
     perm.user_id, perm.group_id, perm.role, v_scope, 'read');
  end if;

  if perm.write_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table,
     user_id, group_id, role, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table,
     perm.user_id, perm.group_id, perm.role, v_scope, 'write');
  end if;

  if perm.comment_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table,
     user_id, group_id, role, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table,
     perm.user_id, perm.group_id, perm.role, v_scope, 'comment');
  end if;

  if perm.owner_p = 't' then
   insert into general_permissions_temp
    (permission_id, on_what_id, on_which_table,
     user_id, group_id, role, scope, permission_type)
   values
    (gp_id_sequence.nextval, perm.on_what_id, perm.on_which_table,
     perm.user_id, perm.group_id, perm.role, v_scope, 'administer');
  end if;
 end loop; 
end;
/
show errors

drop table permissions_ug_map;
drop table general_permissions;
drop table perm_change_state_rowids;

create table general_permissions (
	permission_id		integer not null primary key,
	on_what_id		integer not null,
	on_which_table		varchar(30) not null,
        scope           	varchar(20),
	user_id			references users,
	group_id		references user_groups,
	role			varchar(200),
	permission_type		varchar(20) not null,
	check ((scope = 'user' and user_id is not null
                and group_id is null and role is null) or
	       (scope = 'group_role' and user_id is null
                and group_id is not null and role is not null) or
	       (scope = 'group' and user_id is null
                and group_id is not null and role is null) or
	       (scope in ('registered_users', 'all_users')
                and user_id is null
                and group_id is null and role is null)),
	unique (on_what_id, on_which_table,
                scope, user_id, group_id, role, permission_type)
);

-- This trigger normalizes values in the on_which_table column to
-- be all lowercase. This makes it easier to implement a case-
-- insensitive API (since function-based indexes do not seem to
-- work as advertised in Oracle 8.1.5). Just make sure to call
-- LOWER whenever constructing a criterion involving
-- on_which_table.
--
create or replace trigger gp_on_which_table_tr
before insert or update on general_permissions
for each row
begin
 :new.on_which_table := lower(:new.on_which_table);
end gp_on_which_table_tr;
/
show errors

-- This trigger normalizes values in the permission_type column to
-- be all lowercase. This makes it easier to implement a case-
-- insensitive API (since function-based indexes do not seem to
-- work as advertised in Oracle 8.1.5). Just make sure to call
-- LOWER whenever constructing a criterion involving
-- permission_type.
--
create or replace trigger gp_permission_type_tr
before insert or update on general_permissions
for each row
begin
 :new.permission_type := lower(:new.permission_type);
end gp_permission_type_tr;
/
show errors

-- This view makes it simple to fetch a standard set of
-- permission flags (true or false) for arbitrary rows
-- in the database.
--
create or replace view general_permissions_grid
as
select
 p.on_what_id, p.on_which_table,
 p.scope, p.user_id, p.group_id, p.role,
 decode(sum(decode(p.permission_type, 'read', 1, 0)), 0, 'f', 't')
  as read_permission_p,
 decode(sum(decode(p.permission_type, 'comment', 1, 0)), 0, 'f', 't')
  as comment_permission_p,
 decode(sum(decode(p.permission_type, 'write', 1, 0)), 0, 'f', 't')
  as write_permission_p,
 decode(sum(decode(p.permission_type, 'administer', 1, 0)), 0, 'f', 't')
 as administer_permission_p
from general_permissions p
group by
 p.on_what_id, p.on_which_table,
 p.scope, p.user_id, p.group_id, p.role;

create or replace package ad_general_permissions
as
 -- Returns 't' if the specified user has the specified permission on
 -- the specified database row.
 --
 function user_has_row_permission_p (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return char;

 function grant_permission_to_user (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_role (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_group (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_reg_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_all_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 procedure revoke_permission (
  v_permission_id	general_permissions.permission_id%TYPE
 );

 function user_permission_id (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function group_role_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function group_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function reg_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function all_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 procedure copy_permissions (
  v_old_on_what_id	general_permissions.on_what_id%TYPE,
  v_new_on_what_id	general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE,
  v_user_id1		general_permissions.user_id%TYPE,
  v_user_id2		general_permissions.user_id%TYPE
 );
end ad_general_permissions;
/
show errors

create or replace package body ad_general_permissions
as
 function user_has_row_permission_p (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return char
 is
  user_has_row_permission_p char(1) := 'f';
 begin

  -- Return true if the user is a system administrator
  -- or if the permission has been granted to at least one of:
  --
  -- * all users
  -- * registered users if the user is logged in
  -- * the user directly
  -- * a role in a user group that the user plays
  -- * an entire user group of which the user is a member
  --
  select ad_group_member_p(v_user_id, system_administrator_group_id)
  into user_has_row_permission_p
  from dual;

  if user_has_row_permission_p = 'f' then
   select decode(count(*), 0, 'f', 't')
   into user_has_row_permission_p
   from general_permissions gp
   where gp.on_what_id = v_on_what_id
   and gp.on_which_table = lower(v_on_which_table)
   and gp.permission_type = lower(v_permission_type)
   and ((gp.scope = 'all_users')
        or (gp.scope = 'registered_users'
            and v_user_id > 0)
        or (gp.scope = 'group'
            and exists (select 1
                        from user_group_map ugm
                        where ugm.user_id = v_user_id
                        and ugm.group_id = gp.group_id))
        or (gp.scope = 'group_role'
            and exists (select 1
                        from user_group_map ugm
                        where ugm.user_id = v_user_id
                        and ugm.group_id = gp.group_id
                        and ugm.role = gp.role))
        or (gp.scope = 'user'
            and gp.user_id = v_user_id))
   and rownum < 2;
  end if;

  return user_has_row_permission_p;
 end user_has_row_permission_p;

 function grant_permission_to_user (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, user_id, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'user', v_user_id, v_permission_type);

  return v_permission_id;
 end grant_permission_to_user;

 function grant_permission_to_role (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, group_id, role, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'group_role', v_group_id, v_role, v_permission_type);

  return v_permission_id;
 end grant_permission_to_role;

 function grant_permission_to_group (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, group_id, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'group', v_group_id, v_permission_type);

  return v_permission_id;
 end grant_permission_to_group;

 function grant_permission_to_reg_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'registered_users', v_permission_type);

  return v_permission_id;
 end grant_permission_to_reg_users;

 function grant_permission_to_all_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'all_users', v_permission_type);

  return v_permission_id;
 end grant_permission_to_all_users;

 procedure revoke_permission (
  v_permission_id	general_permissions.permission_id%TYPE
 )
 is
 begin
  delete from general_permissions
  where permission_id = v_permission_id;
 end revoke_permission;

 function user_permission_id (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'user'
  and user_id = v_user_id
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end user_permission_id;

 function group_role_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'group_role'
  and group_id = v_group_id
  and role = v_role
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end group_role_permission_id;

 function group_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'group'
  and group_id = v_group_id
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end group_permission_id;

 function reg_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'registered_users'
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end reg_users_permission_id;

 function all_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'all_users'
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end all_users_permission_id;


 procedure copy_permissions (
  v_old_on_what_id	general_permissions.on_what_id%TYPE,
  v_new_on_what_id	general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE,
  v_user_id1		general_permissions.user_id%TYPE,
  v_user_id2		general_permissions.user_id%TYPE
 )
 is
 begin
  insert into general_permissions
    (permission_id, on_what_id, on_which_table, scope, user_id, 
     group_id, role, permission_type)
  select gp_id_sequence.nextval, v_new_on_what_id, lower(v_on_which_table),
    scope, user_id, group_id, role, permission_type
  from general_permissions
  where on_what_id = v_old_on_what_id and 
    on_which_table = lower(v_on_which_table) and
    (user_id is null or not user_id in (v_user_id1, v_user_id2));
 end copy_permissions;
end ad_general_permissions;
/
show errors

insert into general_permissions
select * from general_permissions_temp;

drop table general_permissions_temp;

-- END GENERAL-PERMISSIONS --


-- BEGIN BBOARD --

alter table bboard_topics add group_id integer references user_groups;

-- END BBOARD --


-- BEGIN ECOMMERCE (EVEANDER 3/4/00) --

alter table ec_products add (
	color_list		varchar(4000),
	size_list		varchar(4000),
	style_list		varchar(4000)
);

alter table ec_items add (
	color_choice	varchar(4000),
	size_choice	varchar(4000),
	style_choice	varchar(4000)
);

alter table ec_creditcards modify (
	billing_zip_code  varchar(80)
);

-- END ECOMMERCE CHANGES --


-- BEGIN SPAM --

alter table spam_history add (
	begin_send_time		date,
	finish_send_time	date
);


alter table daily_spam_files add (
	period	varchar(64) default 'daily'
		check (period in ('daily','weekly', 'monthly', 'yearly'))
);


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


create sequence bulkmail_id_sequence start with 1;

create table bulkmail_instances (
	bulkmail_id	integer primary key,
	description	varchar(400),
	creation_date	date not null,
	creation_user	references users(user_id),
	end_date	date,
	n_sent		integer
);

create table bulkmail_log (
	bulkmail_id	references bulkmail_instances,
	user_id		references users,
	sent_date	date not null
);

create table bulkmail_bounces (
	bulkmail_id	references bulkmail_instances,
	user_id		references users,
	creation_date	date default sysdate,
	active_p	char(1) default 't' check(active_p in ('t', 'f'))
);	
	
create index bulkmail_user_bounce_idx on bulkmail_bounces(user_id, active_p);

-- END SPAM --


-- BEGIN TICKET --

alter table ticket_domains add (message_template varchar2(4000));

-- END TICKET --


-- BEGIN NEWS --

create sequence newsgroup_id_sequence start with 4;

create table newsgroups (
	newsgroup_id	integer primary key,
        -- if scope=all_users, this is the news for all newsgroups
        -- is scope=registered_users, this is the news for all registered users
	-- if scope=public, this is the news for the main newsgroup
	-- if scope=group, this is news associated with a group
        scope           varchar(20) not null,
	group_id	references user_groups,
	check ((scope='group' and group_id is not null) or
	(scope='public') or
	(scope='all_users') or
	(scope='registered_users'))
);

create sequence news_item_id_sequence start with 100000;

create table news_items (
	news_item_id		integer primary key,
	newsgroup_id		references newsgroups not null,
	title			varchar(200) not null,
	body			clob not null,
	-- is the body in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	approval_state		varchar(15) default 'unexamined' check(approval_state in ('unexamined','approved', 'disapproved')),
	approval_date		date,
	approval_user		references users(user_id),
	approval_ip_address	varchar(50),
	release_date		date not null,
	expiration_date		date not null,
	creation_date		date not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null
);

create index newsgroup_group_idx on newsgroups ( group_id );
create index news_items_idx on news_items ( newsgroup_id );

-- Create the default newsgroups

insert into newsgroups (newsgroup_id, scope) values (1, 'registered_users');
insert into newsgroups (newsgroup_id, scope) values (2, 'all_users');
insert into newsgroups (newsgroup_id, scope) values (3, 'public');

-- Create permissions for default newsgroups

-- Migration sql commands
insert into newsgroups
 (newsgroup_id, scope, group_id)
select newsgroup_id_sequence.nextval, 'group', g.group_id
from (select distinct(group_id) from news where group_id is not null) g;

-- Insert group news items
insert into news_items (news_item_id, newsgroup_id, title, body, html_p, 
 approval_state, release_date, expiration_date, 
 creation_date, creation_user, creation_ip_address) 
select news_id, ng.newsgroup_id, title, body, html_p, 
 decode(approved_p, 't', 'approved', 'f', 'disapproved', 'unexamined'), 
 release_date, expiration_date, 
 creation_date, creation_user, creation_ip_address 
from news, newsgroups ng 
where news.group_id = ng.group_id
and news.scope = 'group';

-- Insert public rows
insert into news_items (news_item_id, newsgroup_id, title, body, html_p, 
 approval_state, release_date, expiration_date, 
 creation_date, creation_user, creation_ip_address) 
select news_id, 3, title, body, html_p, 
 decode(approved_p, 't', 'approved', 'f', 'disapproved', 'unexamined'), 
 release_date, expiration_date, 
 creation_date, creation_user, creation_ip_address 
from news
where scope = 'public';

drop index news_idx;
drop index news_group_idx;
drop table news;
drop sequence news_id_sequence;

-- migrate the on_which_table, on_what_column in general_comments
update general_comments
set on_which_table = 'news_items'
where on_which_table = 'news';

-- END NEWS --


-- BEGIN CONTEST --

-- don't complain about constraints until we're done

set constraints all deferred;

-- add domain_id sequence

create sequence contest_domain_id_sequence;

-- add the domain_id column to contest domains and extra columns

alter table contest_domains add (domain_id integer);
alter table contest_extra_columns add (domain_id integer);

-- populate it

declare
    cursor contest_cursor is
      select domain from contest_domains;

    new_domain_id integer;
    domain_name contest_domains.domain%TYPE;
begin

    open contest_cursor;

    loop
        fetch contest_cursor into domain_name;
        exit when contest_cursor%notfound;

        select contest_domain_id_sequence.nextval 
        into new_domain_id
        from dual;

        update contest_domains set domain_id = new_domain_id 
        where domain = domain_name;

        update contest_extra_columns set domain_id = new_domain_id
        where domain = domain_name;

    end loop;

    close contest_cursor;

end;
/
show errors;


-- turn off primary keyness of domain in contest_domains
-- and turn on primary keyness of domain_id in contest_domains

alter table contest_domains drop primary key cascade;
alter table contest_domains add (primary key(domain_id));


-- turn on uniqueness of domain in contest_domains
-- (this also creates an index, which helps when dealing with
-- backwards-compatibility when pages use old domain key URLs

alter table contest_domains add (unique(domain));


-- set up the references relation from contest_extra_columns

alter table contest_extra_columns
add constraint contest_xcol_fk foreign key (domain_id) references contest_domains;


-- nuke the domain column from contest_extra_columns

alter table contest_extra_columns drop column domain;


-- add not-nullness to domain_id columns

alter table contest_domains modify (domain_id not null);
alter table contest_extra_columns modify (domain_id not null);

-- and the trick, she is done

set constraints all immediate;

-- END CONTEST  --


-- BEGIN CLASSIFIEDS --

-- The big picture:  add new integer primary keys for tables
-- that don't have them.  The ad_domains table has a
-- varchar primary key, so we need to change all the locations
-- that refer to ad_domains.domain to refer to ad_domains.domain_id.
-- This involves adding a new foreign key column to several tables,
-- populating the values, and changing the foregin key constraints
-- to refer to the new column.
  
-- drop primary key constraint and all referential
-- integrity constraints that refer to 'domain'
-- from other tables.  We will recreate these constraints
-- one by one on the other tables as we add new domain_id
-- foreign keys to them.
alter table ad_domains drop primary key cascade;

-- but 'domain' continues to be restricted to unique values
alter table ad_domains add (unique(domain));

-- add new 'domain_id' column, which will be the primary key;
-- don't give it a primary key constraint yet, because it has
-- no values.
alter table ad_domains add (
         domain_id               integer
);

-- add sequence to generate domain_id values
create sequence ad_domain_id_seq start with 1;

-- populate new domain_id columns
update ad_domains set domain_id = ad_domain_id_seq.nextval;

commit;

-- now add primary key constraint, since the column has values
alter table ad_domains add (primary key(domain_id));

-- add new integer primary key and foreign key for domain_id
-- (no need to drop primary key constraint since there wasn't one)
alter table ad_integrity_checks  add (
        integrity_check_id integer,
        domain_id integer
);

create sequence ad_integrity_check_id_seq start with 1;

-- populate new primary key column
update ad_integrity_checks set integrity_check_id = ad_integrity_check_id_seq.nextval;

-- and populate foreign key column
update ad_integrity_checks
set domain_id = (select domain_id
                 from ad_domains
                 where ad_domains.domain = ad_integrity_checks.domain);

commit;

-- add primary key and foreign key constraints
alter table ad_integrity_checks add (primary key(integrity_check_id));

alter table ad_integrity_checks add (foreign key(domain_id) references ad_domains(domain_id));

-- add new integer primary key and foreign key for domain_id
-- (no need to drop primary key constraint since there wasn't one)
alter table ad_categories add (
         category_id             integer,
         domain_id integer
);
create sequence ad_category_id_seq start with 1;

-- populate new primary key and foreign key columns
update ad_categories set category_id = ad_category_id_seq.nextval;
update ad_categories
set domain_id = (select domain_id
                 from ad_domains
                 where ad_domains.domain = ad_categories.domain);
commit;

-- add primary key and foreign key constraints for new columns
alter table ad_categories add (primary key(category_id));
alter table ad_categories add (foreign key(domain_id) references ad_domains(domain_id));

-- old ad_categories_unique index referred to 'domain' column;
-- recreate index with new domain_id column
drop index ad_categories_unique;
create unique index ad_categories_unique on ad_categories ( domain_id, primary_category );

-- add new domain_id foreign key to replace 'domain'
alter table classified_ads add (
        domain_id integer
);
-- populate foreign key
update classified_ads
set domain_id = (select domain_id
                 from ad_domains
                 where ad_domains.domain = classified_ads.domain);
commit;

-- add referential integrity constraint for new foreign key
alter table classified_ads add (foreign key(domain_id) references ad_domains(domain_id));
-- and allow old 'domain' column to be null
-- (since we can't just drop the column)
alter table classified_ads modify (domain null);

-- add new domain_id foreign key to replace 'domain'
alter table classified_ads_audit add (
        domain_id integer
);

-- populate new column for old rows
update classified_ads_audit
set domain_id = (select domain_id
                 from ad_domains
                 where ad_domains.domain = classified_ads_audit.domain);
commit;

-- replace this view to change 'domain' column to 'domain_id'
create or replace view classified_context_view as
  select ca.classified_ad_id, ca.domain_id, ca.one_line, ca.expires, ca.one_line || ' ' || ca.full_ad || ' ' || u.email || ' ' || 
u.first_names || ' ' || u.last_name || ' ' || ca.manufacturer || ' ' || ca.model || ' '  as indexed_stuff
from classified_ads ca, users u
where ca.user_id = u.user_id;

-- add new domain_id foreign key to replace 'domain'
alter table classified_auction_bids add (
        bid_id                  integer
);
create sequence classified_auction_bid_id_seq start with 1;

-- populate new bid_id column for old rows
update classified_auction_bids set bid_id = classified_auction_bid_id_seq.nextval;
commit;
-- and add primary key constraint
alter table classified_auction_bids add (primary key(bid_id));

-- add new domain_id foreign key to replace 'domain'
alter table classified_alerts_last_updates add (
        update_id       integer
);

create sequence classified_alerts_l_u_id_seq start with 1;

-- populate new primary key column for old rows
update classified_alerts_last_updates set update_id = classified_alerts_l_u_id_seq.nextval;
commit;
-- and add primary key constraint
alter table classified_alerts_last_updates add (primary key(update_id));

-- add new integer primary key and foreign key columns
alter table classified_email_alerts add (
        alert_id        integer,
        domain_id       integer
);
create sequence classified_email_alert_id_seq start with 1;

-- populate primary key and foreign key columns for old rows
update classified_email_alerts set alert_id = classified_email_alert_id_seq.nextval;
update classified_email_alerts set domain_id = (select domain_id from ad_domains where ad_domains.domain = classified_email_alerts.domain);
commit;

-- add in primary key and foreign key constraints
alter table classified_email_alerts add (primary key(alert_id));
alter table classified_email_alerts add (foreign key(domain_id) references ad_domains(domain_id));
alter table classified_email_alerts modify (domain null);

-- END CLASSIFIEDS UPGRADE ----------------------------------------

-- BEGIN CALENDAR --

-- add extra user_id column to calendar_categories
alter table calendar_categories add(user_id references users);
alter table calendar_categories drop constraint calendar_category_scope_check;
alter table calendar_categories add constraint
calendar_category_scope_check check ((scope='group' and group_id is not
null) or (scope='user' and user_id is not null) or (scope='public'));
alter table calendar_categories drop constraint calendar_category_unique_check;
alter table calendar_categories add constraint
calendar_category_unique_check unique(scope, category, group_id, user_id);

-- END CALENDAR UPGRADE -------------------------------------------


------------------------------------------------------------
-- SURVEY MODULE is all new
------------------------------------------------------------

@survey-simple


------------------------------------------------------------
-- PULL-DOWN MENUS are all new
------------------------------------------------------------

@pull-down-menus
@pull-down-menu-data


-----------------------------------------------------------
-- Education module is  all new 
-----------------------------------------------------------


insert into portal_tables (table_id, table_name, adp, admin_url, creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval, 'Stock Quotes', '<% set html [DisplayStockQuotes $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp, admin_url,
creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Current Weather', '<% set html [DisplayWeather $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp,
admin_url,creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Classes', '<% set html [GetClassHomepages $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp,
admin_url,creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Announcements', '<% set html [GetNewsItems $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp,
admin_url,creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Calendar', '<% set html [edu_calendar_for_portal $db]%><%= $html%>', '', 1, sysdate);

@education

-------------------------------------------------------------
-- Table metadata needed for general permissions
-------------------------------------------------------------

@table-metadata
