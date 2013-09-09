-- 
-- /www/doc/sql/user-groups.sql
--
-- Author: Philip Greenspun (philg@mit.edu), 11/15/98
--
-- augmented 3/98 by Tracy Adams (teadams@mit.edu) 
-- to handle
--    a) Database-driven roles and action permissions
--    b) Creates group_type "administration" for site and
--       module administration
--    c) Permission system that allows programmers to ask
--       "Can user x do y?"
--
-- user-groups.sql,v 1.5 2000/06/05 21:16:36 ron Exp
--

-- allows administrators and users to set up groups of users
-- and then place users in those groups with roles
-- for example, the groups could be hospitals and then a user
-- could be associated with Hospital X as "physician" and with 
-- Hospital Y as "physician".
--

-- a group type might be 'hospital' or 'cardiac_center'
-- or 'professional_society'

-- we keep group_type short because we will be building tables
-- with group_type as the name, e.g., "hospital_info" will store 
-- the extra information specified in user_group_type_fields
-- for groups of type "hospital"

-- if pretty_name is "Cardiac Center" then pretty_plural
-- is "Cardiac Centers"

-- approval_policy of "open" means users can create groups of 
-- this type and they are immediately live
-- of "closed" means that only admins can create groups of this type
-- of "wait" means that users are offered the option to create 
-- but then an admin must approve

--Change to integer primary key by Kevin Schmidt
create sequence user_group_types_seq;

create table user_group_types (
	user_group_types_id integer primary key,
	group_type 	varchar(20) unique not null,
	pretty_name	varchar(50) not null,
	pretty_plural	varchar(50) not null,
	approval_policy	varchar(30) not null,
	default_new_member_policy	varchar(30) default 'open' not null,
	-- if group_module_administration=full, then group administrators have full control of which modules
	-- they can use (they can add, remove, enable and disable modules)
	-- if group_module_administration=enabling, then group administrators have authority to enable and 
	-- disable modules but cannot add or remove modules
	-- if group_module_administration=none, the group administrators have no control over modules
	-- modules are explicitly set for the user group type by the system administrator 
	group_module_administration	varchar(20),
	-- does this group type support virtual group directories 	
	-- if has_virtual_directory_p is t, then virtual url /$group_type can be used instead of /groups 
	-- to access the groups of this type
	has_virtual_directory_p		char(1) default 'f' check(has_virtual_directory_p in ('t','f')),
	-- if has_virtual_directory_p is t and group_type_public_directory is not null, then files in 
	-- group_type_public_directory will be used instead of files in default /groups directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_type_public_directory     varchar(200),
	-- if has_virtual_directory_p is t and group_type_admin_directory is not null, then files in 
	-- group_type_admin_directory will be used instead of files in default /groups/admin directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_type_admin_directory      varchar(200),
	-- if has_virtual_directory_p is t and group_public_directory is not null, then files in 
	-- group_public_directory will be used instead of files in default /groups/group directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_public_directory          varchar(200),
	-- if has_virtual_directory_p is t and group_admin_directory is not null, then files in 
	-- group_admin_directory will be used instead of files in default /groups/admin/group directory
	-- notice also that these files will be used only when the page is accessed through /$group_type url's
	group_admin_directory           varchar(200)
);

alter table user_group_types add constraint group_type_module_admin_check check (
	(group_module_administration is not null)
	 and (group_module_administration in ('full', 'enabling', 'none')));

-- fields of info that are required for each group type
-- these will be stored in a separate table, called
-- ${group_type}_info (e.g., "hospital_info")

create table user_group_type_fields (
	group_type	not null references user_group_types(group_type),
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
	sort_key		integer not null
);


