-- ArsDigita Community System data model
-- by philg@mit.edu

-- as distributed, this will load into a user's default tablespace in
-- Oracle; you'll get substantially higher transaction performance if
-- you put certain tables or their indices into tablespaces that are
-- on separate physical disk drives.  Search for "****" for things 
-- that I (philg) think are good candidates.  Generally there will 
-- be a commented-out directive to park something in a photonet tablespace
-- you can comment these back in and change the tablespace name to something
-- that is meaningful on your system

-- first we define tables that store information about other tables
-- (our own private data dictionary).  We could use the NS2_TABLES
-- table to store this info if we wanted to tie ourselves even
-- more to AOLserver, but we don't so we have our own table (also
-- might make it easier to JOIN)

-- TABLE_ACS_PROPERTIES is used for user profiling, site-wide search,
-- and general comments

create table table_acs_properties (
             table_name      		varchar(30) primary key,
             section_name    		varchar(100) not null,
             user_url_stub   		varchar(200) not null,
             admin_url_stub  		varchar(200) not null,
	     module_key      		references acs_modules,
	     -- we need to keep group_public_file and group_admin_file to support url's
	     -- of items belonging to the groups. there are better ways of doing this but this way
	     -- was chosen because of compatibility issues with previous acs releases. 
	     group_public_file          varchar(200),
	     group_admin_file           varchar(200)
);

-- only the US states (and random territories such as Guam)

