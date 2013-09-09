-- This data model is for the ArsDigita AdServer,
-- a module of the ArsDigita Community System
--
-- created by philg@mit.edu, 12/2/98
-- updated by brucek@arsdigita.com 12/23/98
--

create table advs (
	adv_key         varchar(200) primary key,
	-- this is useful for integrating with third-party ad products and services
	local_image_p	char(1) default 't' constraint advs_local_img_p check (local_image_p in ('t','f')),
	-- 't' indicates that target_url contains lots of html and this ad should not get wrapped
	-- in the clickthrough counter.  This is useful for doubleclick, etc. where they've
	-- got javascript and other nonsense wrapping the ad
	track_clickthru_p char(1) default 't' constraint advs_trk_clk_p check (track_clickthru_p in ('t','f')),
	-- a stub, relative to [ns_info pageroot] if local_image_p, or a url if !local_image_p
	adv_filename    varchar(200),
	target_url      varchar(4000)
);

-- **** move the unique index into a separate tablespace
-- constraint adv_log_u unique (adv_key,entry_date) 
-- using index tablespace photonet_index

create table adv_log (
	adv_key         not null references advs,  
	entry_date      date not null,
	display_count   integer default 0,
	click_count     integer default 0,
	unique(adv_key,entry_date)
);

-- for publishers who want to get fancy

create table adv_user_map (
	user_id         not null references users,
	adv_key         not null references advs,
	event_time      date not null,
	-- will generally be 'd' (displayed) 'c' (clicked through)
	event_type      char(1)
);

-- build an index on the user_id column for adv_user_map
create index adv_user_map_idx on adv_user_map(user_id);

-- for publishers who want to get really fancy 

create table adv_categories (
	adv_key         not null references advs,
	category_id     integer not null references categories,
	unique(adv_key, category_id)
);

-- for publishers who want to get extremely fancy

create table adv_keyword_map (
	adv_key		varchar(200),
	keyword		varchar(50),
	unique(adv_key, keyword)
);

-- stuff built on top of the raw ad server layer 

-- this is for publishers who want to rotate ads within a group

create table adv_groups (
	group_key	varchar(30) not null primary key,
	pretty_name	varchar(50),
	-- need to define some rotation methods
	-- sequential: show the ads in the order specified in adv_group_map
	-- least-exposure-first: show the ad the has been shown the least
	-- unseen-then-sequential: show an unseen ad if available, otherwise show the next ad as specified in adv_group_map
	-- unseen-then-least-first: show an unseen ad if available, otherwise show theleast exposed ad
	-- random: show a random ad
	-- keyword: show an ad that best matches the keywords
	rotation_method char(35) default 'sequential' constraint ad_grp_rotation_method check (rotation_method in ('sequential','least-exposure-first', 'unseen-then-sequential', 'unseen-then-least-first', 'random', 'keyword'))
);

create table adv_group_map (
	group_key	not null references adv_groups,
	adv_key		not null references advs,
	-- added to support sequencial rotation (avni 2000-09-21)
	rotation_order	integer,
	-- primary key for this table
	primary key (group_key,adv_key)
);

-- This view is used to select ads for display based on the current days 
-- impression count
create or replace view advs_todays_log AS
SELECT * FROM adv_log WHERE entry_date = TRUNC(sysdate);



