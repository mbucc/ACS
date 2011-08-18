
--
-- upgrade-2.4-3.0.sql
--
-- by philg@mit.edu on December 17, 1999
--

-- NEW ACS MODULES TABLE (all acs modules should eventually be registered here)

-- this table stores information about the acs modules (news, bboard, ...)
create table acs_modules (
	module_key		varchar(30) primary key,
	pretty_name		varchar(200) not null,
	-- this is the directory where module public files are stored. 
	-- for the news module public_directory would be /news
	public_directory	varchar(200),
	-- this is the directory where module admin files are stored
	-- for the news module admin_directory would be /admin/news
	admin_directory		varchar(200),
	-- this is the directory where system admin files are stored 
	-- notice that this is not always same as the admin_directory
	-- e.g. ticket module has admin directory /ticket/admin and
	-- site admin directory /admin/ticket
	site_wide_admin_directory	varchar(200),
	-- if module_type=system, this module has all: public, admin and site_wide admin pages (e.g. faq, news)
	-- notice that often admin and site_wide admin directory are merged together
	-- if module_type=admin, this is admin module and has no public pages (e.g. display, content_sections)
	-- notice that modules of this type have no public pages
	-- if module_type=site_wide_admin, this is module for site wide administration of another module (e.g. news_admin, bboard_admin)
	-- notice that having admin module for another module allows us to assign administration of modules to user groups
	-- in this case public_directory will correspond to the directory where files for site wide administration of that
	-- module are stored and admin_directory and site_wide_admin_directory are irrelevant 
	module_type                    varchar(20) not null check(module_type in ('system', 'admin', 'site_wide_admin')),
	-- does module support scoping
	supports_scoping_p	char(1) default 'f' check(supports_scoping_p in ('t','f')),
	-- this is short description describing what module is doing	
	description		varchar(4000),
	-- this is url of the html file containing module documentation
	documentation_url	varchar(200),
	-- this is url of the file containing date model of the module
	data_model_url		varchar(200)
);

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)
values
('news', 'News', '/news', '/news/admin', '/admin/news', 'system', 't', '/doc/news.html', '/doc/sql/news.sql', 'A news item is something that is interesting for awhile and then should disappear into the archives without further administrator intervention. We want a news article to serve as the focus of user comments. You could use the /bboard system to accomplish the same function. If you did, you''d get the advantages of file attachments, group-based administration, etc. But we think that news truly is different from discussion. We want to present it by date, not by topic. The publisher probably wants to be very selective about what gets posted (as news if not as comments on news). So it gets a separate module.');

insert into acs_modules
(module_key, pretty_name, admin_directory, module_type, supports_scoping_p, data_model_url)
values
('content-sections', 'Content Sections', '/admin/content-sections', 'admin', 't', '/doc/sql/community-core.sql');

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, module_type, supports_scoping_p, data_model_url)
values
('custom-sections', 'Custom Sections', '/custom-sections', '/admin/custom-sections', 'system', 't', '/doc/sql/community-core.sql');

insert into acs_modules 
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, 
 documentation_url, data_model_url, description)
values
('address-book', 'Address Book', '/address-book', '/address-book', '/admin/address-book','system', 't', '/doc/address-book.html', '/doc/address-book.sql', 'This is a really simple address book which also does birthday reminders.');

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, module_type, supports_scoping_p, 
 documentation_url, data_model_url, description)
values
('display', 'Display', '/display', '/admin/display', 'admin', 't', 
 '/doc/display.html', '/doc/sql/display.sql', 'Use this module if you want to give your pages easily changable display using cascaded style sheets and uploading logos.');