create sequence user_group_sequence start with 1;
create table user_groups (
	group_id	integer primary key,
	group_type	not null references user_group_types(group_type),
	group_name	varchar(100),
	short_name 	varchar(100) unique not null,
	admin_email 	varchar(100),
	registration_date	date default sysdate not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
	approved_p 	char(1) check (approved_p in ('t','f')),
	active_p	char(1) default 't' check(active_p in ('t','f')),
	existence_public_p	char(1) default 't' check (existence_public_p in ('t','f')),
	new_member_policy	varchar(30) default 'open' not null,
	spam_policy		varchar(30) default 'open' not null,
	constraint user_groups_spam_policy_check check(spam_policy in ('open','closed','wait')),
	-- are the administrators notified of new membership?
	email_alert_p		char(1) default 'f' check (email_alert_p in ('t','f')),
	-- should we use the multi-role based
	multi_role_p	char(1) default 'f' check (multi_role_p in ('t','f')),
	-- can the user group administration control roles and actions?
	-- If f, only site admin pages will have the functionality to modify role-action mappings.  This is a way to "lock in" permission system.
	group_admin_permissions_p   char(1) default 'f' check (group_admin_permissions_p in ('t','f')),
	index_page_enabled_p	char(1) default 'f' check (index_page_enabled_p in ('t','f')),
	-- this is index page content
	body			clob,
	-- html_p for the index page content
	html_p	                char(1) default 'f' check (html_p in ('t','f')),
        -- let's keep track of when these records are modified
        modification_date   date,
        modifying_user      integer references users,
        -- add a parent_group_id to support subgroups
        parent_group_id	references user_groups(group_id)
);

-- index parent_group_id to make parent lookups quick!
create index user_groups_parent_grp_id_idx on user_groups(parent_group_id);


create or replace function user_group_group_type (v_group_id IN user_groups.group_id%TYPE)
     return varchar
     IS
        v_group_type user_group_types.group_type%TYPE;

     BEGIN
	select group_type into v_group_type
	from user_groups
	where group_id=v_group_id;

	return v_group_type;
     END user_group_group_type;
/
show errors

-- this is the helper function for function short_name_from_group_name bellow
create or replace function short_name_from_group_name2
(v_short_name IN user_groups.short_name%TYPE, v_identifier IN integer)
     return varchar
     IS
        v_new_short_name user_groups.short_name%TYPE;

	cursor c1 is select short_name
	from user_groups
	where short_name=v_short_name || decode(v_identifier, 0, '', v_identifier);
     BEGIN
	OPEN c1;
	FETCH c1 into v_new_short_name;

	if c1%NOTFOUND then
	    select v_short_name || decode(v_identifier, 0, '', v_identifier) into v_new_short_name from dual;
	    return v_new_short_name;
        else	
	    return short_name_from_group_name2(v_short_name, v_identifier+1);
	end if;

     END short_name_from_group_name2;
/
show errors

-- this function generates unique short_name from the group_nams
-- v_group_name is the group_name of the group, this function will first transform group_name by making it lower case, 
-- and substituting spaces and underscores with dashes. thus, if group_name is Photographers, the transformed group_name
-- will be photographers. then, this function will keep adding numbers to it until it makes it unique (e.g. if short_names
-- photographers and photographers1 already exist this function will return photographers2)
create or replace function short_name_from_group_name
(v_group_name IN user_groups.group_name%TYPE)
     return varchar
     IS
     BEGIN
	return short_name_from_group_name2(lower(substr(translate(v_group_name, '_ ','--'), 1, 80)), 0);
     END short_name_from_group_name;
/
show errors

-- this procedure sets the short_name of all the groups in the user_group
-- table using short_name_from_group_name function
-- notice that simple update using short_name_from_group_name could not be
-- performed because function short_name_from_group_name is used while
-- user_groups is mutating (ORA-04091)
create or replace procedure generate_short_names_for_group
     IS
        v_group_id user_groups.group_id%TYPE;
	v_group_name user_groups.group_name%TYPE;
	v_short_name user_groups.short_name%TYPE;

	cursor c1 is 
	select group_id, group_name
	from user_groups;
     BEGIN
	OPEN c1;

	LOOP
           FETCH c1 INTO v_group_id, v_group_name;
           EXIT WHEN c1%NOTFOUND;
	
	   v_short_name:= short_name_from_group_name(v_group_name);
	   update user_groups set short_name=v_short_name where group_id=v_group_id;

       END LOOP;
     END generate_short_names_for_group;
/
show errors

create or replace trigger user_group_approved_p_tr
before insert on user_groups
for each row
declare
  group_type_row user_group_types%ROWTYPE;
begin
  if :new.approved_p is null then 
    select * into group_type_row from user_group_types ugt 
      where ugt.group_type = :new.group_type;
    if group_type_row.approval_policy = 'open' then
      :new.approved_p := 't';
    else 
      :new.approved_p := 'f';
    end if;
  end if;  
