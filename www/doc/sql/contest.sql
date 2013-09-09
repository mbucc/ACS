--
-- contest system data model
--
-- created  6/29/97 by Philip Greenspun (philg@mit.edu)
-- modified 1/18/98 by Cotton Seed (cottons@arsdigita.com)
-- modified 11/26/98 by Philip Greenspun to integrate
-- with community data model
-- modified 3/10/00 by Mark Dalrymple (markd@arsdigita.com) to
-- use integer primary keys instead of characters
-- modified 04/14/00 by Malte Sussdorff (malte@arsdigita.com) to
-- add voting from arsdigita.org and naming constraints

create sequence contest_domain_id_sequence;

-- Each contest has it's own domain, where all the information about the contest is stored

create table contest_domains (
	domain_id		integer 
				constraint cd_domain_id_pk 
				not null primary key,
	domain			varchar(21) 
				constraint c_domain_un not null unique,
	-- the unique constraint creates an index for us
	entrants_table_name	varchar(30),
	-- name of the table for the contest (contest_entrants_$domain_id)
	pretty_name		varchar(100) not null,
	-- where the contest starts
	-- This could be a complete URL with http:// or just a small stumb. It will be
	-- the value for the HTML href.
	home_url		varchar(200),
	-- arbitrary HTML text that goes at the top of 
	-- the auto-generated entry form
	blather 		varchar(4000),
	-- where to send users after they enter
	-- (if blank, we use a generated form)
	post_entry_url		varchar(200),
	confirm_entry		varchar(4000),
	maintainer		constraint cd_maintainer_fk
				not null references users(user_id),
	notify_of_additions_p	char(1) default 'f'
				constraint cd_notify_of_addtions_p_ck 
				check (notify_of_additions_p in ('t', 'f')),  -- send email when a person enters
	us_only_p		char(1) default 'f' 
				constraint cd_us_only_p_ck check (us_only_p in ('t', 'f')),
	start_date		date,	-- these are optional
	end_date		date,
	voting_p		char(1) 
				constraint cd_voting_p_ck check(voting_p in ('t','f')),
	multiple_entries_p	char(1)
				constraint cd_m_entries_p_ck check(multiple_entries_p in ('t','f'))
);

-- Contest might need additional information (actually always do) besides the standard values, therefore extra columns information are stored here.

create table contest_extra_columns (
	domain_id		not null
				constraint cec_domain_id_fk references contest_domains,
	column_pretty_name	varchar(200),
	column_actual_name	varchar(200) not null,
	column_type		varchar(200) not null,	-- things like 'boolean' or 'text'
	column_extra_sql	varchar(200),	-- things like 'not null' or 'default 5'
	-- entry form will sort by this column
	sort_column		integer,
	constraint cec_domain_id_actual_name_pk primary key (domain_id, column_actual_name)
);


--
-- every contest will be created with a table named
-- contest_entrants_$domain_id ; this may have lots of extra columns 
-- 
-- here's what a default table and accompaning sequence
-- 
-- create sequence contest_entrants_1_seq;
-- 
-- create table contest_entrants_1 (
-- 	-- we don't care how many times they enter;
-- 	-- we query for "distinct" eventually
-- 	entry_date	date not null,
--	entry_id	integer not null
-- 			constraint contest_e1_entry_id_pk primary key,
-- 	user_id		not null
-- 			constraint contest_e1_user_id_fk references users,
--	status		varchar(30)
-- );
--
-- NOTE: If there is a voting_p is "t", the following column
-- will be added: 
-- alter table  contest_entrants_1 add (
-- 	title	varchar(200)
-- );

-- In here we store the votes. Per entry only one vote is allowed per user.

create table contest_votes (
	user_id		integer not null 
			constraint contest_votes_user_id_fk references users,
	entry_date	date,
	domain_id	integer 
			constraint contest_votes_domain_id_fk references contest_domains,
	entry_id	integer,
	ipaddress	varchar(100),
	integer_vote	integer,
	comments	varchar(4000),
	constraint cv_entry_user_domain_pk primary key (entry_id, user_id, domain_id)
);

