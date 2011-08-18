--
-- Classified Ads data-model.sql
--
-- Created July 12, 1996 by Philip Greenspun (philg@mit.edu)
-- 
-- added auction stuff on December 21, 1996
--
-- converted from Illustra to Oracle January 5, 1998
--
-- edited to run from generic community system users table 
-- (instead of email address/name stored in row) teadams@mit.eud April 2, 1998

-- edited by philg on 11/18/98 to incorporate employment ad fields
-- and also domain_type 

-- edited by teadams@mit.edu on 1/7/98 to add active_p to ad_domains
-- edited by teadams@mit.edu on 2/10/98 to prevent multiple seed inserts into 
--   classified_alerts_last_updates
-- edited by curtisg@arsdigita.com on 3/9/00 to convert primary keys
--   to integers

create table ad_domains (
        domain_id               integer primary key,
	-- short key, e.g., "Jobs"
	domain			varchar(30) unique,
	-- a description for this domain, e.g., "Jobs classifieds" 
	-- or "Job Listings", this is designed to serve as a
	-- hypertext anchor back to the top-level page
	full_noun		varchar(100),
	primary_maintainer_id	integer not null references users(user_id),
	domain_type		varchar(30),	-- e.g., 'employment', 'automotive'
	blurb			varchar(4000),
	blurb_bottom		varchar(4000),
	insert_form_fragments	varchar(4000),
	ad_deletion_blurb	varchar(4000),
	default_expiration_days	integer default 100,
	levels_of_categorization integer default 1,
	user_extensible_cats_p	char(1) default 'f' check(user_extensible_cats_p in ('t','f')),
	wtb_common_p		char(1) default 'f' check(wtb_common_p in ('t','f')),
	auction_p		char(1) default 'f' check(auction_p in ('t','f')),
	geocentric_p 		char(1) default 'f' check(geocentric_p in ('t','f')),
	--should this show up on the user interface?
	active_p			char(1) default 't' check (active_p in ('t','f'))
);
create sequence ad_domain_id_seq start with 1;

-- we test these on inserts or updates to the table
-- with user interface complaints
--- check_code is something that goes into a Tcl If statement

create table ad_integrity_checks (
        integrity_check_id integer primary key,
        domain_id       integer references ad_domains(domain_id),
	check_code	varchar(4000),
	error_message	varchar(4000)
);
create sequence ad_integrity_check_id_seq start with 1;


--
-- We have a lot of redundant info in this
-- (e.g., each primary_category may be represented 50 times)
-- but we query into this with DISTINCT and we memo-ize
-- so we don't care
--
-- the entire user interface is built from this
--

create table ad_categories (
        category_id             integer primary key,
        domain_id               integer references ad_domains(domain_id),
	primary_category	varchar(100),
	subcategory_1		varchar(100),
	subcategory_2		varchar(100),
	ad_placement_blurb	varchar(4000)
);
create sequence ad_category_id_seq start with 1;

-- if we're going to have a system where we only use primary 
-- category then presumably these should be constrained unique
-- we can do that with an index:

create unique index ad_categories_unique on ad_categories ( domain_id, primary_category );

-- old system had about 10,000 ads so far, this way we'll know whether
-- or not an ad was inserted under the Oracle regime

create sequence classified_ad_id_sequence start with 200000;

create table classified_ads (
	classified_ad_id	integer primary key,
	user_id			integer not null references users,
        domain_id               integer not null references ad_domains(domain_id),
	originating_ip		varchar(16),	-- stored as string, separated by periods
	posted			date not null,
	expires			date,
	wanted_p		char(1) default 'f' check(wanted_p in ('t','f')),
	private_p		char(1) default 't' check(private_p in ('t','f')),
	-- if 'f', the reply_to link will not be displayed with the ad
	reply_to_poster_p	char(1) default 't' check(reply_to_poster_p in ('t','f')),
	primary_category	varchar(100),
	subcategory_1		varchar(100),
	subcategory_2		varchar(100),
	manufacturer		varchar(50),	
	model			varchar(50),
	date_produced		date,
	item_size		varchar(100),
	color			varchar(50),
	location		varchar(200),
	us_citizen_p		char(1) default 'f' check(us_citizen_p in ('t','f')),
	one_line		varchar(150),
	full_ad			varchar(3600),
	-- is the ad in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	graphic_url		varchar(200),
	price			number(9,2),
	currency		varchar(50) default 'US dollars',
	auction_p		char(1) default 't' check(auction_p in ('t','f')),
	country			varchar(2),
	state			varchar(30),
	-- when system is used for employment ads (Cognet wanted these)
	employer		varchar(100),
	salary_range		varchar(200),
	last_modified		date
);

