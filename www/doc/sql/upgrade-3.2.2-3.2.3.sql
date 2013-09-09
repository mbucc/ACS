--
-- /www/doc/upgrade-3.2.2-3.3.3.sql
--
-- Script to upgrade an ACS 3.2.2 database to 3.3.3
--
-- upgrade-3.2.2-3.2.3.sql,v 3.3 2000/07/07 23:34:47 ron Exp
--

-- BEGIN DOWNLOAD --

alter table download_rules add 
	availability	varchar(30) check (availability in
			   ('all', 'registered_users', 'purchasers',
   			    'group_members', 'previous_purchasers'));

update download_rules set availability = 'registered_users';

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

-- END DOWNLOAD --
