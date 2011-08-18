--
-- homepage.sql
-- 
-- created by mobin@mit.edu at Mon Jan 10 21:52:32 EST 2000 42Å∞21'N 71Å∞04'W
-- Usman Y. Mobin
--
-- supports the Homepage system for giving users the ability to publish 
-- personal web content within a larger community.
-- the public content actually appears in /users/ 
-- should some of the maintenance pages appear at /homepage/ ?
-- the site-wide admin pages are at /admin/homepage/
-- no group admin pages

-- be explicit about 
--   1) does more than one user ever get to maintain a  particular set  of 
--	content? e.g., can they collaborate with another user? Not really. 
--	One user takes responsibility for all of this and maintains it him 
--	or herself. However, a user can authorize one or more other  users 
--	to be helpers. These  people can  be "HTML  programmers" that  are 
--	friends of the user but their email address will  never appear  as 
--	signatory. This is different from group-maintained content where a 
--	group of users is authorized to maintain but the  group signs  and 
--	takes collective responsiblity.
--
--   2) what if a site gets really large and the primary purpose is giving 
--	members personal homepages (e.g., if an adopter of ACS decides  to 
--	become "The GeoCities of Brazil")? How do we support this?  First, 
--	users could decide to  join user  groups. Then  the /users/  index 
--	page  would  show  a  summary of  user groups  whose members  have 
--	personal  pages.  This requires  no new  data in  Oracle. This  is 
--	enabled with SubdivisionByGroupP=1 in  the .ini  file. Users  with 
--	homepages and no group affiliation show up in "unaffiliated"  (fun 
--	with  OUTER  JOIN). When  SubdivisionByNeighborhoodP=1, we  either 
--	keep a denormalized  neighborhood_sortkey in  the homepages  table 
--	and flag the "homepages" that are actually neighborhood folders or 
--	have some separate tables holding categorization.
--    

create sequence users_neighborhood_id_seq start with 2;

create table users_neighborhoods (
	neighborhood_id		integer primary key,
	neighborhood_name	varchar(500) not null,
	description		varchar(4000),
	parent_id		integer references users_neighborhoods on delete cascade
);


-- the system is smart enough to adjust if the root neighborhood
-- has a different neighborhood_id.
insert into users_neighborhoods
(neighborhood_id, 
 neighborhood_name, 
 description, 
 parent_id)
values
(1, 
 'Neighborhoods', 
 'Neighborhood RootNode', 
 null);


create table users_homepages (
	user_id				primary key references users,
	-- the background colour settings for user's public pages
	bgcolor	 			varchar(40),
	-- the text colour settings for user's public pages
	textcolor			varchar(40),
	-- the colour settings for unvisitied links in user's public pages
	unvisited_link	  		varchar(40),
	-- the colour settings for visitied links in user's public pages
	visited_link	  		varchar(40),
	-- the settings to determine whether the links are underlined or
	-- not in user's public pages
	link_text_decoration  		varchar(40),
	-- the settings to determine whether the links are bold or
	-- not in user's public pages. I have added this because I have
	-- strong preference for bold links when they are not underlined.
	link_font_weight		varchar(40),
	-- font for user's public generated pages
	font_type		  	varchar(40),
	-- the background colour settings for user's maintenance pages
	maint_bgcolor	 		varchar(40),
	maint_textcolor			varchar(40),
	maint_unvisited_link		varchar(40),
	maint_visited_link	  	varchar(40),
	maint_link_text_decoration  	varchar(40),
	maint_link_font_weight		varchar(40),
	maint_font_type			varchar(40),
	neighborhood_id		        integer references users_neighborhoods on delete set null
	-- feature_level		varchar(30),
	-- constraint hp_feature_lvl_ck check(feature_level 'platinum', 'gold', 'silver')
	-- keywords			varchar(4000)
);


-- users have their quotas specified by [ad_parameter PrivelegedUserMaxQuota 
-- users] or [ad_parameter  NormalUserMaxQuota users]  depending on  whether 
-- they are site wide administrators or not. However, some users might  have 
-- special quotas which can be granted  by site  wide administrators.  These 
-- quotas are recorded in the users_special_quotas table. If a  user has  an 
-- entry in this table then the above mentioned parameter values are ignored 
-- and instead max_quota is used as his/her quota space.

create table users_special_quotas (
	user_id			integer primary key references users,
	max_quota		number not null,
	modification_date	date default sysdate not null
);


create sequence users_type_id_seq start with 2;

