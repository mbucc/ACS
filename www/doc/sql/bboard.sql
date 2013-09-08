--
-- data-model.sql for generic bboard system
-- bashed for Oracle8 12/3/97
-- bashed to run with community data model (users table rather
-- than unauthenticated email/name) by Tracy Adams in the summer of 1998
-- bashed 9/13/98 by philg to run with the Scorecard data model
-- edited on 11/15/98 by philg so that the usgeospatial style
-- of forum, from www.scorecard.org, would be part of the
-- generic community system
-- added active_p to bboard_topics teadams@mit.edu 1/7/98
-- edited by Tracy Adams (teadams@mit.edu) on 2/7/98 to prevent
--   multiple row inserted into msg_id_generator if this file
--   is loaded more than once
--
-- updated by hqm to use numeric sequence vals as primary keys,
-- and to integrate better with ACS user/group model 
-- see /doc/bboard-new.html 
-- hqm@ai.mit.edu 8/99

-- Copyright 1996, 1997 Philip Greenspun (philg@mit.edu)
--

set scan off


--
-- bboard_icons contains all icons available to the unified bboard
-- module. Listed first since bboard_topics references it.
--
CREATE TABLE bboard_icons (
       icon_id			integer NOT NULL PRIMARY KEY,
       -- A short name for the icon (the system will pick a
       -- non-descriptive name if the user doesn't
       icon_name                varchar(25),
       -- Actual filename of the icon.  The path name is in IconDir
       -- under the bboard/unified key in the
       -- parameters/<servername>.ini file 
       icon_file		varchar(250),
       -- The width (in pixels) that the icon will be scaled to
       icon_width		integer,
       -- The height (in pixels) that the icon will be scaled to
       icon_height		integer
);

create sequence icon_id_seq;


create sequence bboard_topic_id_sequence;

create table bboard_topics (
	topic_id	integer not null primary key,
	-- topic name
	topic		varchar(200) unique not null,
	-- read access rights
	-- can be one of any (anonymous), public (any registered user), group
	read_access	varchar(16) default 'any' check (read_access in ('any','public','group')),
	-- write (post new message) access
	-- can be one of (public, group)
	write_access 	varchar(16) default 'public' check (write_access in ('public','group')),
 	users_can_initiate_threads_p	char(1) default 't' check (users_can_initiate_threads_p in ('t','f')),
	backlink	varchar(4000),	-- a URL pointing back to the relevant page
	backlink_title	varchar(4000),	-- what to say for the link back
	blather		varchar(4000),	-- arbitrary HTML text that goes at the top of the page
	-- posting is always restricted to members
	-- is viewing restricted to members or only posting?
	restricted_p	char(1) default 'f' check (restricted_p in ('t','f')),
	primary_maintainer_id	integer not null references users(user_id),
	subject_line_suffix	varchar(40),	-- whether to put something after the subject line, e.g., 'name', 'date'
	notify_of_new_postings_p	char(1) default 't' check (notify_of_new_postings_p in ('t','f')),	-- send email when a message is added?
	pre_post_caveat		varchar(4000),	-- special HTML to encourage user to search elsewhere before posting a new message
	-- 'unmoderated', 'new_threads_by_maintainer', 'new_threads_by_helpers'
	-- 'all_threads_by_maintainer', 'all_threads_by_helpers','answers_only_from_helpers', 'moderated_topics'
	moderation_policy	varchar(40),
	-- used for keeping messages for 50 US states, for example
	-- where each state is a top level posting but not really a 
	-- question
	-- if this isn't NULL then we put in an "about" link
	policy_statement	varchar(4000),
	-- presentation_type  q-and-a (Question and answer format), threads (standard listserve), or ed_com (Question and response pages separated, editiorial language)
	presentation_type	varchar(20) default 'q_and_a' constraint check_presentation_type check(presentation_type in ('q_and_a','threads', 'ed_com', 'usgeospatial')),
	-- stuff just for Q&A  use
	q_and_a_sort_order	varchar(4) default 'asc' not null check (q_and_a_sort_order in ('asc','desc')),
	q_and_a_categorized_p	char(1) default 'f' check (q_and_a_categorized_p in ('t','f')),
	q_and_a_new_days	integer default 7,
	q_and_a_solicit_category_p	char(1) default 't' check (q_and_a_solicit_category_p in ('t','f')),
	q_and_a_cats_user_extensible_p	char(1) default 'f' check (q_and_a_cats_user_extensible_p in ('t','f')),
	-- use the interest level system
	q_and_a_use_interest_level_p 	char(1) default 't' check (q_and_a_use_interest_level_p in ('t','f')),
	-- for popular boards, only show categories for non-new msgs
	q_and_a_show_cats_only_p	char(1) default 'f' check (q_and_a_show_cats_only_p in  ('t','f')),
	-- for things like NE43 memory project and 6.001 pset site 
	-- top level threads can have custom sort keys, e.g., date
	-- of story (rather than date of posting)
	custom_sort_key_p 		char(1) default 'f' check (custom_sort_key_p in  ('t','f')),
	custom_sort_key_name		varchar(50),	-- for display
	-- SQL data type, lowercase, e.g., "date" (ANSI format so that it sorts)
	-- we really only use this for user input validation
	custom_sort_key_type		varchar(20),
	custom_sort_order		varchar(4) default 'asc' not null check (custom_sort_order in ('asc','desc')),
	-- display to user if there aren't message yet
	custom_sort_not_found_text	varchar(4000),
	-- ask user to supply a sort key with new postings
	custom_sort_solicit_p		char(1) default 'f' check (custom_sort_solicit_p in  ('t','f')),
	-- ask user to supply a pretty sort key for display
	-- e.g., "Fall 1997" instead of 9-29-97
	custom_sort_solicit_pretty_p   char(1) default 'f' check (custom_sort_solicit_pretty_p in  ('t','f')),
	custom_sort_pretty_name		varchar(50),	-- for display
	custom_sort_pretty_explanation	varchar(100),	-- why we ask for it
	-- fragment of Tcl code that evaluates to 0 if a sort key is
	-- bad, 1 if OK, assumed to include "$custom_sort_key"
	custom_sort_validation_code	varchar(4000),
	-- for the 2nd round of 6.001 discussion thinking
	category_centric_p		char(1) default 'f' check (category_centric_p in  ('t','f')),
	-- image and file uploading
	uploads_anticipated		varchar(30) check (uploads_anticipated in ('images','files','images_or_files')),
	-- should this forum come up on the user interface?
	active_p			char(1) default 't' check (active_p in ('t','f')),
	group_id			integer references user_groups,
       -- Columns for unified presentation.
       -- default_topic_p is 't' if the web service admin wants that
       -- topic to be a default bboard forum for users
       default_topic_p            varchar(1) default 't' check (default_topic_p in ('t','f')),
       -- the default color set by the web service admin for
       -- displaying topic summary lines for a forum 
       -- in #XXXXXX format (Hexadecimal)
       color			  varchar(7),
       -- the default icon set by the web service admin for displaying
       -- topic summary lines for the forum 
       icon_id			  integer REFERENCES bboard_icons
);


-- useful for maintaining FAQs

create table bboard_q_and_a_categories (
	topic_id	not null references bboard_topics,	
	category	varchar(200) not null
);

-- useful for keeping idiots out of forums, e.g., looking for
-- "aperature" in the photo.net Q&A forum

create table bboard_bozo_patterns (
	topic_id	not null references bboard_topics,
	the_regexp	varchar(200) not null,
	scope		varchar(20) default 'both' 
           check(scope in ('one_line','message','both')),
        message_to_user	varchar(4000),
	creation_date	date not null,
	creation_user 		not null references users(user_id),
	creation_comment	varchar(4000),
	primary key (topic_id, the_regexp)
);

-- **** primary key using index tablespace photonet_index

create table bboard (
	msg_id		char(6) primary key,
	refers_to	char(6),
	topic_id	not null references bboard_topics,
	category	varchar(200),	-- only used for categorized Q&A forums
	originating_ip	varchar(16),	-- stored as string, separated by periods
	user_id		integer not null references users,
	one_line	varchar(700)
			constraint bboard_one_line_nn not null,
	message		clob,
	-- html_p - is the message in html or not
	html_p		char(1) default 'f' check (html_p in ('t','f')),
	posting_time	date,
	expiration_days	integer,	-- optional N days after posting_time to expire
	-- really only used for postings that initiate threads
	interest_level	integer check ( interest_level >= 0 and interest_level <= 10 ),
	sort_key	varchar(700),
	-- only used for weirdo things like NE43 memory project and 
	-- 6.001
	-- if this is a DATE, it has to be an ANSI so that it will
	-- sort lexicographically
	-- I guess we should constraint this to be UNIQUE
	custom_sort_key		varchar(100),
	custom_sort_key_pretty	varchar(100),
	-- stuff for US geospatial forums
	epa_region	integer check(epa_region >= 1 and epa_region <= 10),
	usps_abbrev	references states,
	fips_county_code	references counties,
	zip_code	varchar(5),
        urgent_p        char(1) default 'f' not null check (urgent_p in ('t','f'))
);

-- for all of the following indices: **** tablespace photonet_index

create index bboard_by_user on bboard (user_id);

-- this SORT_KEY index will make fetching single Q&A thread fast
-- but it will only work if sort_key is bashed down to 758 chars
-- (note:  Illustra could trivially have indexed this)

create index bboard_by_sort_key on bboard ( sort_key );

-- we need this to avoid an O(N^2) search for "unanswered questions"
-- (made worse by stupid Illustra's inability to cache after a sequential
-- scan)

-- don't think we need this anymore because we never ask for
-- refers_to without a topic spec (hence the new_questions 
-- concat index will work fine)
-- OOOps *** we do in fact need this for the unanswered questions

create index bboard_index_by_refers_to on bboard ( refers_to );

-- this is designed to make checking for already posted messages faster
-- on a system where not all of the messages are in one TOPIC then
-- this should be a concatenated index on topic, one_line

create index bboard_index_by_one_line on bboard ( one_line );
-- don't need this anymore because "new_questions one works"
-- create index bboard_by_topic on bboard ( topic );

-- let's try to make the very top-level query load faster

create index bboard_for_new_questions on bboard ( topic_id, refers_to, posting_time );

-- let's try to make the "postings in one category" faster

create index bboard_for_one_category on bboard ( topic_id, category, refers_to );

-- you might want this depending on how you think custom sort keys are handled
-- can't have just custom_sort_key unique because then you can't have the 
-- same one for two topics

-- create unique index bboard_index_custom on bboard ( topic_id, custom_sort_key );


-- let's try to make the "first N days" query fast
-- create index bboard_for_top_N on bboard using btree ( topic, refers_to, posting_time );
-- fails: W01P0G:warning: index hint for range variable bboard is unusable

-- takes a sort_key and returns just the six digit root
-- doesn't work as well as you'd think because you can't 
-- GROUP BY a functional result

--create function bboard_root_msg(text) returns char(6)
--as 
--return substring ( $1 from 1 for 6 );

create view bboard_new_answers_helper 
as
select substr(sort_key,1,6) as root_msg_id, topic_id, posting_time from bboard
where refers_to is not null;

create or replace function bboard_uninteresting_p (interest_level IN integer)
return varchar
AS
BEGIN
  IF interest_level < 4 THEN
    return 't';  
  ELSE
    return 'f';
  END IF;
END bboard_uninteresting_p;
/
show errors

--create index bboard_pls_index on bboard using pls
--( one_line, message, email, name );

create table msg_id_generator (
	last_msg_id	char(6)
);


declare
 n_msg_id_generator_seed_rows integer;
begin
 select count(*) into n_msg_id_generator_seed_rows from msg_id_generator where last_msg_id = '000000';
 if n_msg_id_generator_seed_rows = 0 then 
	insert into msg_id_generator(last_msg_id) select ('000000') from dual where 0 = (select count(last_msg_id) from msg_id_generator);
 end if;
end;
/



--
-- an "email me if changed" system
--


create table bboard_email_alerts (
	user_id		integer not null references users,
	topic_id	not null references bboard_topics,
	valid_p	char(1) default 't',	-- we set this to 'f' if we get bounces
	frequency varchar2(30),		-- 'instant', 'daily', 'Monday/Thursday', 'weekly', etc.	
	keywords  varchar2(2000)	-- stuff the user is interested in
);

create index bboard_email_alerts_idx on bboard_email_alerts(user_id);

-- Alert by thread system; obsoletes notify field in bboard table.
create table bboard_thread_email_alerts (
	thread_id	references bboard, -- references msg_id of thread root
	user_id		references users,
	primary key (thread_id, user_id)
);



--
-- this holds the last time we sent out notices and the total
-- number of messages sent (just for fun)
--

-- had to change name of table from 
-- bboard_email_alerts_last_updates

create table bboard_email_alerts_updates (
	weekly	date,
	weekly_total	integer,
	daily	date,
	daily_total	integer,
	monthu	date,
	monthu_total	integer
);

-- need something to initialize this table 

insert into bboard_email_alerts_updates 
(weekly, weekly_total, daily, daily_total, monthu, monthu_total)
values
(sysdate,0,sysdate,0,sysdate,0);


create or replace function bboard_contains (email IN varchar, name IN varchar, one_line IN varchar, message IN clob, space_sep_list_untrimmed IN varchar)
return integer
IS
  space_sep_list        varchar(32000);
  upper_indexed_stuff   varchar(32000);
  -- if you call this var START you get hosed royally
  first_space           integer;
  score                 integer;
BEGIN 
  space_sep_list := upper(ltrim(rtrim(space_sep_list_untrimmed)));
  upper_indexed_stuff := upper(email || name || one_line || dbms_lob.substr(message,30000));
  score := 0;
  IF space_sep_list is null or upper_indexed_stuff is null THEN
    RETURN score;  
  END IF;
  LOOP
   first_space := instr(space_sep_list,' ');
   IF first_space = 0 THEN
     -- one token or maybe end of list
     IF instr(upper_indexed_stuff,space_sep_list) <> 0 THEN
        RETURN score+10;
     END IF;
     RETURN score;
   ELSE
   -- first_space <> 0
     IF instr(upper_indexed_stuff,substr(space_sep_list,1,first_space-1)) <> 0 THEN
        score := score + 10;
     END IF;
   END IF;
    space_sep_list := substr(space_sep_list,first_space+1);
  END LOOP;  
END bboard_contains;
/
show errors

-- for geospatialized forum

-- There must be one row for every state, though we guess that you
-- don't have to use the same 10 EPA regions that we used for
-- Scorecard

-- if you want to use this, feed your database the epa-regions.dmp 
-- file that is in the /install directory

-- create table bboard_epa_regions (
-- 	state_name		varchar(30),
--  	fips_numeric_code	char(2),
-- 	epa_region		integer,
-- 	usps_abbrev		char(2),
--         -- "Great Lakes Region", "Central Region", etc. 
--         -- Not very normalized, but easy.... -jsc
--         description             varchar(50)
-- );

-- for uploading files with bboard postings

-- these are stored in a configurable directory

-- we add photos, Word and Excel documents, etc.
-- file_type is "photo", "spreadsheet", "plaintext"
-- "pdf", "html", "word", "miscbinary", "audio"

-- we only allow one upload per message

create sequence bboard_upload_id_sequence;

create table bboard_uploaded_files (
	bboard_upload_id	integer primary key,
	msg_id			not null unique references bboard,
	file_type		varchar(100),	-- e.g., "photo"
	file_extension		varchar(50), 	-- e.g., "jpg"
	-- can be useful when deciding whether to present all of something
	n_bytes			integer,
	-- what this file was called on the client machine
	client_filename		varchar(4000) not null,
	-- generally the filename will be "*msg_id*-*upload_id*.extension"
	-- where the extension was the originally provided (so 
	-- that ns_guesstype will work)
	filename_stub		varchar(200) not null,
	-- fields that only make sense if this is an image
	caption			varchar(4000),
	-- will be null if the photo was small to begin with
	thumbnail_stub		varchar(200),
	original_width		integer,
	original_height		integer
);

--
-- bboard-unified.sql for unfying the bboard forums
-- 
-- by LuisRodriguez@photo.net
-- Date: May 2000
--


--
-- Map users to their customizable unified set of Forums they want to
-- participate in
--
CREATE TABLE bboard_unified (
       user_id		 	 integer NOT NULL REFERENCES users,
       topic_id			 integer NOT NULL REFERENCES bboard_topics,
       -- default_topic_p is 't' if the user wants that topic to be in
       -- his/her unified bboard view
       default_topic_p           varchar(1) DEFAULT 't' CHECK (default_topic_p IN ('t','f')),
       -- the color used to display topic summary lines for the forum,
       -- in #XXXXXX format (Hexadecimal)
       color			 varchar(7),
       -- the icon used in displaying topic summary lines for the forum
       icon_id			 integer REFERENCES bboard_icons
);


--
-- pl/sql function that performs the tcl function
-- bboard_user_can_view_topic_p declared in /tcl/bboard-defs.tcl
-- returns 'f' if the person is not allowed to view, 't' if he is
--

create or replace function bboard_user_can_view_topic_p ( v_user_id IN integer, v_topic_id IN integer)
return char
IS
	v_read_access varchar(16);
	v_group_id    integer;
	v_count       integer;
BEGIN
	select read_access, group_id into v_read_access, v_group_id
	from bboard_topics
	where topic_id = v_topic_id;

	IF v_read_access = 'any' or v_read_access = 'public' THEN
	   RETURN 't';
	END IF;

	-- now, we know that it's in some group, let's make sure this person is in it
	select count(*) into v_count
	from user_group_map
	where user_id = v_user_id
	and group_id = v_group_id;	

	IF v_count > 0 THEN
	   RETURN 't';
	END IF;
	
	-- if we're up to here, then this person is not allowed to view this page
	RETURN 'f';
	   
END;
/
show errors


create or replace function bboard_user_can_view_msg_p ( v_user_id IN integer, v_msg_id IN varchar)
return char
IS
	v_topic_id	integer;
BEGIN
	select topic_id into v_topic_id
	from bboard
	where msg_id = v_msg_id;

	RETURN bboard_user_can_view_topic_p(v_user_id, v_topic_id);
END;
/
show errors;
