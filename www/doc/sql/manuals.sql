-- /www/doc/sql/manuals.sql
--
-- Author: kevin@caltech.edu, January 1999
-- Modified by: aure@arsdigita.com, ron@arsdigita.com
--
-- Tables for the online manual system allowing features like
-- automatic table of contents generation, rearrangement of sections,
-- interface with HTMLDOC, etc.
--
-- manuals.sql,v 3.3 2000/06/17 18:49:35 ron Exp

create sequence manual_id_sequence;

create table manuals (
	manual_id		integer primary key,
	-- title of the manual
	title			varchar(500) not null unique,
	-- compact title used to generate file names, e.g. short_name.pdf
	short_name		varchar(100) not null unique,
	-- person responsible for the manual (editor-in-chief)
	owner_id		references users(user_id) not null,
	-- a string containing the author or authors which will
	-- be included on the title page of the printable version
	author			varchar(500),
	-- copyright notice (may be null)
	copyright		varchar(500),
	-- string describing the version and/or release date of the manual
	version			varchar(500),
	-- if scope=public, this manual is viewable by anyone
	-- if scope=group, this manual is restricted to group members
	scope			varchar(20) not null,
	-- if scope=group, this is the owning group_id
	group_id		references user_groups,
	-- is this manual currently active?
	active_p		char(1) default 'f' check (active_p in ('t','f')),
	-- notify the editor-in-chief on all changes to the manual
	notify_p		char(1) default 't' check (notify_p in ('t','f')),
	-- insure consistent state
	constraint manual_scope_check check ((scope='group' and group_id is not null)
	                                     or (scope='public'))
);

create sequence manual_section_id_sequence;

create table manual_sections (
	section_id		integer primary key,
	-- which manual this section belongs to
	manual_id		integer references manuals not null,
	-- a string we use for cross-referencing this section
	label			varchar(100),
	-- used to determine where this section fits in the document hierarchy
	sort_key		varchar(50) not null,
	-- title of the section
	section_title		varchar(500) not null,
	-- user who first created the section
	creator_id		references users(user_id) not null,
	-- notify the creator whenever content is edited?
	notify_p		char(1) default 'f' check (notify_p in ('t','f')),
	-- user who last edited content for this section
	last_modified_by	references users(user_id),
	-- is there an html file associated with this section?
	content_p		char(1) default 'f' check (content_p in ('t','f')),
	-- determines whether a section is displayed on the user pages
	active_p		char(1) default 't' check (active_p in ('t','f')),
	-- we may want to shorten the table of contents by not displaying all sections
	display_in_toc_p 	char(1) default 't' check (display_in_toc_p in ('t','f')),
	-- make sure that sort_keys are unique within a give manual
	unique(manual_id,sort_key)
	-- want to add the following but can't figure out the syntax
	-- contraint manual_label_check check ((label is null) or (unique(manual_id,label))
);

-- a view to generate the list of all chapters (top-level sections)

create or replace view chapters
as
select   manual_id, section_id, section_title
from     manual_sections
where    length(sort_key) = 2
and      active_p = 't'
order by sort_key;

-- a view to generate the navigation controls

create or replace view section_neighbors 
as
select  s0.section_id,
(select s1.section_id 
 from   manual_sections s1
 where  s0.manual_id = s1.manual_id
 and    s1.sort_key  = (select max(s2.sort_key)
                        from   manual_sections s2
                        where  s0.manual_id = s2.manual_id
                        and    s0.sort_key  > s2.sort_key
                        and    s2.active_p  = 't'
                        and    s2.content_p = 't')) as prev_section_id,
(select s1.section_id 
 from   manual_sections s1
 where  s0.manual_id = s1.manual_id
 and    s1.sort_key  = (select min(s2.sort_key)
                        from   manual_sections s2
                        where  s0.manual_id = s2.manual_id
                        and    s0.sort_key  < s2.sort_key
                        and    s2.active_p  = 't'
                        and    s2.content_p = 't')) as next_section_id
from    manual_sections s0;

-- figures table

create sequence manual_figure_id_sequence;

create table manual_figures (
	figure_id		integer primary key,
	-- the manual this figure belongs to	
	manual_id		references manuals not null,
	-- a string we use for cross-referencing this figure
	label			varchar(100) not null,
	-- caption for the figure
	caption			varchar(4000),
	-- auto-generated sorting key, also serves as figure number
	sort_key		integer not null,
	-- flag to indicate whether the figure is numbered or just a stored image 
	numbered_p		char(1) default 't' check (numbered_p in ('t','f')),
	-- MIME type of the image (image/gif, image/jpeg, etc.)
	file_type		varchar(100) not null,
	-- image size
	height			integer not null,
	width			integer not null,
	-- additional contraints
	-- unique(manual_id,sort_key),
	unique(manual_id,label)
);


-- Add to table_acs_properties so general comments works

insert into table_acs_properties
  (table_name, section_name, user_url_stub, admin_url_stub)
values
  ('manual_sections', 'Manuals', 
   '/manuals/section-view.tcl?section_id=',
   '/manuals/admin/section-edit?section_id=');

  

commit;