-- no need to define these; the /install/*.dmp files
-- create them when you import (you must do that first)

-- create table states (
-- 	usps_abbrev	char(2) not null primary key,
-- 	fips_state_code char(2),
-- 	state_name	varchar(25)
-- );

-- create table country_codes (
-- 	iso		char(2) not null primary key,
-- 	country_name	varchar(150)
-- );

-- create table counties (
-- 	fips_county_code	 varchar(5) not null primary key,
-- 	fips_county_name	 varchar(35) not null,
-- 	fips_state_code		 varchar(2) not null,
-- 	usps_abbrev		 varchar(2) not null,
-- 	state_name		 varchar(50) not null
-- );

-- create table currency_codes (
--	iso		char(3) primary key,
--	currency_name	varchar(200)
--);

-- populating counties from the Scorecard rel_search_co table:
-- insert into counties
-- (fips_county_code, fips_county_name, fips_state_code, usps_abbrev, state_name)
-- select fips_county_code, fips_county_name, fips_state_code, state, state_name from rel_search_co;

create sequence user_id_sequence start with 1;

-- in general, users can't be deleted because of integrity constraints
-- on content they've contributed; we can pseudo-delete them by setting 
-- deleted_p to 't'; at this point there is the question of what to do 
-- if/when they reappear on the site.  If they deleted themselves 
-- then presumably we let them re-enable their registration.  If they
-- were banned by the administration then we have to play dead or inform 
-- them of that fact.

create table users (
	user_id			integer not null primary key,
	first_names		varchar(100) not null,
	last_name		varchar(100) not null,
	screen_name		varchar(100),
	constraint users_screen_name_unique unique(screen_name),
	priv_name		integer default 0,
	email			varchar(100) not null unique,
	priv_email		integer default 5,
	email_bouncing_p	char(1) default 'f' check(email_bouncing_p in ('t','f')),
	-- converted_p means password is bogus; we imported this guy
	-- from a system where we only had email address
	converted_p		char(1) default 'f' check(converted_p in ('t','f')),
	password		varchar(30) not null,
	-- we put homepage_url here so that we can
	-- always make names hyperlinks without having to 
	-- JOIN to users_contact
	url			varchar(200),
	-- to suppress email alerts
	on_vacation_until	date,
	-- set when user reappears at site
	last_visit		date,
	-- this is what most pages query against (since the above column
	-- will only be a few minutes old for most pages in a session)
	second_to_last_visit	date,
	-- how many times this person has visited
	n_sessions		integer default 1,
	registration_date	date,
	registration_ip		varchar(50),
	-- state the user is in in the registration process
	user_state		varchar(100) check(user_state in ('need_email_verification_and_admin_approv', 'need_admin_approv', 'need_email_verification', 'rejected', 'authorized', 'banned', 'deleted')),
	-- admin approval system
        approved_date           date,
        approving_user          references users(user_id),
	approving_note       	varchar(4000),
	-- email verification system
	email_verified_date      date,
	-- used if the user rejected before they reach 
	-- the authorized state
	rejected_date		date,
	rejecting_user		integer references users(user_id),
	rejecting_note          varchar(4000),
	-- user was active but is now deleted from the system 
	-- may be revived
	deleted_date		date,	
	deleting_user   	integer references users(user_id),
	deleting_note          varchar(4000),
	-- user was active and now not allowed into the system
	banned_date		date,
	-- who and why this person was banned
	banning_user		references users(user_id),
	banning_note		varchar(4000),
	-- customer relationship manager fields
	crm_state		varchar(50), -- forward reference: references crm_user_states,
	crm_state_entered_date	date, -- when the current state was entered
	-- portrait (esp. useful for corporate intranets)
	portrait		blob,
	portrait_upload_date	date,
	-- not a caption but background info
	portrait_comment	varchar(4000),
	-- file name including extension but not path
	portrait_client_file_name	varchar(500),
	portrait_file_type			varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	portrait_file_extension		varchar(50), 	-- e.g., "jpg"
	portrait_original_width		integer,
	portrait_original_height	integer,
	-- if our server is smart enough (e.g., has ImageMagick loaded)
	-- we'll try to stuff the thumbnail column with something smaller
	portrait_thumbnail		blob,
	portrait_thumbnail_width	integer,
	portrait_thumbnail_height	integer,
	-- so user's can tell us their life story
	bio			varchar(4000)
);

-- we need this to support /shared/whos-online.tcl and /chat 
create index users_by_last_visit on users (last_visit);

-- we need this index to list number of users in given user_state
-- for the admin pages
create index users_user_state on users (user_state);

-- for queries by crm_state
create index users_by_crm_state on users (crm_state);

-- when Oracle 8.1 comes out, build a case-insensitive 
-- functional index
-- create unique index users_email_idx on users(upper(email));



-- records multiple vacations
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
create index user_vacations_dates_idx on user_vacations(start_date, end_date);
create index user_vacations_type_idx on user_vacations(vacation_type);

-- on_vacation_p refers to the vacation_until column of the users table
-- it does not care about user_vacations!
create or replace function on_vacation_p (vacation_until IN date) return CHAR
IS
BEGIN
	IF (vacation_until is not null) AND (vacation_until >= sysdate) THEN
		RETURN 't';
	ELSE
		RETURN 'f';
	END IF;
END;
/
show errors



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



--- users who are not deleted or banned

create or replace view users_active
as
select * 
 from users 
 where user_state = 'authorized';
  
-- users who've signed up in the last 30 days
-- useful for moderators since new users tend to 
-- be the ones who cause trouble

create or replace view users_new
as
select * 
 from users 
 where registration_date > (sysdate - 30);

-- create a system user (to do things like own administrators group)
-- and also create an anonymous user (to own legacy content)
-- we keep their status in special email addresses because these are indexed
-- (constrained unique) and therefore fast to look up 

declare
 n_system_users		integer;
 n_anonymous_users	integer;
begin
 select count(*) into n_system_users from users where email = 'system';
 if n_system_users = 0 then 
   insert into users
    (user_id, first_names, last_name, email, password, user_state)
   values 
    (user_id_sequence.nextval, 'system', 'system', 'system', 'changeme', 'authorized');
 end if;
 -- if moving content from an old system, you might have lots that needs
 -- to be owned by anonymous
 select count(*) into n_anonymous_users from users where email = 'anonymous';
 if n_anonymous_users = 0 then 
   insert into users
    (user_id, first_names, last_name, email, password)
   values 
    (user_id_sequence.nextval, 'anonymous', 'anonymous', 'anonymous', 'changeme');
 end if;
end;
/

create or replace function system_user_id
return integer
as
  v_user_id	integer;
begin
  select user_id into v_user_id from users where email = 'system';
  return v_user_id;
end;
/

create or replace function anonymous_user_id
return integer
as
  v_user_id	integer;
begin
  select user_id into v_user_id from users where email = 'anonymous';
  return v_user_id;
end;
/


create table users_preferences (
	user_id			integer primary key references users,
	prefer_text_only_p	char(1) default 'f' check (prefer_text_only_p in ('t','f')),
	-- an ISO 639 language code (in lowercase)
	language_preference	char(2) default 'en',
	dont_spam_me_p		char(1) default 'f' check (dont_spam_me_p in ('t','f')),
	email_type		varchar(64)
);


---- same as users_alertable but for publisher-initiated correspondence

create or replace view users_spammable
as
select u.*, up.email_type 
 from users u, users_preferences up
 where u.user_id = up.user_id(+)
 and user_state = 'authorized'
 and (email_bouncing_p is null or email_bouncing_p = 'f')
 and (dont_spam_me_p is null or dont_spam_me_p = 'f');



-- there is a bit of redundancy here with users_contact
-- but people may want to do a survey without ever asking
-- users for full addresses

create table users_demographics (
	user_id		   	integer primary key references users,
	birthdate		date,
	priv_birthdate		integer,
	sex			char(1) check (sex in ('m','f')),
	priv_sex		integer,
	postal_code		varchar(80),
	priv_postal_code	integer,
	ha_country_code		char(2) references country_codes(iso),
	priv_country_code	integer,
	affiliation		varchar(40),
	-- these last two have to do with how the person
	-- became a member of the community
	how_acquired		varchar(40),
	-- will be non-NULL if they were referred by another user
	referred_by		integer references users(user_id)
);

create or replace function user_demographics_summary (v_user_id IN integer)
return varchar
as
  demo_row		users_demographics%ROWTYPE;
  age			integer;
  pretty_sex		varchar(20);
begin
  select * into demo_row from users_demographics where user_id = v_user_id;
  age := round(months_between(sysdate,demo_row.birthdate)/12.0);
  IF demo_row.sex = 'm' THEN
    pretty_sex := 'man';
  ELSIF demo_row.sex = 'f' THEN
    pretty_sex := 'woman';
  END IF;
  IF pretty_sex is null and age is null THEN
    return null;
  ELSIF pretty_sex is not null and age is null THEN
    return 'a ' || pretty_sex;
  ELSIF pretty_sex is null and age is not null THEN
    return 'a ' || age || '-year-old person of unknown sex';
  ELSE
    return 'a ' || age || '-year-old ' || pretty_sex;
  END IF;
end user_demographics_summary;
/
show errors


-- contact info for users

create table users_contact (
	user_id		integer primary key references users,
	home_phone	varchar(100),
	priv_home_phone	integer,
	work_phone	varchar(100),
	priv_work_phone	integer,
	cell_phone	varchar(100),
	priv_cell_phone	integer,
	pager		varchar(100),
	priv_pager	integer,
	fax		varchar(100),
	priv_fax	integer,
	-- to facilitate users talking to each other and Web server
	-- sending instant messages, we keep the AOL Instant Messenger 
	-- screen name
	aim_screen_name		varchar(50),
	priv_aim_screen_name	integer,
	-- also the ICQ# (they have multi-user chat)
	-- currently this is probably only a 32-bit integer but
	-- let's give them 50 chars anyway
	icq_number		varchar(50),
	priv_icq_number		integer,
	-- Which address should we mail to?
	m_address		char(1) check (m_address in ('w','h')),
	-- home address
	ha_line1		varchar(80),
	ha_line2		varchar(80),
	ha_city			varchar(80),
	ha_state		varchar(80),
	ha_postal_code		varchar(80),
	ha_country_code		char(2) references country_codes(iso),
	priv_ha			integer,
	-- work address
	wa_line1		varchar(80),
	wa_line2		varchar(80),
	wa_city			varchar(80),
	wa_state		varchar(80),
	wa_postal_code		varchar(80),
	wa_country_code		char(2) references country_codes(iso),
	priv_wa			integer,
	-- used by the intranet module
        note			varchar(4000),
        current_information	varchar(4000)
);

create or replace function user_contact_summary (v_user_id IN integer)
return varchar
as
  contact_row		users_contact%ROWTYPE;
begin
  select * into contact_row from users_contact where user_id = v_user_id;
  IF contact_row.m_address = 'w' THEN
    -- they prefer to receive mail at work
    return contact_row.wa_line1 || ' ' || contact_row.wa_line2 || ' ' || contact_row.wa_city || ', ' || contact_row.wa_state || contact_row.wa_postal_code || ' ' || contact_row.wa_country_code;
  ELSE
    return contact_row.ha_line1 || ' ' || contact_row.ha_line2 || ' ' || contact_row.ha_city || ', ' || contact_row.ha_state || contact_row.ha_postal_code || ' ' || contact_row.ha_country_code;
  END IF; 
end user_contact_summary;
/
show errors


-- a table for keeping track of a "commitment" requirement for
-- users. This means that we can require that a user give a real
-- address, a birthdate, etc... because we think that this user
-- needs to commit more to the community.

create table user_requirements (
	user_id			integer primary key references users,
	demographics		char(1) default 'f' check (demographics in ('t','f')),
	contacts		char(1) default 'f' check (contacts in ('t','f'))
);	

-- a PL/SQL function to make life easier, and to abstract out a 
-- bit the requirements of this data model
create or replace function user_fulfills_requirements_p(uid in integer) return char
AS
	requirements	user_requirements%ROWTYPE;
	count_result	integer;
begin
	select count(*) INTO count_result from user_requirements where user_id=uid;
	IF count_result=0
	THEN RETURN 't';
	END IF;

	select * INTO requirements from user_requirements where user_id=uid;
	
	select count(*) INTO count_result from users_demographics where user_id=uid;

	IF requirements.demographics='t' AND count_result=0 THEN
		RETURN 'f';
	END IF;

	select count(*) INTO count_result from users_contact where user_id=uid;

	IF requirements.contacts='t' AND count_result=0 THEN
		RETURN 'f';
	END IF;

	RETURN 't';
	
end user_fulfills_requirements_p;
/
show errors 

-- we use these for categorizing content, registering user interest
-- in particular areas, organizing archived Q&A threads
-- we also may use this as a mailing list to keep users up
-- to date with what goes on at the site

create sequence category_id_sequence start with 1;

create table categories (
	category_id	integer not null primary key,
	category	varchar(50) not null,
	category_description    varchar(4000),
	-- e.g., for a travel site, 'country', or 'activity' 
	-- could also be 'language'
	category_type	varchar(50),
	-- language probably would weight higher than activity 
	profiling_weight	number default 1 check(profiling_weight >= 0),
	enabled_p	char(1) default 't' check(enabled_p in ('t','f')),
	mailing_list_info	varchar(4000)
);

-- optional system to put categories in a hierarchy 
-- (see /doc/user-profiling.html)

-- we use a UNIQUE constraint instead of PRIMARY key 
-- because we use rows with NULL parent_category_id to 
-- signify the top-level categories

create table category_hierarchy (
   parent_category_id     integer references categories,
   child_category_id      integer references categories,
   unique (parent_category_id, child_category_id)
);

create sequence site_wide_cat_map_id_seq;

-- this table can represent "item X is related to category Y" for any
-- item in the ACS; see /doc/user-profiling.html for examples

create table site_wide_category_map (
             map_id                  integer primary key,
	     category_id             not null references categories,
	     -- We are mapping a category in the categories table
	     -- to another row in the database.  Which table contains
	     -- the row?
             on_which_table          varchar(30) not null,
	     -- What is the primary key of the item we are mapping to?
	     -- With the bboard this is a varchar so we can't make this
	     -- and integer
             on_what_id              varchar(500) not null,
	     mapping_date	     date not null,
	     -- how strong is this relationship?
	     -- (we can even map anti-relationships with negative numbers)
	     mapping_weight          integer default 5 
				     check(mapping_weight between -10 and 10),
	     -- A short description of the item we are mapping
	     -- this enables us to avoid joining with every table
	     -- in the ACS when looking for the most relevant content 
	     -- to a users' interests
	     -- (maintain one_line_item_desc with triggers.)
             one_line_item_desc      varchar(200) not null,
	     mapping_comment         varchar(200),
	     -- only map a category to an item once
             unique(category_id, on_which_table, on_what_id)
);

create index swcm_which_table_what_id_idx on site_wide_category_map (on_which_table, on_what_id);

-- a place to record which users care about what

create table users_interests (
	user_id		integer not null references users,
	category_id	integer not null references categories,
	-- 0 is same as NULL, -10 is "hate this kind of stuff" 
	-- 5 is "said I liked it", 10 is "love this kind of stuff"
	interest_level	integer default 5 check(interest_level between -10 and 10),
	interest_date	date,
	unique(user_id, category_id)
);

-- a place to record which items of content are related to which
-- categories (this can be used in conjunction with any table
-- system-wide)

create sequence page_id_sequence start with 1;
create table static_pages (
	page_id		integer not null primary key,
	url_stub	varchar(400) not null unique,
	original_author	integer references users(user_id),
	-- generally PAGE_TITLE will be whatever was inside HTML TITLE tag
	page_title	varchar(4000),
	-- the dreaded CLOB data type (bleah)
	page_body	clob,
	draft_p		char(1) default 'f' check (draft_p in ('t','f')),
	-- for a page that is no longer in the file system, but we 
	-- don't actually delete it from the database because of 
	-- integrity constraints
	obsolete_p	char(1) default 'f' check (obsolete_p in ('t','f')),
	-- force people to register before viewing?
	members_only_p	char(1) default 'f' check (members_only_p in ('t','f')),
	-- if we want to charge (or pay) readers for viewing this
	price		number,
	-- for deviations from site-default copyright policy
	copyright_info	varchar(4000),
	-- whether or not this page accepts reader contributions
	accept_comments_p	char(1) default 't' check (accept_comments_p in ('t','f')),
	accept_links_p		char(1) default 't' check (accept_links_p in ('t','f')),
	-- do we display comments on the same page?
	inline_comments_p	char(1) default 't' check (inline_comments_p in ('t','f')),
	inline_links_p	char(1) default 't' check (inline_links_p in ('t','f')),
	-- include in site-wide index?
	index_p		char(1) default 't' check (index_p in ('t','f')),
	index_decision_made_by	varchar(30) default 'robot' check(index_decision_made_by in ('human', 'robot')),
	-- for sites with fancy navigation, do we want this page to have a menu?
	menu_p			char(1) default 't'  check (menu_p in ('t','f')),
	-- if the menu has an "uplevel" link and it should
	-- not go to the directory defaults, what the link should be
	uplink			varchar(200),
	-- filesize in bytes
	file_size		integer,
	-- determined by the unix file system
	last_updated		date,
	-- used to prevent minor changes from looking like new content
	publish_date		date
);

-- if a page has been authored by one or more users, then 
-- there are rows here (this serves for both credit and update
-- permission)
-- 
-- also keep track of whether author wants to get email 
-- notifications of new comments, links, etc.
-- (this information will also be available in a summary Web page
--  when author logs in)

create table static_page_authors (
	page_id		integer not null references static_pages,
	user_id		integer not null references users,
	notify_p	char(1) default 't' check (notify_p in ('t','f')),
	unique(page_id,user_id)
);


-- patterns for exclusion from index of static pages
-- these match either the URLs, page titles, or page_body
-- (the last one is tricky because it is a CLOB and LIKE doesn't 
--  work; let's not implement this for now :-( )

-- all matching is done lowercased (e.g., the patterns should be
-- in lower case)

create sequence static_page_index_excl_seq;

create table static_page_index_exclusion (
	exclusion_pattern_id	integer primary key,
	match_field		varchar(30) default 'url_stub' not null check(match_field in ('url_stub', 'page_title', 'page_body')),
	like_or_regexp		varchar(30) default 'like' not null check(like_or_regexp in ('like', 'regexp')),
	pattern			varchar(4000) not null,
	pattern_comment		varchar(4000),
	creation_user		not null references users,
	creation_date		date default sysdate not null 
);

-- comment_type is generally one of the following:
--   alternative_perspective
--   private_message_to_page_authors 
--   rating
--   unanswered_question
-- if an administrator had to delete a comment, deleted_p will be 't'


create sequence comment_id_sequence start with 1;

create table comments (
	comment_id	integer  primary key,
	page_id		integer not null references static_pages,
	user_id		integer not null references users,
	comment_type	varchar(30),
	message		clob,
	html_p		char(1) check (html_p in ('t','f')),
	-- null unless comment_type is 'rating'
	rating		integer check (rating >= 0 and rating <= 10),
	originating_ip	varchar(50),
	posting_time	date,
	deleted_p	char(1) default 'f' check (deleted_p in ('t','f')),
	-- columns useful for attachments, column names
	-- lifted from general_comments
	-- this is where the actual content is stored
	attachment		blob,
	-- file name including extension but not path
	client_file_name	varchar(500),
	file_type		varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	file_extension		varchar(50), 	-- e.g., "jpg"
	-- fields that only make sense if this is an image
	caption			varchar(4000),
	original_width		integer,
	original_height		integer
);

create index comments_by_page_idx on comments(page_id);
create index comments_by_user_idx on comments(user_id);

create view comments_not_deleted 
as 
select * 
from comments 
where deleted_p is null
or deleted_p = 'f';

-- user-contributed links (a micro-Yahoo)


create table links (
	page_id		integer not null references static_pages,
	user_id		integer not null references users,
	url		varchar(300) not null,
	link_title	varchar(100) not null,
	link_description	varchar(4000),
	-- contact if link is dead?
	contact_p	char(1) default 't' check (contact_p in ('t','f')),
	status		varchar(10) default 'live' check (status in ('live','coma','dead','removed')),
	originating_ip	varchar(50),
	posting_time	date,
	-- last time this got checked 
	checked_date	date,
	unique(page_id,url)
);

--
-- we store glob patterns (like REGEXP but simpler)
-- of URLs that we don't want to see added
--
-- page_id = NULL means "applies to all pages on the site"
--

create table link_kill_patterns (
	page_id		integer references static_pages,
	-- who added the kill pattern
	user_id		integer not null references users,
	date_added	date,
	glob_pattern	varchar(500) not null
);

--- which pages has a user read
--- we'll do this index-only to save space and time
--- **** good table to put in another tablespace
---  (add "tablespace photonet_index" AFTER the organization directive;
---   Oracle doesn't believe in commutivity)

create table user_content_map (
	user_id		integer not null references users,
	page_id		integer not null references static_pages,
	view_time	date not null,
	primary key(user_id, page_id))
organization index;


-- referers (people who came in from external references)

create table referer_log (
	-- relative to the PageRoot, includes the leading /
	local_url	varchar(250) not null,
	-- full URL on the foreign server, including http://
	foreign_url	varchar(250) not null,
	entry_date	date not null,	-- we count referrals per day
	click_count	integer default 0,
	primary key ( local_url, foreign_url, entry_date)
);

-- the primary key constraint above will make it really fast to get to
-- the one relevant row

-- let's also try to make it fast for quick daily reports

create index referer_log_date_idx on referer_log (entry_date);  -- **** tablespace photonet_index


-- Tcl GLOB patterns that lump referrer headers together,
-- particularly useful for search engines (i.e., we don't want
-- every referral from AltaVista logged separately).

create table referer_log_glob_patterns (
	glob_pattern		varchar(250) primary key,
	canonical_foreign_url	varchar(250) not null,
	-- not NULL if this is here for a search engine and 
	-- we're also interested in harvesting query strings
	search_engine_name	varchar(30),
	search_engine_regexp	varchar(200)
);

-- strings entered by users, either on our site-local search engine
-- or at Internet-wide servers

create table query_strings (
	query_date		date not null,
	query_string		varchar(300) not null,
	-- if they came in from a public search engine and we 
	-- picked it from the referer header
	search_engine_name	varchar(30),
	-- subsection of the site from which they were searching
	subsection		varchar(100),
	-- if we know who they are
	user_id		integer references users,
	-- not null if this was a local query
	n_results	integer	
);

-- **** tablespace photonet_index
create index query_strings_by_user on query_strings (user_id);

create index query_strings_by_date on query_strings (query_date);

create index query_strings_by_engine on query_strings (search_engine_name, query_date);

-- stuff to manage email and make sure that we don't keep sending
-- to guys with invalid addresses

-- a bounce is event_type = 'bounce' and content NULL
-- a bboard alert is event_type = 'alert' 

-- this is actually a great candidate for an index-organized table

create table email_log (
	user_id		integer not null references users,
	email_date	date not null,
	event_type	varchar(100) not null,
	content		varchar(4000)
);

-- **** tablespace photonet_index
create index email_log_idx on email_log ( user_id, event_type );

-- can't have local and foreign_urls too long or they won't be
-- indexable in Oracle
-- note that the local URL does NOT include the starting / 

create table clickthrough_log (
	local_url	varchar(400) not null,
	foreign_url	varchar(300) not null,	-- full URL on the foreign server
	entry_date	date,	-- we count referrals per day
	click_count	integer default 0,
	primary key (local_url, foreign_url, entry_date)
);

--- keep track of user sessions
--- we keep the total in "session_count" and the number of repeaters
--  (folks who had a last_visit cookie already set) in repeat_count
--  entry-date is midnight on the day of interest, as with our
--  referer and clickthrough stuff

create table session_statistics (
	session_count	integer default 0 not null,
	repeat_count	integer default 0 not null,
	entry_date	date not null
);



--- dynamic user groupings
create sequence user_class_id_seq;

create table user_classes (
	user_class_id    integer primary key,
	name		 varchar(200) unique,
	description      varchar(4000),
	-- this query was written by our tcl procs, we'll
	-- have an autogenerated description describing what it means.
	sql_description   varchar(1000),
	-- The sql that will follow the select clause.
	-- for example, sql_post_select_list for 'select count(user_id) from
	-- users' would be 'from users'.
	-- We record this fragment instead of the complete sql
	-- query so we can select a count of desired columns as desired.
	sql_post_select    varchar(4000)	
);


-- user_user_bozo_filter table contains information to implement a personalized "bozo filter"
-- any user ( origin_user_id) can restrain any emails from some other user ( target_user_id )
-- this is not group specific


create table user_user_bozo_filter (
	origin_user_id	references users not null,
	target_user_id	references users not null,
	primary key (origin_user_id, target_user_id)
);


