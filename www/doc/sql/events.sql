--
-- data model for events module
-- 
-- re-written by bryanche@arsdigita.com on Feb 02, 2000
-- to support group-based registrations
-- created by bryanche@arsdigita.com on Jan 13, 2000
-- adapted from register.photo.net's chautauqua code

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
   administration_group_add ('Events Administration', 'events', 'events', '', 'f', '/events/admin/'); 
end;
/

-- create a group type of "events"
insert into user_group_types 
(group_type, pretty_name, pretty_plural, approval_policy, group_module_administration, user_group_types_id)
values
('event', 'Event', 'Events', 'closed', 'full', user_group_types_seq.nextval);

create table event_info (
       group_id primary key references user_groups,
	-- the contact person for this event
	contact_user_id	      integer references users
);

insert into user_group_type_fields 
(group_type, column_name, pretty_name, column_type, 
column_actual_type, sort_key)
values
('event', 'contact_user_id', 'Event Contact Person', 'integer', 'integer', 1);

-- can't ever delete an event/activity because it might have been
-- ordered and therefore the row in events_registrations would be hosed
-- so we flag it

create sequence events_activity_id_sequence;

-- the activities
create table events_activities (
	activity_id	integer primary key,
	-- activities are owned by user groups
	group_id	integer references user_groups,
        creator_id      integer not null references users,
	short_name	varchar(100) not null,
	default_price   number default 0 not null,
	currency	char(3) default 'USD',
	description	clob,
        -- Is this activity occurring? If not, we can't assign
        -- any new events to it.
        available_p	char(1) default 't' check (available_p in ('t', 'f')),
        deleted_p	char(1) default 'f' check (deleted_p in ('t', 'f')),
        detail_url 	varchar(256), -- URL for more details
	default_contact_user_id integer references users
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
       -- some contact info for this venue
       fax_number	  varchar(30),
       phone_number	  varchar(30),
       email		  varchar(100),
       needs_reserve_p	  char(1) default 'f' check (needs_reserve_p in ('t', 'f')),
       max_people	  integer,	
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
        max_people	      integer,
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

create index evnt_evnt_idx on events_events(event_id, activity_id, start_time, end_time);

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
-- table will contain a "user_id integer primary key references users" 
-- column

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

-- create default organizer roles for an activity
create sequence events_activity_org_roles_seq start with 1;
create table events_activity_org_roles (
       role_id			integer 
				constraint evnt_act_org_roles_role_id_pk 
				primary key ,
       activity_id		integer 
				constraint evnt_act_role_activity_id_fk 
				references events_activities
				constraint evnt_act_role_activity_id_nn
				not null,  
       role			varchar(200) 
				constraint evnt_act_org_roles_role_nn
				not null,
       responsibilities		clob,
       -- is this a role that we want event registrants to see?
       public_role_p		char(1) default 'f' 
				constraint evnt_act_role_public_role_p
				check (public_role_p in ('t', 'f'))
);

-- create actual organizer roles for each event
create sequence events_event_org_roles_seq start with 1;
create table events_event_organizer_roles (
       role_id			integer 
				constraint evnt_ev_org_roles_role_id_pk 
				primary key,
       event_id			integer 
				constraint evnt_ev_org_roles_event_id_fk 
				references events_events
				constraint evnt_ev_org_roles_event_id_nn
				not null,  
       role			varchar(200) 
				constraint evnt_ev_org_roles_role_nn
				not null,
       responsibilities		clob,
       -- is this a role that we want event registrants to see?
       public_role_p		char(1) default 'f' 
				constraint evnt_ev_roles_public_role_p
				check (public_role_p in ('t', 'f'))
);

create table events_organizers_map (
       user_id			   constraint evnt_org_map_user_id_nn
				   not null
				   constraint evnt_org_map_user_id_fk
				   references users,
       role_id			   integer 
				   constraint evnt_org_map_role_id_nn
				   not null 
				   constraint evnt_org_map_role_id_fk
				   references events_event_organizer_roles,
       constraint events_org_map_pk primary key (user_id, role_id)
);

-- create a view to see event organizer roles and the people in those roles
create or replace view events_organizers 
as
select eor.*, eom.user_id
from events_event_organizer_roles eor, events_organizers_map eom
where eor.role_id=eom.role_id(+);


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

create index evnt_price_idx on events_prices(price_id, event_id);

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
	-- reg_states: pending, shipped, canceled, waiting
	--pending: waiting for approval
	--shipped: registration all set 
	--canceled: registration canceled
	--waiting: registration is wait-listed
	reg_state	varchar(50) not null check (reg_state in ('pending', 'shipped', 'canceled',  'waiting')),
	-- when the registration was made
	reg_date	date,
	-- when the registration was shipped
	shipped_date	date,
	org		varchar(500),
	title_at_org	varchar(500),
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

create index evnt_reg_idx on events_registrations(reg_id, user_id, price_id, reg_state, org, title_at_org);

-- need this index for speeding up /events/admin/order-history-one.tcl
create index users_last_name_idx on users(lower(last_name), last_name, first_names, email, user_id);

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


-- write functions for completely deleting an event (useful for dev/debug)

-- completely deletes a user group.  Follows /admin/ug/group-delete-2.tcl
create or replace procedure delete_user_group(v_group_id integer)
IS
	sql_stmt			varchar(500);
	v_group_type_table		varchar(20);
BEGIN
	delete from user_group_map_queue 
	where group_id = v_group_id;

	delete from user_group_map
	where group_id = v_group_id;

	-- delete from the user group's info table
	select trim(group_type) || '_info' into v_group_type_table
	from user_groups
	where group_id = v_group_id;

	sql_stmt := 'delete from ' || v_group_type_table || 
	' where group_id = :id';
	EXECUTE IMMEDIATE sql_stmt using v_group_id;
	
	delete from user_group_member_fields where group_id = v_group_id;

	delete from user_group_roles where group_id = v_group_id;

	delete from user_group_action_role_map where group_id = v_group_id;

	delete from user_group_actions where group_id = v_group_id;

	delete from content_section_links
	where from_section_id in (select section_id
			      from content_sections
			      where scope='group'
			      and group_id=v_group_id)
	or to_section_id in (select section_id
			      from content_sections
			      where scope='group'
			      and group_id=v_group_id);

        delete from content_files
	       where section_id in (select section_id
                          from content_sections
                          where scope='group'
                          and group_id=v_group_id);

	delete from content_sections
	where scope='group'
	and group_id=v_group_id;

	delete from faqs
	where scope='group'
	and group_id=v_group_id;

	delete from page_logos
	where scope='group'
	and group_id=v_group_id;

	delete from css_simple
	where scope='group'
	and group_id=v_group_id;

	delete from downloads
	where scope='group'
	and group_id=v_group_id;

	delete from user_groups 
	where group_id = v_group_id;
END delete_user_group;
/
show errors;

-- create a function for deleting an event
-- NOTE: this will delete all the event's registrants too!
create or replace procedure events_delete_event (v_event_id IN integer)
     IS 
	sql_stmt		varchar(500);
	i_group_id		integer;

	-- get all the orders for this event
	cursor c1 is
	select distinct r.order_id
	from events_prices p, events_registrations r
	where p.event_id = v_event_id
	and r.price_id = p.price_id;

	-- get all the organizer roles for this event
	cursor c2 is
	select role_id 
	from events_event_organizer_roles
	where event_id = v_event_id;

     BEGIN
	-- delete all the registrations/orders for this event
	FOR e in c1 LOOP
		delete from events_registrations
		where order_id = e.order_id;

		delete from events_orders
		where order_id = e.order_id;
	END LOOP;

	-- delete the event prices for this event
	delete from events_prices
	where event_id = v_event_id;

	-- get the event's group_id
	select group_id into i_group_id
	from events_events
	where event_id = v_event_id;

	-- delete the event's event fields
	delete from events_event_fields
	where event_id = v_event_id;

	-- delete the event's organizers and roles
	FOR f in c2 LOOP
	    -- delete the organizers with this role
	    delete from events_organizers_map
	    where role_id = f.role_id;

	    -- delete this role
	    delete from events_event_organizer_roles
	    where role_id = f.role_id;
	END LOOP;

	-- drop the event_n_info table
	sql_stmt := 'drop table event_' || v_event_id || '_info';
	EXECUTE IMMEDIATE sql_stmt;

	-- delete the event
	delete from events_events
	where event_id = v_event_id;

	-- delete the event's user group
	delete_user_group(i_group_id);

END events_delete_event;
/
show errors;