create table users_content_types (
	type_id			integer primary key,
	type_name		varchar(200) not null,
	sub_type_name		varchar(200) not null,
	owner_id		integer not null references users,
	sub_type		integer references users_content_types,
	super_type		integer references users_content_types
);


-- We use this sequence to assign values to file_id. The 
-- reason for starting from 2 is that no file is special 
-- enough to have file_id=1, or is there a file that is?

create sequence users_file_id_seq start with 2;

create table users_files (
	file_id			integer primary key,
	-- the maximum filesize in unix is 255 characters (starting from 1)
	filename		varchar(255) not null,
	directory_p		char(1) default 'f', 
	constraint users_dir_ck check(directory_p in ('t','f')),
	file_pretty_name	varchar(500) not null,
	-- this is the number of bytes the files takes up on the file 
	-- system. We will use these values to determine quota  usage 
	-- except where directory_p is true. In that case, we'll  use 
	-- [ad_parameter DirectorySpaceRequirement users] to see  the 
	-- amount of quota space consumed by a directory. Thus, if we 
	-- magically manage to change the file system,  we dont  have 
	-- to update  file_size for  directories here  because it  is 
	-- irrelevent.
	managed_p		char(1) default 'f' check(managed_p in ('t','f')),
	-- this column is used for files created by the content
	-- publishing system which the user cannot rename or move
	modifyable_p		char(1) default 't' check(modifyable_p in ('t','f')),
	file_size		number not null,
	content_type		references users_content_types,
	-- points to the user_id of the user who owns this file.
	owner_id		integer not null references users,
	-- points to the file_id of the directory which contains 
	-- this file. Useful for supporting hierarchical content 
	-- structure.
	parent_id		integer references users_files
);

create index users_files_idx1 on users_files(file_id, parent_id);

create index users_files_idx2 on users_files(parent_id, file_id);

create index users_files_idx3 on users_files(owner_id);

create sequence users_access_id_sequence start with 2;

create table users_files_access_log (
	access_id		integer primary key,
	file_id			references users_files on delete set null,
	relative_filename	varchar(500) not null,
	owner_id		references users on delete cascade,
	access_date		date not null,
	ip_address		varchar(50) not null
);


create synonym hp for users_files;


------------------------------------------------
-- BEGINNINGOF fileSystemManagement codeBlock --
------------------------------------------------