end;
/
show errors

-- role = 'administrator' is magic and lets the person add other
-- members

create table user_group_map (
	group_id 	not null references user_groups,
	user_id		not null references users,
	-- define in this order because we want to 
	-- quickly see if user X belongs to requested group
	-- and/or which groups a user belongs to
	role		varchar(200),
	registration_date	date default sysdate not null,
	-- keep track of who did this and from where
	mapping_user	not null references users(user_id),
	-- store the string, separated by dots, e.g., 18.23.10.101
	-- make it large enough to handle IPv6 (128 bits)
	mapping_ip_address	varchar(50) not null,
	-- this unique constraint permits a user to have multiple
	-- roles for a group, e.g., one person could have the
	-- roles of CEO and CTO for a user group of type 'company'
	-- we use a unique constraint instead of a primary key
	-- because role can be null simple membership in a group
	-- would have null for the role
	unique (group_id, user_id, role)
);

-- holds people who've asked to be in a group but aren't 
-- approved yet

create table user_group_map_queue (
	group_id	integer references user_groups,
	user_id		integer references users,
	ip_address	varchar(50),
	queue_date	date default sysdate,
	primary key (group_id, user_id)
);

-- stores the roles used by each group
-- only meaningful for groups that use a 
-- multi_role permission system

create table user_group_roles (
	group_id	     integer not null references user_groups,
	role		     varchar(200),
	creation_date        date default sysdate not null,
	creation_user        integer not null references users,
	creation_ip_address  varchar(200) not null,
	primary key (group_id, role)
);

-- stores the actions used by each group
-- only used in multi-role mode

create table user_group_actions (
	group_id	     integer not null references user_groups,
	action		     varchar(200),
	creation_date        date default sysdate not null,
	creation_user        integer not null references users,
	creation_ip_address  varchar(200) not null,
	primary key (group_id, action)
);

-- maps roles to allowed actions

create table user_group_action_role_map (
	group_id     		integer not null references user_groups,
	role			varchar(200) not null,
	action			varchar(200) not null,
	creation_date        	date default sysdate not null,
	creation_user        	not null references users,
	creation_ip_address  	varchar(200) not null,
	primary key (group_id, role, action)
);

---MODULE  ADMINISTRATION

-- this table lets you ask "what is the user group that corresponds
-- to a particular module/submodule of the ACS?"

-- module would be something like "classifieds" and submodule
-- would be a classifieds domain; for a bboard, the module would
-- be "bboard" and the submodules individual bboard topics 

-- NOTE: Most tables named grouptype_info are autogenerated
-- This is the one _info table that is created by hand

create table administration_info (
 	group_id	integer not null references user_groups,
	module		varchar(300) not null,
	submodule	varchar(300),
	--- link to the module administration page
	url		varchar(300),
	unique(module, submodule)
);

declare
 n_system_group_types	integer;
begin
 select count(*) into n_system_group_types from user_group_types where group_type = 'administration';
 if n_system_group_types = 0 then 
   insert into user_group_types
     (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration, user_group_types_id)
   values
     ('administration', 'Administration', 'Administration Groups', 'closed', 'closed', 'full', user_group_types_seq.nextval);
   insert into user_group_type_fields
     (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key)
   values
     ('administration', 'module', 'Module', 'text', 'varchar(300)', 'not null', 1);
   insert into user_group_type_fields
     (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key)
   values
     ('administration', 'submodule', 'Submodule', 'text', 'varchar(300)','', 2);
   -- so that we can offer admins links from their workspace 
   insert into user_group_type_fields
     (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key)
   values
     ('administration', 'url', 'URL', 'text', 'varchar(100)','',3);
 end if;
end;
/

-- creates a new group of type "administration"; does nothing if the group is
-- already defined

create or replace procedure administration_group_add (pretty_name IN varchar, v_short_name IN varchar, v_module IN varchar, v_submodule IN varchar, v_multi_role_p IN varchar, v_url IN varchar ) 
IS
  v_group_id	integer;
  n_administration_groups integer;
  v_system_user_id integer; 
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
end;
/
show errors

--- Define an administration group for site wide administration

begin
   administration_group_add ('Site-Wide Administration', 'site_wide', 'site_wide', '', 'f', '/admin/'); 
