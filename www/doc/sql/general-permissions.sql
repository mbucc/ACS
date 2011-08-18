-- 
-- A general permissions facility 
--
-- created by richardl@arsdigita.com on 7/14/99
-- rewritten by michael@arsdigita.com, yon@arsdigita.com & markc@arsdigita.com, 2000-02-25

create sequence gp_id_sequence start with 1;

create table general_permissions (
	permission_id		integer not null primary key,
	on_what_id		integer not null,
	on_which_table		varchar(30) not null,
        scope           	varchar(20),
	user_id			references users,
	group_id		references user_groups,
	role			varchar(200),
	permission_type		varchar(20) not null,
	check ((scope = 'user' and user_id is not null
                and group_id is null and role is null) or
	       (scope = 'group_role' and user_id is null
                and group_id is not null and role is not null) or
	       (scope = 'group' and user_id is null
                and group_id is not null and role is null) or
	       (scope in ('registered_users', 'all_users')
                and user_id is null
                and group_id is null and role is null)),
	unique (on_what_id, on_which_table,
                scope, user_id, group_id, role, permission_type)
);

-- This trigger normalizes values in the on_which_table column to
-- be all lowercase. This makes it easier to implement a case-
-- insensitive API (since function-based indexes do not seem to
-- work as advertised in Oracle 8.1.5). Just make sure to call
-- LOWER whenever constructing a criterion involving
-- on_which_table.
--
create or replace trigger gp_on_which_table_tr
before insert or update on general_permissions
for each row
begin
 :new.on_which_table := lower(:new.on_which_table);
end gp_on_which_table_tr;
/
show errors

-- This trigger normalizes values in the permission_type column to
-- be all lowercase. This makes it easier to implement a case-
-- insensitive API (since function-based indexes do not seem to
-- work as advertised in Oracle 8.1.5). Just make sure to call
-- LOWER whenever constructing a criterion involving
-- permission_type.
--
create or replace trigger gp_permission_type_tr
before insert or update on general_permissions
for each row
begin
 :new.permission_type := lower(:new.permission_type);
end gp_permission_type_tr;
/
show errors

-- This view makes it simple to fetch a standard set of
-- permission flags (true or false) for arbitrary rows
-- in the database.
--
create or replace view general_permissions_grid
as
select
 p.on_what_id, p.on_which_table,
 p.scope, p.user_id, p.group_id, p.role,
 decode(sum(decode(p.permission_type, 'read', 1, 0)), 0, 'f', 't')
  as read_permission_p,
 decode(sum(decode(p.permission_type, 'comment', 1, 0)), 0, 'f', 't')
  as comment_permission_p,
 decode(sum(decode(p.permission_type, 'write', 1, 0)), 0, 'f', 't')
  as write_permission_p,
 decode(sum(decode(p.permission_type, 'administer', 1, 0)), 0, 'f', 't')
 as administer_permission_p
from general_permissions p
group by
 p.on_what_id, p.on_which_table,
 p.scope, p.user_id, p.group_id, p.role;

