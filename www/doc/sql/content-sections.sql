-- File:     /doc/sql/content-sections.sql
-- Date:     01/08/2000	
-- Contact:  tarik@arsdigita.com
-- Purpose:  content sections and content files tables

-- changes for new content sections table
-- note that we have changed the primary key in the content_sections table
-- so we will have to move data to new temporary table
-- let's first create content_sections table, then insert data into it 
-- from the old content_sections table, then drop the old content sections 
-- table and finally rename content_sections table back to content_sections

create sequence content_section_id_sequence;
create table content_sections (
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


-- versioning, indexing, categorization of static content

-- URL_STUB is relative to document root, includes leading /
-- and trailing ".html"

-- for collaboration, the software assumes the possible existence
-- of a file ending in ".new.html" (presented only to authors)
-- this is not handled in the RDBMS

-- draft pages end in ".draft.html" in the Unix file system; they are
-- only made available to users who show up in the static_page_authors
-- table; the URL_STUB during development does not include the ".draft"
-- but is instead the final location where the file will ultimately reside

-- we could key by url_stub but (1) that makes reorganizing
-- the static pages on the server even harder, (2) that bloats
-- out the referring tables

-- we keep an ORIGINAL_AUTHOR (redundant with static_page_authors)
-- when the page was originally created by one particular user
-- will be NULL if we don't have the author in our system

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

create sequence section_link_id_sequence start with 1;
create table content_section_links(
	section_link_id integer primary key,
	from_section_id references content_sections,
	to_section_id references content_sections,
	constraint content_section_links_unique unique(from_section_id, to_section_id)
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