-- returned value is a filename that does not begin with a slash
create or replace function hp_true_filename (filesystem_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select filename from users_files
		where file_id=filesystem_node;
	CURSOR parent_cursor IS
		select parent_id from users_files
		where file_id=filesystem_node;
	fullname	varchar(500);
	parentid	integer;
BEGIN
	OPEN parent_cursor;
	OPEN name_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH name_cursor INTO fullname;
	CLOSE parent_cursor;
	CLOSE name_cursor;
	IF parentid is null
	THEN 
		return fullname;
	ELSE
		return CONCAT(hp_true_filename(parentid), CONCAT('/',fullname));
	END IF;	
END;
/
show errors


-- returned value is a varchar2 which is the sort key
-- Uses the fact that the full filename of each file has
-- to be unique.
create or replace function hp_filesystem_node_sortkey_gen (filesystem_node IN integer)
return varchar2
IS
	CURSOR plsql_is_stupid IS
		select filename, 
                       decode(directory_p,'t','0','1') as dp,
                       parent_id 
                from users_files
		where file_id=filesystem_node;
	fullname	varchar(500);
	parentid	integer;
	dir_p		varchar(1);
	plsql_val	plsql_is_stupid%ROWTYPE;
	discriminator	varchar(5);  -- useful for discriminating between files and directories
BEGIN
	OPEN plsql_is_stupid;
	FETCH plsql_is_stupid into plsql_val;
	dir_p := plsql_val.dp;
	fullname := plsql_val.filename;
	parentid := plsql_val.parent_id;

	IF parentid is null
	THEN 
		return CONCAT(dir_p, fullname);
	ELSE
		return CONCAT(hp_filesystem_node_sortkey_gen(parentid), CONCAT('/', CONCAT(dir_p,fullname)));
	END IF;	
END;
/
show errors


-- returns a filename beginning with a slash, unless the file is user's root
create or replace function hp_user_relative_filename (filesystem_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select filename from users_files
		where file_id=filesystem_node;
	CURSOR parent_cursor IS
		select parent_id from users_files
		where file_id=filesystem_node;
	fullname	varchar(500);
	parentid	integer;
BEGIN
	OPEN parent_cursor;
	OPEN name_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH name_cursor INTO fullname;
	CLOSE parent_cursor;
	CLOSE name_cursor;
	IF parentid is null
	THEN 
		return '';
	ELSE
		return CONCAT(hp_user_relative_filename(parentid) ,CONCAT('/',fullname));
	END IF;	
END;
/
show errors


create or replace function hp_get_filesystem_root_node (u_id IN integer)
return integer
IS
	CURSOR root_cursor IS
		select file_id from users_files
	        where filename=u_id
        	and parent_id is null
	        and owner_id=u_id;
	root_id		integer;
BEGIN
	OPEN root_cursor;
	FETCH root_cursor INTO root_id;
	CLOSE root_cursor;
	return root_id;
END;
/
show errors


create or replace function hp_get_filesystem_node_owner (fsid IN integer)
return integer
IS
	CURSOR owner_cursor IS
		select owner_id from users_files
		where file_id=fsid;
	owner_id	integer;
BEGIN
	OPEN owner_cursor;
	FETCH owner_cursor INTO owner_id;
	CLOSE owner_cursor;
	return owner_id;
END;
/
show errors


create or replace function hp_get_filesystem_child_count (fsid IN integer)
return integer
IS
	CURSOR count_cursor IS
		select count(*) from users_files
		where parent_id=fsid;
	counter		integer;
BEGIN
	OPEN count_cursor;
	FETCH count_cursor INTO counter;
	CLOSE count_cursor;
	return counter;
END;
/
show errors


create or replace function hp_access_denied_p (fsid IN integer, u_id IN integer)
return integer
IS
	CURSOR owner_cursor IS
		select owner_id from users_files
		where file_id=fsid;
	owner_id	integer;
BEGIN
	OPEN owner_cursor;
	FETCH owner_cursor INTO owner_id;
	CLOSE owner_cursor;
	IF owner_id = u_id
	THEN
		return 0;
	ELSE
		return 1;
	END IF;
END;
/
show errors


create or replace function hp_fs_node_from_rel_name (rootid IN integer, rel_name IN varchar2)
return integer
IS
	slash_location		integer;
	nodeid			integer;
BEGIN
	IF rel_name is null
	THEN
		return rootid;
	ELSE
		slash_location := INSTR(rel_name,'/');
		IF slash_location = 0
		THEN
			select file_id into nodeid
			from users_files
			where parent_id=rootid
			and filename=rel_name;
			return nodeid;
		ELSIF slash_location = 1
		THEN
			return hp_fs_node_from_rel_name(rootid, SUBSTR(rel_name,2));
		ELSE
			select file_id into nodeid
			from users_files
			where parent_id=rootid
			and filename=SUBSTR(rel_name,1,slash_location-1);
			return hp_fs_node_from_rel_name(nodeid,SUBSTR(rel_name,slash_location));
		END IF;
	END IF;
END;
/
show errors


------------------------------------------
-- ENDOF fileSystemManagement codeBlock --
------------------------------------------


---------------------------------------------
-- BEGINNINGOF contentManagement codeBlock --
---------------------------------------------


create or replace function hp_top_level_content_title (filesystem_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select file_pretty_name from users_files
		where file_id=filesystem_node;
	CURSOR parent_cursor IS
		select parent_id from users_files
		where file_id=filesystem_node;
	CURSOR managed_p_cursor IS
		select managed_p from users_files
		where file_id=filesystem_node;
	managedp		varchar(1);	
	fullname		varchar(500);
	parentid		integer;
	parent_managedp 	varchar(1);
BEGIN
	OPEN parent_cursor;
	OPEN name_cursor;
	OPEN managed_p_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH name_cursor INTO fullname;
	FETCH managed_p_cursor INTO managedp;
	CLOSE parent_cursor;
	CLOSE name_cursor;
	CLOSE managed_p_cursor;
	IF parentid is null
	THEN 
		return fullname;
	END IF;
	IF managedp = 't'
	THEN
		select managed_p into parent_managedp
		from users_files
		where file_id=parentid;
		
		IF parent_managedp = 'f'
		THEN
			return fullname;
		ELSE
			return hp_top_level_content_title(parentid);
		END IF;
	ELSE
		return fullname;
	END IF;	
END;
/
show errors


create or replace function hp_top_level_content_node (filesystem_node IN integer)
return varchar2
IS
	CURSOR parent_cursor IS
		select parent_id from users_files
		where file_id=filesystem_node;
	CURSOR managed_p_cursor IS
		select managed_p from users_files
		where file_id=filesystem_node;
	managedp		varchar(1);	
	parentid		integer;
	parent_managedp 	varchar(1);
BEGIN
	OPEN parent_cursor;
	OPEN managed_p_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH managed_p_cursor INTO managedp;
	CLOSE parent_cursor;
	CLOSE managed_p_cursor;
	IF parentid is null
	THEN 
		return filesystem_node;
	END IF;
	IF managedp = 't'
	THEN
		select managed_p into parent_managedp
		from users_files
		where file_id=parentid;
		
		IF parent_managedp = 'f'
		THEN
			return filesystem_node;
		ELSE
			return hp_top_level_content_node(parentid);
		END IF;
	ELSE
		return filesystem_node;
	END IF;	
END;
/
show errors


create or replace function hp_onelevelup_content_title (filesystem_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select file_pretty_name from users_files
		where file_id=filesystem_node;
	CURSOR parent_cursor IS
		select parent_id from users_files
		where file_id=filesystem_node;
	CURSOR managed_p_cursor IS
		select managed_p from users_files
		where file_id=filesystem_node;
	CURSOR directory_p_cursor IS
		select directory_p from users_files
		where file_id=filesystem_node;
	managedp		varchar(1);	
	dirp			varchar(1);	
	parentid		integer;
	fullname		varchar(500);
BEGIN
	OPEN name_cursor;
	OPEN parent_cursor;
	OPEN managed_p_cursor;
	OPEN directory_p_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH managed_p_cursor INTO managedp;
	FETCH directory_p_cursor INTO dirp;
	FETCH name_cursor INTO fullname;
	CLOSE parent_cursor;
	CLOSE managed_p_cursor;
	CLOSE directory_p_cursor;
	CLOSE name_cursor;

	IF parentid is null
	THEN 
		return fullname;
	END IF;
	IF managedp = 't'
	THEN
		IF dirp = 't'
		THEN
			return fullname;
		ELSE
			return hp_onelevelup_content_title(parentid);
		END IF;
	ELSE
		return fullname;
	END IF;	
END;
/
show errors


create or replace function hp_onelevelup_content_node (filesystem_node IN integer)
return varchar2
IS
	CURSOR parent_cursor IS
		select parent_id from users_files
		where file_id=filesystem_node;
	CURSOR managed_p_cursor IS
		select managed_p from users_files
		where file_id=filesystem_node;
	CURSOR directory_p_cursor IS
		select directory_p from users_files
		where file_id=filesystem_node;
	managedp		varchar(1);	
	dirp			varchar(1);	
	parentid		integer;
BEGIN
	OPEN parent_cursor;
	OPEN managed_p_cursor;
	OPEN directory_p_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH managed_p_cursor INTO managedp;
	FETCH directory_p_cursor INTO dirp;
	CLOSE parent_cursor;
	CLOSE managed_p_cursor;
	CLOSE directory_p_cursor;
	IF parentid is null
	THEN 
		return filesystem_node;
	END IF;
	IF managedp = 't'
	THEN
		IF dirp = 't'
		THEN
			return filesystem_node;
		ELSE
			return hp_onelevelup_content_node(parentid);
		END IF;
	ELSE
		return filesystem_node;
	END IF;	
END;
/
show errors


---------------------------------------
-- ENDOF contentManagement codeBlock --
---------------------------------------


---------------------------------------------------
-- BEGINNINGOF neighbourhoodManagement codeBlock --
---------------------------------------------------


create or replace function hp_true_neighborhood_name (neighborhood_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select neighborhood_name from users_neighborhoods
		where neighborhood_id=neighborhood_node;
	CURSOR parent_cursor IS
		select parent_id from users_neighborhoods
		where neighborhood_id=neighborhood_node;
	fullname	varchar(500);
	parentid	integer;
BEGIN
	OPEN parent_cursor;
	OPEN name_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH name_cursor INTO fullname;
	CLOSE parent_cursor;
	CLOSE name_cursor;
	IF parentid is null
	THEN 
		return fullname;
	ELSE
		return CONCAT(hp_true_neighborhood_name(parentid), CONCAT(' : ',fullname));
	END IF;	
END;
/
show errors


create or replace function hp_get_neighborhood_root_node return integer
IS
	CURSOR root_cursor IS
		select neighborhood_id 
 		from users_neighborhoods
        	where parent_id is null;
	root_id		integer;
BEGIN
	OPEN root_cursor;
	FETCH root_cursor INTO root_id;
	CLOSE root_cursor;
	return root_id;
END;
/
show errors


create or replace function hp_relative_neighborhood_name (neighborhood_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select neighborhood_name from users_neighborhoods
		where neighborhood_id=neighborhood_node;
	CURSOR parent_cursor IS
		select parent_id from users_neighborhoods
		where neighborhood_id=neighborhood_node;
	fullname	varchar(500);
	parentid	integer;
	root_node	integer;
BEGIN
	OPEN parent_cursor;
	OPEN name_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH name_cursor INTO fullname;
	CLOSE parent_cursor;
	CLOSE name_cursor;

	select hp_get_neighborhood_root_node 
	into root_node
	from dual;

	IF neighborhood_node = root_node
	THEN
		return '';
	END IF;

	IF parentid is null
	THEN
		return '';
	END IF;

	IF parentid = root_node
	THEN 
		return fullname;
	ELSE
		return CONCAT(hp_relative_neighborhood_name(parentid), CONCAT(' : ',fullname));
	END IF;	
END;
/
show errors


-- generates a sort key for this neighbourhood. Can be used in 'connect by'
-- with 'order by'.
create or replace function hp_neighborhood_sortkey_gen (neighborhood_node IN integer)
return varchar2
IS
	CURSOR name_cursor IS
		select neighborhood_name from users_neighborhoods
		where neighborhood_id=neighborhood_node;
	CURSOR parent_cursor IS
		select parent_id from users_neighborhoods
		where neighborhood_id=neighborhood_node;
	fullname	varchar(500);
	parentid	integer;
BEGIN
	OPEN parent_cursor;
	OPEN name_cursor;
	FETCH parent_cursor INTO parentid;
	FETCH name_cursor INTO fullname;
	CLOSE parent_cursor;
	CLOSE name_cursor;
	IF parentid is null
	THEN 
		return '/';
	ELSE
		return CONCAT(hp_neighborhood_sortkey_gen(parentid), CONCAT('/',fullname));
	END IF;	
END;
/
show errors


create or replace function hp_get_nh_child_count (neighborhoodid IN integer)
return integer
IS
	CURSOR count_cursor IS
		select count(*) from users_neighborhoods
		where parent_id=neighborhoodid;
	counter		integer;
BEGIN
	OPEN count_cursor;
	FETCH count_cursor INTO counter;
	CLOSE count_cursor;
	return counter;
END;
/
show errors


create or replace function hp_neighborhood_in_subtree_p (source_node IN integer, target_node IN integer)
return varchar2
IS
	CURSOR parent_cursor IS
		select parent_id from users_neighborhoods
		where neighborhood_id=target_node;
	parentid	integer;
BEGIN
	OPEN parent_cursor;
	FETCH parent_cursor INTO parentid;
	CLOSE parent_cursor;
	
	IF source_node = target_node
	THEN
		return 't';
	END IF;
	
	IF parentid is null
	THEN 
		return 'f';
	ELSE
		IF parentid = source_node
		THEN
			return 't';
		ELSE
			return hp_neighborhood_in_subtree_p(source_node, parentid);
		END IF;
	END IF;	
END;
/
show errors


---------------------------------------------
-- ENDOF neighbourhoodManagement codeBlock --
---------------------------------------------


-----------------------------------
-- BEGINNINGOF useless codeBlock --
-----------------------------------


-- This is a function that I have hath use for ofttimes.
create or replace function mobin_function_definition (function_name IN varchar2)
return varchar2
IS
	CURSOR fn_line_cursor IS
		select Text from USER_SOURCE
		where Name = upper(function_name)
		and Type = 'FUNCTION'
		order by Line;
	fn_line		varchar(500);
	fn_total	varchar(4000);
BEGIN
	OPEN fn_line_cursor;
	LOOP
		FETCH fn_line_cursor INTO fn_line;
		EXIT WHEN fn_line_cursor%NOTFOUND;
		fn_total := CONCAT(fn_total,fn_line);
	END LOOP;
	return fn_total;
	
END;
/
show errors


-- A view I find rather useful
create or replace view hp_functions
AS
select lower(Name) as function_name, count(*) as line_count 
from USER_SOURCE
where Type = 'FUNCTION'
and Name like 'HP_%'
and Name != 'HP_FUNCTIONS'
group by Name
order by Name;


-----------------------------
-- ENDOF useless codeBlock --
-----------------------------


----------------------------------
-- BEGINNINGOF useful codeBlock --
----------------------------------


-- this function is so useful that I can't tell you!
create or replace function mobin_number_to_letter (letter_no IN integer)
return varchar2
IS
	letter		varchar(1);
BEGIN
	select decode(letter_no, '1', 'A', '2', 'B', '3', 'C', 
	'4', 'D', '5', 'E', '6', 'F',
	'7', 'G', '8', 'H', '9', 'I',
	'10', 'J', '11', 'K', '12', 'L',
	'13', 'M', '14', 'N', '15', 'O',
	'16', 'P', '17', 'Q', '18', 'R',
	'19', 'S', '20', 'T', '21', 'U',
	'22', 'V', '23', 'W', '24', 'X',
	'25', 'Y', 'Z') into letter
	from dual;
	return letter;
	
END;
/
show errors


----------------------------
-- ENDOF useful codeBlock --
----------------------------


-----------------------------------------------
-- BEGINNINGOF userQuotaManagement codeBlock --
-----------------------------------------------


create or replace function hp_user_quota_max (userid IN integer, lesser_mortal_quota IN integer, higher_mortal_quota IN integer, higher_mortal_p IN integer)
return integer
IS
	quota_max		integer;
	special_count		integer;
	return_value		integer;
BEGIN
	select count(*) into special_count
	from users_special_quotas
        where user_id=userid;

	IF special_count = 0
	THEN
		IF higher_mortal_p = 0
		THEN
			select (lesser_mortal_quota * power(2,20)) 
			into return_value
			from dual;
			return return_value;
		ELSE
			select (higher_mortal_quota * power(2,20)) 
			into return_value
			from dual;
			return return_value;
		END IF;
	ELSE
		select max_quota into quota_max
		from users_special_quotas
                where user_id=userid;
		select (quota_max * power(2,20)) 
		into return_value
		from dual;
		return return_value;
	END IF;
END;
/
show errors


create or replace function hp_user_quota_max_check_admin (userid IN integer, lesser_mortal_quota IN integer, higher_mortal_quota IN integer)
return integer
IS
	quota_max		integer;
	special_count		integer;
	return_value		integer;
	higher_mortal_p		integer;
BEGIN
	select count(*) into special_count
	from users_special_quotas
        where user_id=userid;

	select count(*) into higher_mortal_p
	from user_group_map ugm
	where ugm.user_id = userid
	and ugm.group_id = system_administrator_group_id;

	IF special_count = 0
	THEN
		IF higher_mortal_p = 0
		THEN
			select (lesser_mortal_quota * power(2,20)) 
			into return_value
			from dual;
			return return_value;
		ELSE
			select (higher_mortal_quota * power(2,20)) 
			into return_value
			from dual;
			return return_value;
		END IF;
	ELSE
		select max_quota into quota_max
		from users_special_quotas
                where user_id=userid;
		select (quota_max * power(2,20)) 
		into return_value
		from dual;
		return return_value;
	END IF;
END;
/
show errors


create or replace function hp_user_quota_used (userid IN integer, dir_requirement IN integer)
return integer
IS
	return_value		integer;
	file_space		integer;
	dir_space		integer;
BEGIN
	select (count(*) * dir_requirement) into dir_space 
        from users_files
        where directory_p='t'
        and owner_id=userid;

	select nvl(sum(file_size),0) into file_space
        from users_files
        where directory_p='f'
        and owner_id=userid;

	return_value := dir_space + file_space;

	return return_value;
END;
/
show errors


create or replace function hp_user_quota_left (userid IN integer, lesser_mortal_quota IN integer, higher_mortal_quota IN integer, higher_mortal_p IN integer, dir_requirement IN integer)
return integer
IS
	return_value		integer;
BEGIN
	select (hp_user_quota_max(userid, lesser_mortal_quota, higher_mortal_quota, higher_mortal_p) - hp_user_quota_used(userid, dir_requirement))
	into return_value
	from dual;

	return return_value;
END;
/
show errors


create or replace function hp_user_quota_left_check_admin (userid IN integer, lesser_mortal_quota IN integer, higher_mortal_quota IN integer, dir_requirement IN integer)
return integer
IS
	return_value		integer;
BEGIN
	select (hp_user_quota_max_check_admin(userid, lesser_mortal_quota, higher_mortal_quota) - hp_user_quota_used(userid, dir_requirement))
	into return_value
	from dual;

	return return_value;
END;
/
show errors


-----------------------------------------
-- ENDOF userQuotaManagement codeBlock --
-----------------------------------------