insert into acs_modules
(module_key, pretty_name, public_directory, module_type, supports_scoping_p)
values
('news_administration', 'News Administration', '/admin/news', 'site_wide_admin', 'f');

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)
values
('faq', 'Frequently Asked Questions', '/faq', '/faq/admin', '/admin/faq', 'system', 't', '/doc/faq.html', '/doc/sql/faq.sql', 'Frequently Asked Questions');

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)	
values	
('general-comments', 'General Comments', '/general-comments', '/general-comments/admin', '/admin/general-comments', 'admin', 't', '/doc/general-comments.html', '/doc/sql/general-comments.sql', 'General Comments Module');

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)	
values	
('download', 'Download', '/download', '/download/admin', '/admin/download', 'system', 't', '/doc/download.html', '/doc/sql/download.sql', 'Download Module');


commit;

create or replace function section_type_from_module_key (v_module_key IN acs_modules.module_key%TYPE)
     return varchar
     IS
	v_module_type acs_modules.module_type%TYPE;
     BEGIN
	select module_type into v_module_type
	from acs_modules
	where module_key=v_module_key;

	if v_module_type='system' then
	    return 'system';
	elsif v_module_type='admin' then
	    return 'admin';
	else
	    return 'system';
	end if;
     END section_type_from_module_key;
/
show errors

create or replace function pretty_name_from_module_key (v_module_key IN acs_modules.module_key%TYPE)
     return varchar
     IS
	v_pretty_name acs_modules.pretty_name%TYPE;
     BEGIN
	select pretty_name into v_pretty_name
	from acs_modules
	where module_key=v_module_key;

	return v_pretty_name;

     END pretty_name_from_module_key;
/
show errors


-- ADDRESS BOOK SCOPIFICATION

-- support for group_id and scope checking (user, group, public)
create sequence address_book_id_sequence;
alter table address_book add (
	address_book_id	integer,
        scope		varchar(20) not null,
	group_id	references user_groups,
	on_which_table  varchar(50),
	on_what_id      integer
);

update address_book 
set address_book_id=address_book_id_sequence.nextval;

update address_book
set scope='user'
where user_id is not null;

update address_book
set scope='public'
where user_id is null;

commit;

alter table address_book add constraint address_book_primary_id_check primary key(address_book_id);

alter table address_book add constraint address_book_scope_check 
check ((scope='group' and group_id is not null) or
       (scope='user' and user_id is not null) or
       (scope='table' and on_which_table is not null and on_what_id is not null) or
       (scope='public'));

-- add index on the group_id for the address_book table
create index address_book_group_idx on address_book ( group_id );



-- NEW DISPLAY MODULE

