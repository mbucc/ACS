--
-- data model for on-line calendar (ArsDigita Calendar)
-- 
-- created by brucek@arsdigita.com on September 8, 1998
-- 
-- adapted to ArsDigita Community System on November 20, 1998
-- by philg@mit.edu
--

-- what kinds of events are we interested in

create sequence calendar_category_id_sequence start with 1 ;

create table calendar_categories (
	category_id	integer primary key,
	-- if scope=public, this is a calendar category the whole system
        -- if scope=group, this is a calendar category for a particular group
	-- if scope=user, this is a calendar category for a user   
 	scope           varchar(20) not null,
	group_id	references user_groups,
	user_id		references users,
	category	varchar(100) not null,
	enabled_p	char(1) default 't' check(enabled_p in ('t','f')),
	constraint calendar_category_scope_check check ((scope='group' and group_id is not null) or
							(scope='user' and user_id is not null) or
							(scope='public')),
	constraint calendar_category_unique_check unique(scope, category, group_id, user_id)
);

create index calendar_categories_group_idx on calendar_categories ( group_id );

create sequence calendar_id_sequence start with 1;

create table calendar (
	calendar_id	integer primary key,
	category_id	not null references calendar_categories,
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
