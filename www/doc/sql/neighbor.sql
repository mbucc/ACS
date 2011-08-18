--
-- data model for photo.net Neighbor to Neighbor system
-- 
-- philg@mit.edu (Philip Greenspun)
-- created December 22, 1997 
--  (adapted from older Illustra-based system)
-- teadams@mit.edu (Tracy Adams) and philg@mit.edu
-- ported to the commuity system in December 1998
--
-- philg hates to say this, but this system was never elegant to begin'
-- with and now it is really growing hair

-- the original idea was to have several sites running on the same db server
-- (so there was a DOMAIN column).  Then each site would have several 
-- neighbor services, e.g., my personal site could have a "photographic" 
-- category and a "Web servers" category.  Within each category there would
-- be subcategories, e.g., "Camera Shops" for "photographic".

-- like all comprehensive ambitious systems designed and operated by
-- stupid people, neighbor to neighbor never really blossomed.  I ended up 
-- using it at http://photo.net/photo/ with a hardwired domain and a hardwired
-- primary category.  I don't want to break links from all over the 
-- Internet so I can't really change this now.  Thus there will have to 
-- be a default primary_category in the ad.ini file.

-- one good new thing about this port to the ACS: users can comment on
-- neighbor to neighbor postings

create sequence neighbor_sequence start with 50000;

set scan off

-- now we can have an & in a comment and SQL*Plus won't get all hot
-- and bothered

create sequence n_to_n_primary_category_id_seq;

create table n_to_n_primary_categories (
	category_id		integer not null primary key,
	primary_category	varchar(100),
	top_title		varchar(100),
	top_blurb		varchar(4000),
	primary_maintainer_id	not null references users(user_id),
	-- "open", "closed", "wait", just like in ad.ini
	approval_policy		varchar(100),
	-- how much interface to devote to regional options, 
	-- e.g., "new postings by region"
	regional_p		char(1) default 'f' check(regional_p in ('t','f')),
	-- we can do interesting user interface widgets with
	-- "country", "us_state", and "us_county"
	region_type		varchar(100),
	-- e.g., "merchant" for photo.net
	noun_for_about		varchar(100),
	-- a chunk of HTML to go in a table
	decorative_photo	varchar(400),
	-- what to say to people who are contributing a new posting
	pre_post_blurb		varchar(4000),
	-- should this category be shown to users
	active_p		char(1) default 't' check(active_p in ('t','f'))
);


-- information that varies per subcategory, e.g., an addition
-- photo or a regional_p that overrides the primary cat's

-- oftentimes the publisher has static content to wish he or she 
-- would point readers, e.g., "if primary_category = 'photographic' and 
-- subcategory_1 = 'Processing Laboratories' then point readers to 
-- http://photo.net/photo/labs.html; this goes into publisher_hint

create sequence n_to_n_subcategory_id_seq;

create table n_to_n_subcategories (
	subcategory_id		integer not null primary key,
	category_id		not null references n_to_n_primary_categories,
	subcategory_1		varchar(100),
	subcategory_2		varchar(100),
	publisher_hint		varchar(4000),
	regional_p		char(1) default 'f' check(regional_p in ('t','f')),
	-- we can do interesting user interface widgets with
	-- "country", "us_state", and "us_county"
	region_type		varchar(100),
	-- an extra photo to go at the top of the listings
	decorative_photo	varchar(400)
);

create table neighbor_to_neighbor (
	neighbor_to_neighbor_id	integer primary key,
	poster_user_id		not null references users(user_id),
	posted			date not null,
	creation_ip_address	varchar(50) not null,
	expires			date,	-- could be NULL
	category_id		not null references n_to_n_primary_categories,
	subcategory_id		not null references n_to_n_subcategories,
	region			varchar(100),	-- state, for example
	about			varchar(200),	-- merchant name
	title			varchar(200) not null,
	body			clob not null,
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	approved_p	char(1) default 'f' check(approved_p in ('t','f'))
);

-- should be a concatenated index for a real installation with
-- multiple domains

create index neighbor_main_index on neighbor_to_neighbor ( category_id, subcategory_id );

create index neighbor_subcat_index on neighbor_to_neighbor ( subcategory_id );

create index neighbor_by_user on neighbor_to_neighbor ( poster_user_id );


-- audit table (we hold deletions, big changes, here)

create table neighbor_to_neighbor_audit (
	neighbor_to_neighbor_id	integer not null, -- no longer primary key (can have multiple entries)
	audit_entry_time	date,
	poster_user_id	        integer references users(user_id),
	posted			date,
	category_id		integer,
	subcategory_id		integer,
	about			varchar(200),
	title			varchar(200),
	body			clob,
	html_p			char(1)
);