end;
/

--- returns the group_id of the site_wide administration group

create or replace function system_administrator_group_id
return integer
as
  v_group_id	integer;
begin
  select group_id into v_group_id
   from administration_info
   where module = 'site_wide'
   and submodule is null;
  return v_group_id;
end;
/

---  Add the system user to the site-wide administration group

declare
 v_system_group_id      integer;
 v_system_user_id	integer;
 n_user_id		integer;
begin
   v_system_user_id := system_user_id;
   v_system_group_id := system_administrator_group_id;
   select count(user_id) into n_user_id
from user_group_map 
where user_id = v_system_user_id
and group_id = v_system_group_id;
   if n_user_id = 0 then
	insert into user_group_map
    	(group_id, user_id, role, mapping_user, mapping_ip_address)
   	values 
    	(v_system_group_id, v_system_user_id, 'administrator', v_system_user_id, '0.0.0.0');
   end if;
end;
/

--  Some query functions

create or replace function ad_group_member_p
  (v_user_id	IN user_group_map.user_id%TYPE,
   v_group_id	IN user_group_map.group_id%TYPE)
return char
IS
  ad_group_member_p char(1);
BEGIN
  -- maybe we should check the validity of user_id and group_id;
  -- we're not doing it for now, because it would slow this function
  -- down with 2 extra queries

  select decode(count(*), 0, 'f', 't')
  into ad_group_member_p
  from user_group_map 
  where user_id = v_user_id
  and group_id = v_group_id
  and rownum < 2;

  return ad_group_member_p;
END ad_group_member_p;
/
show errors

create or replace function ad_user_has_role_p
  (v_user_id	IN user_group_map.user_id%TYPE,
   v_group_id	IN user_group_map.group_id%TYPE,
   v_role	IN user_group_map.role%TYPE)
return char
IS
  ad_user_has_role_p char(1);
BEGIN
  -- maybe we should check the validity of user_id and group_id;
  -- we're not doing it for now, because it would slow this function
  -- down with 2 extra queries

  select decode(count(*), 0, 'f', 't')
  into ad_user_has_role_p
  from user_group_map 
  where user_id = v_user_id
  and group_id = v_group_id
  and role = v_role;

  return ad_user_has_role_p;
END ad_user_has_role_p;
/
show errors

create or replace function ad_group_member_admin_role_p
  (v_user_id IN integer, v_group_id IN integer)
return varchar
IS
  n_rows  integer;
BEGIN
  select count(*) into n_rows
   from user_group_map 
   where user_id = v_user_id
   and group_id = v_group_id
   and lower(role) = 'administrator';
  IF n_rows > 0 THEN
    return 't';
  ELSE
    return 'f';
  END IF;
END;
/
show errors

create or replace function ad_admin_group_member_p
  (v_module IN varchar,
   v_submodule IN varchar,
   v_user_id IN integer)
return varchar
IS
  n_rows  integer;
BEGIN
  select count(*) into n_rows
   from user_group_map 
   where user_id = v_user_id
   and group_id in (select group_id from administration_info
                    where (module = v_module and submodule = v_submodule)
                    or module = 'site_wide');
  IF n_rows > 0 THEN
    return 't';
  ELSE
    return 'f';
  END IF;
END;
/
show errors


-- This table records additional fields to be recorded per user who belongs
-- to a group of a particular type.
-- Each field can be associated with a role within a group.  This allows
-- us to present a role-specific set of fields for users to add/edit.
-- If the role field is empty we present the field to all members
-- of the group of specified group_type. aegrumet@arsdigita.com, 2000-03-10
create table user_group_type_member_fields (
	group_type	varchar(20) references user_group_types(group_type),
	role		varchar(200),
	field_name	varchar(200) not null,
	field_type	varchar(20) not null, -- short_text, long_text, boolean, date, etc.
	-- Sort key for display of columns.
	sort_key		integer not null,
        -- We can't make this a primary key since role can be NULL.
	-- The unique constraint creates an index.
	unique (group_type, role, field_name)
);

-- Contains information about fields to gather per user for a user group.
-- Cannot contain a field_name that appears in the
-- user_group_type_member_fields table for the group type this group belongs to.

