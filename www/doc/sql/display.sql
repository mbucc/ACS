-- File:     /doc/sql/display.sql
-- Date:     12/26/1999
-- Contact:  tarik@arsdigita.com
-- Purpose:  data model for the display module
--           this module supports cascaded style sheets and logos

-- notice that these two separate data models will be merged into 
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