create or replace package ad_general_permissions
as
 -- Returns 't' if the specified user has the specified permission on
 -- the specified database row.
 --
 function user_has_row_permission_p (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return char;

 function grant_permission_to_user (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_role (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_group (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_reg_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function grant_permission_to_all_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 procedure revoke_permission (
  v_permission_id	general_permissions.permission_id%TYPE
 );

 function user_permission_id (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function group_role_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function group_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function reg_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 function all_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE;

 procedure copy_permissions (
  v_old_on_what_id	general_permissions.on_what_id%TYPE,
  v_new_on_what_id	general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE,
  v_user_id1		general_permissions.user_id%TYPE,
  v_user_id2		general_permissions.user_id%TYPE
 );
end ad_general_permissions;
/
show errors

create or replace package body ad_general_permissions
as
 function user_has_row_permission_p (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return char
 is
  user_has_row_permission_p char(1) := 'f';
 begin

  -- Return true if the user is a system administrator
  -- or if the permission has been granted to at least one of:
  --
  -- * all users
  -- * registered users if the user is logged in
  -- * the user directly
  -- * a role in a user group that the user plays
  -- * an entire user group of which the user is a member
  --
  select ad_group_member_p(v_user_id, system_administrator_group_id)
  into user_has_row_permission_p
  from dual;

  if user_has_row_permission_p = 'f' then
   select decode(count(*), 0, 'f', 't')
   into user_has_row_permission_p
   from general_permissions gp
   where gp.on_what_id = v_on_what_id
   and gp.on_which_table = lower(v_on_which_table)
   and gp.permission_type = lower(v_permission_type)
   and ((gp.scope = 'all_users')
        or (gp.scope = 'registered_users'
            and v_user_id > 0)
        or (gp.scope = 'group'
            and exists (select 1
                        from user_group_map ugm
                        where ugm.user_id = v_user_id
                        and ugm.group_id = gp.group_id))
        or (gp.scope = 'group_role'
            and exists (select 1
                        from user_group_map ugm
                        where ugm.user_id = v_user_id
                        and ugm.group_id = gp.group_id
                        and ugm.role = gp.role))
        or (gp.scope = 'user'
            and gp.user_id = v_user_id))
   and rownum < 2;
  end if;

  return user_has_row_permission_p;
 end user_has_row_permission_p;

 function grant_permission_to_user (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, user_id, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'user', v_user_id, v_permission_type);

  return v_permission_id;
 end grant_permission_to_user;

 function grant_permission_to_role (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, group_id, role, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'group_role', v_group_id, v_role, v_permission_type);

  return v_permission_id;
 end grant_permission_to_role;

 function grant_permission_to_group (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, group_id, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'group', v_group_id, v_permission_type);

  return v_permission_id;
 end grant_permission_to_group;

 function grant_permission_to_reg_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'registered_users', v_permission_type);

  return v_permission_id;
 end grant_permission_to_reg_users;

 function grant_permission_to_all_users (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select gp_id_sequence.nextval into v_permission_id from dual;

  insert into general_permissions
   (permission_id, on_what_id, on_which_table,
    scope, permission_type)
  values
   (v_permission_id, v_on_what_id, v_on_which_table,
    'all_users', v_permission_type);

  return v_permission_id;
 end grant_permission_to_all_users;

 procedure revoke_permission (
  v_permission_id	general_permissions.permission_id%TYPE
 )
 is
 begin
  delete from general_permissions
  where permission_id = v_permission_id;
 end revoke_permission;

 function user_permission_id (
  v_user_id		general_permissions.user_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'user'
  and user_id = v_user_id
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end user_permission_id;

 function group_role_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_role		general_permissions.role%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'group_role'
  and group_id = v_group_id
  and role = v_role
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end group_role_permission_id;

 function group_permission_id (
  v_group_id		general_permissions.group_id%TYPE,
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'group'
  and group_id = v_group_id
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end group_permission_id;

 function reg_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'registered_users'
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end reg_users_permission_id;

 function all_users_permission_id (
  v_permission_type	general_permissions.permission_type%TYPE,
  v_on_what_id		general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE
 )
 return general_permissions.permission_id%TYPE
 is
  v_permission_id	general_permissions.permission_id%TYPE;
 begin
  select permission_id
  into v_permission_id
  from general_permissions
  where on_what_id = v_on_what_id
  and on_which_table = lower(v_on_which_table)
  and scope = 'all_users'
  and permission_type = lower(v_permission_type);

  return v_permission_id;

 exception when no_data_found then
  return 0;
 end all_users_permission_id;


 procedure copy_permissions (
  v_old_on_what_id	general_permissions.on_what_id%TYPE,
  v_new_on_what_id	general_permissions.on_what_id%TYPE,
  v_on_which_table	general_permissions.on_which_table%TYPE,
  v_user_id1		general_permissions.user_id%TYPE,
  v_user_id2		general_permissions.user_id%TYPE
 )
 is
 begin
  insert into general_permissions
    (permission_id, on_what_id, on_which_table, scope, user_id, 
     group_id, role, permission_type)
  select gp_id_sequence.nextval, v_new_on_what_id, lower(v_on_which_table),
    scope, user_id, group_id, role, permission_type
  from general_permissions
  where on_what_id = v_old_on_what_id and 
    on_which_table = lower(v_on_which_table) and
    (user_id is null or not user_id in (v_user_id1, v_user_id2));
 end copy_permissions;
end ad_general_permissions;
/
show errors

-- This table defines the valid types of permission for each
-- table. Right now, it's only used by the admin pages. We
-- need to figure out if we should use it more broadly.
--
create table general_permission_types (
	table_name	varchar(30) not null,
	permission_type	varchar(20) not null,
	primary key (table_name, permission_type)
);