create or replace trigger classified_update_last_mod
before insert or update on classified_ads 
for each row
begin
 :new.last_modified :=SYSDATE;
 IF inserting and :new.posted is null THEN
   :new.posted := SYSDATE;
 END IF; 
end classified_update_last_mod;
/
show errors

create index classified_ads_by_primary_cat on classified_ads (primary_category);

create index classified_ads_by_subcat_1 on classified_ads (subcategory_1);

-- for the "remember to update your ads spam"

create index classified_ads_by_email on classified_ads (user_id);

-- the auction system 

create table classified_auction_bids (
        bid_id                  integer primary key,
	classified_ad_id	not null references classified_ads,
	user_id			not null references users,
	bid			number(9,2),
	currency		varchar(100) default 'US dollars',
	bid_time		date,
	location		varchar(100)
);
create sequence classified_auction_bid_id_seq start with 1;

create index classified_auction_bids_index 
on classified_auction_bids (classified_ad_id);


-- audit table (we hold deletions, big changes, here)
-- warning:  this gives SQL*Plus heartburn if typed at the shell

create table classified_ads_audit (
	classified_ad_id	integer,
	user_id			integer,
        domain_id               integer,
	originating_ip		varchar(16),
	posted			date,
	expires			date,
	wanted_p		char(1),
	private_p		char(1),
	reply_to_poster_p	char(1),
	primary_category	varchar(100),
	subcategory_1		varchar(100),
	subcategory_2		varchar(100),
	manufacturer		varchar(50),	
	model			varchar(50),
	date_produced		date,
	item_size		varchar(100),
	color			varchar(50),
	location		varchar(200),
	us_citizen_p		char(1),
	one_line		varchar(150),
	full_ad			varchar(3600),
	html_p			char(1),
	graphic_url		varchar(200),
	price			number(9,2),
	currency		varchar(50),
	auction_p		char(1),
	country			varchar(2),
	state			varchar(30),
	employer		varchar(100),
	salary_range		varchar(200),
	last_modified		date,
	-- from where user edited ad
	audit_ip		varchar(16),
	-- deleted by moderator?
	deleted_by_admin_p	char(1) default 'f' check(deleted_by_admin_p in  ('t','f'))
);

create index classified_ads_audit_idx on classified_ads_audit(classified_ad_id);
create index classified_ads_audit_user_idx on classified_ads_audit(user_id);


-- ConText index stuff 

-- this is also good for sequential scanning with pseudo_contains

create or replace view classified_context_view as
  select ca.classified_ad_id, ca.domain_id, ca.one_line, ca.expires, ca.one_line || ' ' || ca.full_ad || ' ' || u.email || ' ' || u.first_names || ' ' || u.last_name || ' ' || ca.manufacturer || ' ' || ca.model || ' '  as indexed_stuff
from classified_ads ca, users u
where ca.user_id = u.user_id;


-- email alert system

--
-- this holds the last time we sent out notices
--

create table classified_alerts_last_updates (
        update_id       integer primary key,
	weekly	date,
	weekly_total	integer,
	daily	date,
	daily_total	integer,
	monthu	date,
	monthu_total	integer
);

declare
 n_last_update_seed_rows integer;
begin
 select count(*) into n_last_update_seed_rows from classified_alerts_last_updates where weekly = 'sydate' and daily = 'sysdate' and monthu = 'sysdate';
 if n_last_update_seed_rows = 0 then 
	insert into classified_alerts_last_updates (update_id, weekly, weekly_total, daily, daily_total, monthu, monthu_total) values (1, sysdate,0,sysdate,0,sysdate,0);
 end if;
end;
/

create table classified_email_alerts (
        alert_id        integer primary key,
        domain_id       not null references ad_domains(domain_id),
	user_id		not null references users,
	valid_p		char(1) default 't' check(valid_p in ('t','f')),
	expires		date,
	howmuch		varchar(100),	-- 'everything', 'one_line'
	frequency	varchar(100),	-- 'instant', 'daily', 'Monday/Thursday', 'weekly', etc.
	alert_type	varchar(20),	-- 'all', 'category', 'keywords'
	category	varchar(100),
	keywords	varchar(100),
	established	date
);
create sequence classified_email_alert_id_seq start with 1;

create or replace trigger classified_ea_established
before insert on classified_email_alerts
for each row
when (new.established is null)
begin
 :new.established :=SYSDATE;
end;
/
show errors