create table user_group_member_fields (
	group_id	integer references user_groups,
	field_name	varchar(200) not null,
	field_type	varchar(20) not null, -- short_text, long_text, boolean, date, etc.
	sort_key	integer not null,
	primary key (group_id, field_name)
);

-- View that brings together all field information for a user group, from
-- user_group_type_member_fields and user_group_member_fields.
-- We throw in the sort keys prepended by 'a' or 'b' so we can display
-- them in the correct order, with the group type fields first.
create or replace view all_member_fields_for_group as
select group_id, field_name, field_type, 'a' || sort_key as sort_key
from user_group_type_member_fields ugtmf, user_groups ug
where ugtmf.group_type = ug.group_type
union
select group_id, field_name, field_type, 'b' || sort_key as sort_key
from user_group_member_fields;


-- Contains extra field information for a particular user. These fields
-- were defined either in user_group_type_member_fields or 
-- user_group_member_fields
create table user_group_member_field_map (
	group_id	integer references user_groups,
	user_id		integer references users,
	field_name	varchar(200) not null,
	field_value	varchar(4000),
	primary key (group_id, user_id, field_name)
);



-- this table is used when group administrators are not allowed to handle module administration
-- (allow_module_administration_p is set to 0 for this group type)
-- all groups of this group type will have only modules set up for which mapping in this table exists
create sequence group_type_modules_id_sequence start with 1;
create table user_group_type_modules_map (
	group_type_module_id 	integer primary key,	
	group_type 		references user_group_types(group_type) not null,
	module_key		references acs_modules not null
);



-----------------------------------------------------------------------------------------------------------


-- created by ahmeds@mit.edu on Thu Jan 13 21:29:11 EST 2000
--
-- supports a system for spamming members of a user group 
--

-- group_member_email_preferences table retains email preferences of members 
-- that belong to a particular group 

create table group_member_email_preferences (
	group_id		references user_groups not null,
	user_id			references users not null ,
	dont_spam_me_p		char (1) default 'f' check(dont_spam_me_p in ('t','f')),
	primary key (group_id, user_id)  
);


-- group_spam_history table holds the spamming log for this group 

create sequence group_spam_id_sequence  start with 1;

create table group_spam_history (
	spam_id			integer primary key,
	group_id		references user_groups not null,
	sender_id		references users(user_id) not null,
	sender_ip_address	varchar(50) not null,
	from_address		varchar(100),
	subject			varchar(200),
 	body			clob,
	send_to			varchar (50) default 'members',
	creation_date		date not null,
	-- approved_p matters only for spam policy='wait'
	-- approved_p = 't' indicates administrator approved the mail 
	-- approved_p = 'f' indicates administrator disapproved the mail, so it won't be listed for approval again
	-- approved_p = null indicates the mail is not approved/disapproved by the administrator yet 
	approved_p		char(1) default null check (approved_p is null or approved_p in ('t','f')),
	send_date		date,
	-- this holds the number of intended recipients
	n_receivers_intended	integer default 0,
	-- we'll increment this after every successful email
	n_receivers_actual	integer default 0
);


-- This function returns the number of members all of the subgroups of
-- one group_id has. Note that since we made subgroups go 1 level down
-- only, this function only looks for groups whose parent is the specified
-- v_parent_group_id
create or replace function user_groups_number_subgroups (v_group_id IN integer)
return integer
IS
  v_count   integer;
BEGIN
  select count(1) into v_count from user_groups where parent_group_id = v_group_id;
  return v_count;
END;
/
show errors;


-- We need to be able to answer "How many total members are there in all 
-- of my subgroups?" 
create or replace function user_groups_number_submembers (v_parent_group_id IN integer)
return integer
IS
  v_count   integer;
BEGIN
  select count(1) into v_count 
    from user_group_map 
   where group_id in (select group_id 
                        from user_groups 
                       where parent_group_id=v_parent_group_id);
  return v_count;
END;
/
show errors;


-- While doing a connect by, we need to count the number of members in 
-- user_group_map. Since we can't join with a connect by, we create 
-- this function
create or replace function user_groups_number_members (v_group_id IN integer)
return integer
IS
  v_count   integer;
BEGIN
  select count(1) into v_count 
    from user_group_map 
   where group_id=v_group_id;
  return v_count;
END;
/
show errors;


