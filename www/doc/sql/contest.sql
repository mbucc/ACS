--
-- contest system data model
--
-- created  6/29/97 by Philip Greenspun (philg@mit.edu)
-- modified 1/18/98 by Cotton Seed (cottons@arsdigita.com)
-- modified 11/26/98 by Philip Greenspun to integrate
-- with community data model
-- modified 3/10/00 by Mark Dalrymple (markd@arsdigita.com) to
-- use integer primary keys instead of characters

create sequence contest_domain_id_sequence;

create table contest_domains (
	domain_id		integer not null primary key,
	domain			varchar(21) not null unique,
	-- the unique constraint creates an index for us
	entrants_table_name	varchar(30),
	pretty_name		varchar(100) not null,
	-- where the contest starts
	home_url	varchar(200),
	-- arbitrary HTML text that goes at the top of 
	-- the auto-generated entry form
	blather		varchar(4000),
	-- where to send users after they enter
	-- (if blank, we use a generated form)
	post_entry_url	varchar(200),
	maintainer	not null references users(user_id),
	notify_of_additions_p	char(1) default 'f' check (notify_of_additions_p in ('t', 'f')),  -- send email when a person enters
	us_only_p		char(1) default 'f' check (us_only_p in ('t', 'f')),
	start_date		date,	-- these are optional
	end_date		date
);



create table contest_extra_columns (
	domain_id		not null references contest_domains,
	column_pretty_name	varchar(30),
	column_actual_name	varchar(200) not null,
	column_type		varchar(200) not null,	-- things like 'boolean' or 'text'
	column_extra_sql	varchar(200)	-- things like 'not null' or 'default 5'
);


--
-- every contest will be created with a table named
-- contest_entrants_$domain ; this may have lots of extra columns 
-- 
-- here's what a default table might look like
-- 
-- create table contest_entrants_fpx_of_month (
-- 	-- we don't care how many times they enter;
-- 	-- we query for "distinct" eventually
-- 	entry_date	date,
-- 	user_id		not null references users,
--      answer		varchar(4000)
-- );
--