-- notice that these two separate data models for css will be merged into 
-- one in the next release of the acs (per jeff davis data model

-- using this table makes writing user friendly css forms possible
-- it limits how much you can do with css though, but it should
-- suffice for most practical purposes
create sequence css_simple_id_sequence;
create table css_simple (
        css_id  		  integer primary key,
        -- if scope=public, this is the css for the whole system
        -- if scope=group, this is the css for a particular group
        -- is scope=user this is the css for particular user
        scope   	          varchar(20) not null,
        user_id			  references users,
        group_id		  references user_groups,
	css_bgcolor		  varchar(40),
	css_textcolor		  varchar(40),
	css_unvisited_link	  varchar(40),
	css_visited_link	  varchar(40),
	css_link_text_decoration  varchar(40),
	css_font_type		  varchar(40)
);

alter table css_simple add constraint css_simple_scope_unique 
unique(scope, user_id, group_id);

alter table css_simple add constraint css_simple_data_scope_check check (
	(scope='group' and group_id is not null and user_id is null) or
        (scope='user' and user_id is not null and group_id is null) or
        (scope='public'));

-- if you need full control of how your css look like you should use 
-- css_complete_version table which is capable of storing any css
create sequence css_complete_id_sequence;
create table css_complete (
        css_id integer primary key,
        -- if scope=public, this is the css for the whole system
        -- if scope=group, this is the css for a particular group
        -- is scope=user this is the css for particular user
        scope           varchar(20) not null,
        user_id		references users,
        group_id	references user_groups,
	-- e.g. A, H1, P, P.intro
	selector varchar(60) not null,
	-- e.g. color, bgcolor, font-family
        property varchar(40) not null,
	-- e.g. "Times Roman", "Verdana". notice that value can be rather
	-- big (for example when specifying font-families)
        value varchar(400) not null
);

alter table css_complete add constraint css_complete_data_scope_check check (
	(scope='group' and group_id is not null and user_id is null) or
        (scope='user' and user_id is not null and group_id is null) or
        (scope='public'));

-- selector and property must be unique for the appropriate scope
alter table css_complete add constraint css_selector_property_unique 
unique (scope, group_id, user_id, selector, property);


-- this table stores the log that can be displayed on every page
create sequence page_logos_id_sequence;
create table page_logos (
	logo_id 		integer primary key,
       	-- if scope=public, this is the system-wide logo
        -- if scope=group, this is the logo for a particular group
        -- is scope=user this is the logo for a particular user
        scope           	varchar(20) not null,
        user_id			references users,
        group_id		references user_groups,
	logo_enabled_p		char(1) default 'f' check(logo_enabled_p in ('t', 'f')),
	logo_file_type          varchar(100) not null,
        logo_file_extension     varchar(50) not null,    -- e.g., "jpg"
	logo			blob not null
);

alter table page_logos add constraint page_logos_scope_check check (
	(scope='group' and group_id is not null and user_id is null) or
        (scope='user' and user_id is not null and group_id is null) or
        (scope='public'));

alter table page_logos add constraint page_logos_scope_unique 
unique(scope, user_id, group_id);



-- CHANGES TO THE USER GROUP TABLE

-- add short_name to the user_groups necessary for pretty url's and other purposes
-- (e.g. http://photo.net/groups/travel for group with short name travel as opposed
--  to http://photo.net/ug/groups.tcl?group_id=2314)
-- note that short name is rather big (100 characters) in order to support backward
-- compatibility because we want to generate short names for old data by taking out
-- spaces from the group_name and then adding the key to ensure uniqueness.
-- also, email at the bottom page of the group user pages can be potentially different for 
-- each group. so, if admin_email in user_groups table is not null than admin_email should be used 
-- at the bottom of each group user page and else if it is null than the SystemOwner email from
-- parameters file should be used (this is to ensure backward compatibility).
-- note that group admin pages should stil be signed by AdminOwner email (from parameters file)
-- because group administrators will not have programming privileges (they will only be managing
-- user data through provided web interface)

alter table user_groups add (
	short_name varchar(100),
	admin_email varchar (100)
);

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

-- generate short_names from existing group_names
execute generate_short_names_for_group;

-- short_name should be not null

alter table user_groups add constraint user_groups_short_name_nnull check(short_name is not null);

-- short name should be unique 

alter table user_groups add constraint user_groups_short_name_unique unique(short_name);

-- add various user group settings
alter table user_groups add (
	index_page_enabled_p	char(1) default 'f' check (index_page_enabled_p in ('t','f')),
	-- this is index page content
	body			clob,
	-- html_p for the index page content
	html_p	                char(1) default 'f' check (html_p in ('t','f'))
);

------------ philg added this to robot-detection.sql

create or replace trigger robots_modified_date
before insert or update on robots
for each row
when (new.modified_date is null)
begin
 :new.modified_date := SYSDATE;
end;
/
show errors



-- NEW AND IMPROVED CONTENT SECTIONS

-- changes for new content sections table
-- note that we have changed the primary key in the content_sections table
-- so we will have to move data to new temporary table
-- let's first create content_sections table, then insert data into it 
-- from the old content_sections table, then drop the old content sections 
-- table and finally rename content_sections table back to content_sections

create sequence content_section_id_sequence;
create table content_sections_temp (
        section_id              integer primary key,
        -- if scope=public, this is the content sections for the whole system
        -- if scope=group this is the content sections for particular group
        -- is scope=user this is the content sections for particular user
        scope                   varchar(20) not null,
	-- if section_type=system, this section corresponds to one of the system sections
	-- such as news, bboard, ...
	-- if section_type=custom, this section is custom section
	-- custom sections serve like url directories. so if group administrator of group travel 
	-- at photo.net defines custom section sweeden (e.g. photo.net/travel/sweeden), he will be 
	-- able to then to upload files for this section (see content_files table) in order to display
	-- the file photo.net/groups/travel/sweeden/stockholm.html
	-- if section_type=static, this section is static section
	-- static sections serve as html pages and address of html page is specified in section_url_stub
	-- if you have file arsdigita.html in your carrers directory then section_url_stub should be
	-- /carrers/arsdigita.html  
	-- if section_type=admin, this section is system section but does not have associated public pages
	-- it only has administration pages.
	section_type                    varchar(20) not null,
	-- does user have to be registered in order to access this page
	requires_registration_p	char(1) default 'f' check(requires_registration_p in ('t','f')),
	-- if visibility=public this content section is viewable by everybody
	-- if visibility=private this content section is viewable be a user only if scope=user
	-- or by group members only if scope=group
	visibility		varchar(20) not null check(visibility in ('private', 'public')),
        user_id                 references users,
        group_id                references user_groups,
        section_key             varchar(30) not null,
	-- this is used only for system sections
	-- each system sections is associated with an acs module
	module_key		references acs_modules,
        section_url_stub        varchar(200),
        section_pretty_name     varchar(200) not null,
        -- if we print lists of sections, where does this go?
        -- two sections with same sort_key will sort 
        -- by upper(section_pretty_name)
        sort_key                integer,
        enabled_p               char(1) default 't' check(enabled_p in ('t','f')),
        intro_blurb		varchar(4000),
        help_blurb      	varchar(4000),
        index_page_enabled_p    char(1) default 'f' check (index_page_enabled_p in ('t','f')),
        -- html content for customizing index page (this is used only for content sections of section_type custom)
        body                    clob,
        html_p                  char(1) default 'f' check(html_p in ('t','f'))
);

-- note that all old data from previous data model will have all of it's content sections 
-- with scope=public and both user_id and group_id set to null
-- also we don't have to specify values for body and html_p because they are new in this data model
-- due to our constraint that static pages must have a section_url_stub (this is new constraint)
-- we will insert / for section_url_stub where static_p='t'

insert into content_sections_temp
(section_id, scope, section_type, section_key, section_url_stub, requires_registration_p, visibility,
 section_pretty_name, sort_key, enabled_p, intro_blurb, help_blurb)
select section_id, 'public', 'static', section_key, 
       decode(section_url_stub, NULL, '/', section_url_stub), requires_registration_p, 'public',
       section_pretty_name, sort_key, enabled_p, intro_blurb, help_blurb
from content_sections 
where static_p='t';

-- when static_p='f' we will assume it's system section (it didn't have much meaning before)
-- don't have to worry about section_url_stub

insert into content_sections_temp
(section_id, scope, section_type, section_key, section_url_stub, requires_registration_p, visibility,
 section_pretty_name, sort_key, enabled_p, intro_blurb, help_blurb)
select section_id, 'public', 'system', section_key, 
       section_url_stub, requires_registration_p, 'public', section_pretty_name,  
       sort_key, enabled_p, intro_blurb, help_blurb
from content_sections 
where static_p='f';

commit;

-- now, that we have all the data in the content_sections table, 
-- let's drop the old content_sections table and rename 
-- content_sections table to content_sections

drop table content_sections;
alter table content_sections_temp rename to content_sections;

-- now, let's add scope checking
alter table content_sections add constraint content_sections_scope_check 
check ((scope='group' and group_id is not null and user_id is null) or
       (scope='user' and user_id is not null and group_id is null) or
       (scope='public' and user_id is null and group_id is null));

-- add check to make sure section_url_stub is always provided for the static sections
-- also, system and admin sections must have associated acs module with them
alter table content_sections add constraint content_sections_type_check 
check ((section_type='static' and section_url_stub is not null) or
       ((section_type='system' or section_type='admin') and module_key is not null) or 
       (section_type='custom'));

-- add checks for appropriate uniqueness
alter table content_sections add constraint content_sections_unique_check
unique(scope, section_key, user_id, group_id);

-- returns t if section exists and is enabled
create or replace function enabled_section_p 
       ( v_section_id content_sections.section_id%TYPE)
     return varchar
     is
       v_enabled_p char(1);
     BEGIN
       select enabled_p into v_enabled_p 
         from content_sections
         where section_id = v_section_id;

      if v_enabled_p is null then
         return 'f';
       else 
         return v_enabled_p;
       end if;
     END enabled_section_p;
/
show errors

create or replace function content_section_id_to_key (v_section_id IN content_sections.section_id%TYPE)
     return varchar
     IS
        v_section_key content_sections.section_key%TYPE;

     BEGIN
	select section_key into v_section_key
	from content_sections
	where section_id=v_section_id;

	return v_section_key;
     END content_section_id_to_key;
/
show errors


-- CONTENT FILES TABLE USED BY CUSTOM SECTIONS MODULE


create sequence content_file_id_sequence start with 1;
create table content_files (
	content_file_id 	integer primary key,
	section_id 		references content_sections,
	-- this will be part of url; should be a-zA-Z and underscore
	file_name		varchar(30) not null,
        -- this is a MIME type (e.g., text/html, image/jpeg)	
        file_type               varchar(100) not null,
        file_extension          varchar(50),    -- e.g., "jpg"
	-- if file is text or html we need page_pretty_name, body and html_p
	page_pretty_name        varchar(200),
	body			clob,
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	-- if the file is attachment we need use binary_data blob( e.g. photo, image)
	binary_data             blob
);

alter table content_files add constraint content_file_names_unique
unique(section_id, file_name);


-- CONTENT SECTION LINKS  

create sequence section_link_id_sequence start with 1;
create table content_section_links(
	section_link_id integer primary key,
	from_section_id references content_sections,
	to_section_id references content_sections,
	constraint content_section_links_unique unique(from_section_id, to_section_id)
);


-- MODIFICATION TO USER GROUP TYPE TABLE

alter table user_group_types add (
	-- if group_module_administration=full, then group administrators have full control of which modules
	-- they can use (they can add, remove, enable and disable all system modules)
	-- if group_module_administration=enabling, then group administrators have authority to enable and 
	-- disable modules but cannot add or remove modules
	-- if group_module_administration=none, the group administrators have no control over modules
	-- modules are explicitly set for the user group type by the system administrator 
	group_module_administration	varchar(20)
);

update user_group_types 
set group_module_administration='none';

commit;


-- MAPPING BETWEEN THE MODULES AND THE GROUP TYPES


-- this table is used when group administrators are not allowed to handle module administration
-- (allow_module_administration_p is set to 0 for this group type)
-- all groups of this group type will have only modules set up for which mapping in this table exists
create sequence group_type_modules_id_sequence start with 1;
create table user_group_type_modules_map (
	group_type_module_id 	integer primary key,	
	group_type 		references user_group_types not null,
	module_key		references acs_modules not null
);

-- this is the helper function for function uniq_group_module_section_key bellow
create or replace function uniq_group_module_section_key2
(v_module_key IN acs_modules.module_key%TYPE, v_group_id IN user_groups.group_id%TYPE, v_identifier IN integer)
     return varchar
     IS
        v_new_section_key content_sections.section_key%TYPE;

	cursor c1 is select section_key
	from content_sections
	where scope='group' 
	and group_id=v_group_id
	and section_key=v_module_key || decode(v_identifier, 0, '', v_identifier);
     BEGIN
	OPEN c1;
	FETCH c1 into v_new_section_key;

	if c1%NOTFOUND then
	    select v_module_key || decode(v_identifier, 0, '', v_identifier) into v_new_section_key from dual;
	    return v_new_section_key;
        else	
	    return uniq_group_module_section_key2(v_module_key, v_group_id, v_identifier+1);
	end if;

     END uniq_group_module_section_key2;
/
show errors

-- this function generates unique section_key
-- v_module_key is the proposed section_key, this function will keep adding numbers to it
-- until it makes it unique (e.g. if sections news and news1 already exist for this groups, 
-- and module_key is news this function will return news2)
create or replace function uniq_group_module_section_key
(v_module_key IN acs_modules.module_key%TYPE, v_group_id IN user_groups.group_id%TYPE)
     return varchar
     IS
     BEGIN
	return uniq_group_module_section_key2(v_module_key, v_group_id, 0);
     END uniq_group_module_section_key;
/
show errors

-- this function returns t if a section module identified by module_key
-- is associated with the group identified by the group_id
create or replace function group_section_module_exists_p
(v_module_key IN acs_modules.module_key%TYPE, v_group_id IN user_groups.group_id%TYPE)
     return char
     IS
        v_dummy integer;

	cursor c1 is select 1
	from content_sections
	where scope='group' 
	and group_id=v_group_id
	and module_key=v_module_key;
     BEGIN
	OPEN c1;
	FETCH c1 into v_dummy;

	if c1%NOTFOUND then
	    return 'f';
        else	
	    return 't';
	end if;

     END group_section_module_exists_p;
/
show errors


-- SCOPIFICATION OF THE NEWS MODULE

-- added scoping support for news module
alter table news add ( 
	scope 		varchar(20),
	user_id		references users,
	group_id	references user_groups,
	on_which_table  varchar(50),
	on_what_id      integer
);

update news set scope='public';

commit;

alter table news add constraint news_scope_not_null_check 
check (scope is not null);

alter table news add constraint news_scope_check 
check ((scope='group' and group_id is not null) or
       (scope='user' and user_id is not null) or
       (scope='table' and on_which_table is not null and on_what_id is not null) or
       (scope='public'));

create index news_idx on news ( user_id );
create index news_group_idx on news ( group_id );


-- SCOPIFICATION OF THE GENERAL COMMENTS

alter table general_comments add (
	scope			varchar(20) default 'public' not null,
	-- group_id of the group for which this general comment was submitted
	group_id		references user_groups	
);

alter table general_comments add constraint general_comments_scope_check 
check ((scope='group' and group_id is not null) or
       (scope='public'));


-- BBoard changes
create sequence bboard_topic_id_sequence;

alter table bboard_topics add (topic_id	integer);
update bboard_topics set topic_id = bboard_topic_id_sequence.nextval;
alter table bboard_topics modify (topic_id not null);
-- drop references to topic so we can add primary key on topic_id
alter table bboard_topics drop primary key cascade;
alter table bboard_topics add (primary key (topic_id));

alter table bboard_topics add (read_access	varchar(16) default 'any' check (read_access in ('any','public','group')));
alter table bboard_topics add (write_access 	varchar(16) default 'public' check (write_access in ('public','group')));

alter table bboard add (urgent_p        char(1) default 'f' not null check (urgent_p in ('t','f')));


alter table bboard_q_and_a_categories add (topic_id references bboard_topics);
update bboard_q_and_a_categories set topic_id = (select topic_id from bboard_topics where topic = bboard_q_and_a_categories.topic);
alter table bboard_q_and_a_categories modify (topic_id not null);

alter table bboard_bozo_patterns add (topic_id references bboard_topics);
update bboard_bozo_patterns set topic_id = (select topic_id from bboard_topics where topic = bboard_bozo_patterns.topic);
alter table bboard_bozo_patterns modify (topic_id not null);

alter table bboard add (topic_id references bboard_topics);
update bboard set topic_id = (select topic_id from bboard_topics where topic = bboard.topic);
alter table bboard modify (topic_id not null);

drop index bboard_for_new_questions;
create index bboard_for_new_questions on bboard ( topic_id, refers_to, posting_time );

drop index bboard_for_one_category;
create index bboard_for_one_category on bboard ( topic_id, category, refers_to );

create or replace view bboard_new_answers_helper 
as
select substr(sort_key,1,6) as root_msg_id, topic_id, posting_time from bboard
where refers_to is not null;

alter table bboard_email_alerts add (topic_id references bboard_topics);
update bboard_email_alerts set topic_id = (select topic_id from bboard_topics where topic = bboard_email_alerts.topic);
alter table bboard_email_alerts modify (topic_id not null);

-- Create and populate bboard_thread_email_alerts
create table bboard_thread_email_alerts (
	thread_id	references bboard, -- references msg_id of thread root
	user_id		references users,
	primary key (thread_id, user_id)
);

insert into bboard_thread_email_alerts
select distinct substr(sort_key, 1, 6), user_id
from bboard
where notify = 't';

alter table bboard_topics add (unique(topic)); 

-- Drop obsolete columns and tables.
alter table bboard_topics drop column ns_perm_group;
alter table bboard_topics drop column ns_perm_group_added_for_forum;
alter table bboard_topics drop column restrict_to_workgroup_p;

drop table bboard_authorized_maintainers;
drop table bboard_workgroup;

alter table bboard_bozo_patterns drop primary key;
alter table bboard_bozo_patterns drop column topic;
alter table bboard_bozo_patterns add primary key (topic_id, the_regexp);

alter table bboard_bozo_patterns add primary key(topic_id);
alter table bboard_email_alerts drop column topic;

alter table bboard_q_and_a_categories drop primary key;
alter table bboard_q_and_a_categories drop column topic;
alter table bboard_q_and_a_categories add primary key (topic_id, category);

alter table bboard drop column topic;


--------- add an API call to the user group system

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


-- Support for persistent table customization, dimensional sliders,
-- etc.   from user-custom.sql
--  davis@arsdigita.com

create table user_custom (
        user_id         references users not null,
        -- user entered name
        item            varchar2(80) not null,
        -- ticket_table etc
        item_group      varchar2(80) not null,
        -- table_view etc
        item_type       varchar2(80) not null,
        -- list nsset etc.
        value_type      varchar2(80) not null,
        value           clob default empty_clob(), 
        primary key (user_id, item, item_group, item_type)
);


-- NEW FAQ MODULE

-- faq.sql  

-- a simple data model for holding a set of FAQs
-- by dh@arsdigita.com

-- Created Dec. 19 1999

create sequence faq_id_sequence;

create table faqs (
	faq_id		integer primary key,
	-- name of the FAQ.
	faq_name	varchar(250) not null,
	-- group the viewing may be restricted to 
	group_id	integer references user_groups,
	-- permissions can be expanded to be more complex later
        scope		varchar(20),
        -- insure consistant state 
       	constraint faq_scope_check check ((scope='group' and group_id is not null) 
                                          or (scope='public'))
);

create index faqs_group_idx on faqs ( group_id );

create sequence faq_entry_id_sequence;

create table faq_q_and_a (
	entry_id	integer primary key,
	 -- which FAQ
	faq_id		integer references faqs not null,
	question	varchar(4000) not null,
	answer		varchar(4000) not null,
	 -- determines the order of questions in a FAQ
	sort_key	integer not null
);

create or replace trigger faq_entry_faq_delete_tr
before delete on faqs
for each row
begin

   delete from faq_q_and_a
   where faq_id=:old.faq_id;

end faq_entry_faq_delete_tr;
/
show errors


-- NEW DOWNLOAD MODULE

--
-- download.sql
-- 
-- created by philg@mit.edu on 12/28/99
--
-- supports a system for keeping track of what .tar files or whatever
-- are available to which users and who has downloaded what
--
-- e.g., we use this at ArsDigita to keep track of who has downloaded
-- our open-source toolkit (so that we can later spam them with 
-- upgrade notifications)
-- 

create sequence download_id_sequence start with 1;

create table downloads (
	download_id		integer primary key,
	-- if scope=public, this is a download for the whole system
        -- if scope=group, this is a download for/from a subcommunity
        scope           varchar(20) not null,
	-- will be NULL if scope=public 
	group_id	references user_groups,
	-- e.g., "Bloatware 2000"
	download_name	varchar(100) not null,
	directory_name	varchar(100) not null,
	description		varchar(4000),
	-- is the description in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	creation_date		date default sysdate not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
        -- state should be consistent
	constraint download_scope_check check ((scope='group' and group_id is not null) 
                                               or (scope='public'))
);

create index download_group_idx on downloads ( group_id );

create sequence download_version_id_sequence start with 1;

create table download_versions (
	version_id	integer primary key,
	download_id	not null references downloads,
	-- when this can go live before the public
	release_date	date not null,
	pseudo_filename	varchar(100) not null,
	-- might be the same for a series of .tar files, we'll serve
	-- the one with the largest version_id
	version		number,
	status		varchar(30) check (status in ('promote', 'offer_if_asked', 'removed')),
	creation_date		date default sysdate not null ,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null
);

create index download_versions_download_idx on download_versions ( download_id );

create sequence download_rule_id_sequence start with 1;

create table download_rules (
	rule_id		integer primary key,
	-- one of the following will be not null
	version_id	references download_versions,
	download_id	references downloads,
	user_scope	varchar(30) check (user_scope in ('all', 'registered_users', 'purchasers', 'group_members', 'previous_purchasers')),
	-- will be NULL unless user_scope is 'group_membes'
	group_id	references user_groups,
	-- price to purchase or upgrade, typically NULL
	price		number,
	-- currency code to feed to CyberCash or other credit card system
	currency	varchar(3) default 'USD'
);

alter table download_rules add constraint download_version_null_check 
check ( download_id is not null or version_id is not null);

create index download_rules_version_idx on download_rules ( version_id );
create index download_rules_download_idx on download_rules ( download_id );


-- build a PL/SQL proc here 
-- returns 't' if a user can download, 'f' if not 
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_authorized_p (version_id IN integer, user_id IN integer)
return varchar
IS
begin
  return 't';
end download_authorized_p;
/
show errors

-- history 

create sequence download_log_id_sequence start with 1;

create table download_log (
	log_id		integer primary key,
	version_id	not null references download_versions,
	user_id		not null references users,
	entry_date	date not null,
	ip_address	varchar(50) not null
);

create index download_log_version_idx on download_log ( version_id );

create or replace trigger download_versions_delete_info
before delete on downloads
for each row
begin

   delete from download_versions
   where download_id=:old.download_id;

end download_versions_delete_info;
/
show errors

create or replace trigger downloads_rules_dload_del_tr
before delete on downloads
for each row
begin

   delete from download_rules
   where download_id=:old.download_id;

end downloads_rules_dload_del_tr;
/
show errors

create or replace trigger downloads_rules_version_del_tr
before delete on download_versions
for each row
begin

   delete from download_rules
   where version_id=:old.version_id;

end downloads_rules_version_del_tr;
/
show errors

create or replace trigger download_log_user_delete_tr
before delete on users
for each row
begin

   delete from download_log
   where user_id=:old.user_id;

end download_log_user_delete_tr;
/
show errors

create or replace trigger download_log_version_delete_tr
before delete on download_versions
for each row
begin

   delete from download_log
   where version_id=:old.version_id;

end download_log_version_delete_tr;
/
show errors



        

                     