-- easy way to get the user_group from an id. This is important when
-- using connect by in your table and it also makes the code using 
-- user subgroups easier to read (don't have to join an additional
-- user_groups tables). However, it is recommended that you only
-- use this pls function when you have to or when it truly saves you
-- from some heinous coding
create or replace function user_group_name_from_id (v_group_id IN integer)
return varchar
IS
  v_group_name    user_groups.group_name%TYPE;
BEGIN
  if v_group_id is null
     then return '';
  end if;
  
  select group_name into v_group_name from user_groups where group_id = v_group_id;
  return v_group_name;
END;
/
show errors;



-- With subgroups, we needed an easy way to add adminstration groups
-- and tie them to parents
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



-- Adds the specified field_name and field_type to a group with group id v_group_id
-- if the member field already exists for this group, does nothing
-- if v_sort_key is not specified, the member_field will be added with sort_key
--   1 greater than the current max
create or replace procedure user_group_member_field_add (v_group_id   IN integer,
                                                         v_field_name IN varchar, 
                                                         v_field_type IN varchar,
                                                         v_sort_key   IN integer)
IS
  n_groups          integer;
BEGIN
  -- make sure we don't violate the unique constraint of user_groups_member_fields
  select decode(count(1),0,0,1) into n_groups
    from all_member_fields_for_group
   where group_id = v_group_id
     and field_name = v_field_name;

  if n_groups = 0 then 
     -- member_field is new - add it

     insert into user_group_member_fields 
     (group_id, field_name, field_type, sort_key)
     values
     (v_group_id, v_field_name, v_field_type, v_sort_key);

   end if;
end;
/
show errors;



-- function to create new groups of a specified type 
-- This is useful mostly when loading your modules - simply use this 
-- function to create the groups you need
create or replace procedure user_group_add (v_group_type IN varchar,
                                            v_pretty_name IN varchar, 
                                            v_short_name IN varchar,
                                            v_multi_role_p IN varchar)
IS
  n_groups          integer;
  v_system_user_id  integer; 
BEGIN
  -- make sure we don't violate the unique constraint of user_groups.short_name
  select decode(count(1),0,0,1) into n_groups
    from user_groups
   where upper(short_name)=upper(v_short_name);

  if n_groups = 0 then 
     -- call procedure defined in community-core.sql to get system user
     v_system_user_id := system_user_id;
     -- create the actual group
     insert into user_groups 
      (group_id, group_type, short_name, group_name, creation_user, creation_ip_address, approved_p, existence_public_p, new_member_policy, multi_role_p)
      values
      (user_group_sequence.nextval, v_group_type, v_short_name, v_pretty_name, v_system_user_id, '0.0.0.0', 't', 'f', 'closed', v_multi_role_p);
   end if;
end;
/
show errors



-- returns a list of all the groups a user is in, separated by
-- commas
 
create or replace function group_names_of_user (
	v_user_id IN Integer) Return varchar2 IS
	   counter integer;
	   return_string 	varchar(2000);
	CURSOR c_user_groups is
		select group_name
		from user_groups, user_group_map
		where user_groups.group_id = user_group_map.group_id
		and user_group_map.user_id = v_user_id;
BEGIN
	counter := 0;
	for v_group_data in c_user_groups LOOP
		counter := counter + 1;
		if counter = 1 then				
			return_string := v_group_data.group_name;
		else
			return_string := return_string || ', ' || v_group_data.group_name;
		end if;
	End Loop;
	Return return_string;
END;
/
show errors


-- returns a list of all the groups a user is in, separated by
-- commas 
create or replace function group_names_of_user_by_type ( p_user_id IN Integer, p_group_type IN varchar) 
Return varchar2 IS
	   v_counter integer;
	   v_return_string 	varchar(2000);
	CURSOR c_user_groups is
           select group_name
	     from user_groups, user_group_map
	    where user_groups.group_id = user_group_map.group_id
	      and user_groups.group_type = p_group_type
	      and user_group_map.user_id = p_user_id;
BEGIN
	v_counter := 0;
	for v_group_data in c_user_groups LOOP
		v_counter := v_counter + 1;
		if v_counter = 1 then				
			v_return_string := v_group_data.group_name;
		else
			v_return_string := v_return_string || ', ' || v_group_data.group_name;
		end if;
	End Loop;
	Return v_return_string;
END;
/
show errors

