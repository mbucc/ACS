-- /www/doc/sql/download.sql
-- 
-- created by philg@mit.edu on 12/28/99
-- augmented by ahmeds@mit.edu
-- augmented by ron@arsdigita.com 04/10/2000

-- supports a system for keeping track of what .tar files or whatever
-- are available to which users and who has downloaded what
-- e.g., we use this at ArsDigita to keep track of who has downloaded
-- our open-source toolkit (so that we can later spam them with 
-- upgrade notifications)
--
-- download.sql,v 3.6 2000/04/21 05:35:26 ron Exp

create sequence download_id_sequence;

create table downloads (
	download_id		integer primary key,
	-- if scope=public, this is a download for the whole system
        -- if scope=group, this is a download for/from a subcommunity
        scope           varchar(20) not null,
	-- will be NULL if scope=public 
	group_id	references user_groups on delete cascade,
	-- e.g., "Bloatware 2000"
	download_name	varchar(100) not null,
	-- e.g., "bw2000" (valid UNIX directory name)
	directory_name	varchar(100) not null,
	-- primary description of the item
	description		varchar(4000),
	-- is the description in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	-- when the download was created, who created it, etc.
	creation_date		date default sysdate not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
        -- state should be consistent
	constraint download_scope_check check ((scope='group' and group_id is not null) 
                                               or (scope='public'))
);

create index download_group_idx on downloads ( group_id );

create sequence download_version_id_sequence;

create table download_versions (
	version_id		integer primary key,
	download_id		not null references downloads on delete cascade,
	-- when this can go live before the public
	release_date		date not null,
	-- important: this is the file name that will be served up to
	-- the user, e.g. bw2000-1.2.3.tar.gz.  This is completely up
	-- to the administrator since we can't verify the contents of
	-- the downloadable files.
	pseudo_filename		varchar(100) not null,
	-- might be the same for a series of .tar files, we'll serve
	-- the one with the largest version_id
	version		 	varchar(4000),
	version_description	varchar(4000),
	-- is the description in HTML or plain text (the default)
	version_html_p		char(1) default 'f' check(version_html_p in ('t','f')),
	-- status of this version
	status			varchar(30) check (status in ('promote', 'offer_if_asked', 'removed')),
	creation_date		date default sysdate not null ,
	creation_user		references users on delete set null,
	creation_ip_address	varchar(50) not null
);

create sequence download_rule_id_sequence;

create table download_rules (
	rule_id		integer primary key,
	-- one of the following will be not null
	version_id	references download_versions on delete cascade,
	download_id	references downloads on delete cascade,
	-- who is allowed to view the download files?
	visibility	varchar(30) check (visibility in 
	                   ('all', 'registered_users', 'purchasers', 
	                    'group_members', 'previous_purchasers')),
	-- who is allowed to download the files?
	availability	varchar(30) check (availability in 
			   ('all', 'registered_users', 'purchasers',
   			    'group_members', 'previous_purchasers')),
	-- price to purchase or upgrade, typically NULL
	price		number,
	-- currency code to feed to CyberCash or other credit card system
	currency	char(3) default 'USD' references currency_codes,
	constraint download_version_null_check check 
	                (download_id is not null or version_id is not null)
);

-- PL/SQL proc
-- returns 'authorized' if a user can view a file, 'not authorized' otherwise.
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_viewable_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_visibility download_rules.visibility%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select visibility into v_visibility
	from   download_rules
	where  version_id = v_version_id;
	
	if v_visibility = 'all' 
	then	
		return 'authorized';
	elsif v_visibility = 'group_members' then	

		select group_id into v_group_id
		from   downloads d, download_versions dv
		where  dv.version_id  = v_version_id
		and    dv.download_id = d.download_id;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from   user_group_map 
                where  user_id  = v_user_id 
		and    group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from   users 
  	        where  user_id = v_user_id;

		return v_return_value;
	end if; 

     END download_viewable_p;
/
show errors

-- PL/SQL proc
-- returns 'authorized' if a user can download, 'not authorized' if not 
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_authorized_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_availability download_rules.availability%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select availability into v_availability
	from   download_rules
	where  version_id = v_version_id;
	
	if v_availability = 'all' 
	then	
		return 'authorized';
	elsif v_availability = 'group_members' then	

		select group_id into v_group_id
		from   downloads d, download_versions dv
		where  dv.version_id  = v_version_id
		and    dv.download_id = d.download_id;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from   user_group_map 
		where  user_id  = v_user_id 
		and    group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from   users 
		where  user_id = v_user_id;
		
		return v_return_value;
	end if; 

     END download_authorized_p;
/
show errors

-- history 

create sequence download_log_id_sequence;

create table download_log (
	log_id		integer primary key,
	version_id	not null references download_versions on delete cascade,
	-- keep track of who downloaded what
	user_id		references users on delete set null,
	entry_date	date not null,
	ip_address	varchar(50) not null,
	-- keeps track of why people downloaded this particular item
	download_reasons varchar(4000)
);



