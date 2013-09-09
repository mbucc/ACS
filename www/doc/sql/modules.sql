-- Filename
--  /doc/sql/modules.sql
-- 
-- Author
--  Tarik <tarik@arsdigita.com>
--
-- Date
--  12/22/1999
--
-- Purpose
--  Data model for ACS modules
--
-- Version
--  modules.sql,v 3.2 2000/06/17 18:49:35 ron Exp
--

-- The acs_modules table contains information on all the modules registered with the
-- ad_module_register procedure. It is part of the core toolkit because the modules that call
-- ad_module_register depend on it. 
-- We don't give this table an integer primary key because it is referenced by
-- user_group_types_module_map and content_sections.

create table acs_modules (
	module_key		varchar(30) primary key,
	pretty_name		varchar(200) not null,
	-- this is the directory where module public files are stored. 
	-- for the news module public_directory would be /news
	-- can be a Tcl list of filenames
	public_directory	varchar(200),
	-- this is the directory where module admin files are stored
	-- for the news module admin_directory would be /admin/news
	-- can be a Tcl list of filenames
	admin_directory		varchar(200),
	-- this is the directory where system admin files are stored 
	-- notice that this is not always same as the admin_directory
	-- e.g. ticket module has admin directory /ticket/admin and
	-- site admin directory /admin/ticket
	-- can be a Tcl list of filenames
	site_wide_admin_directory	varchar(200),
	-- if module_type=system, this module has all: public, admin and site_wide admin pages (e.g. faq, news)
	-- notice that often admin and site_wide admin directory are merged together
	-- if module_type=admin, this is admin module and has no public pages (e.g. display, content_sections)
	-- notice that modules of this type have no public pages
	-- if module_type=site_wide_admin, this is module for site wide administration of another module (e.g. news_admin, bboard_admin)
	-- notice that having admin module for another module allows us to assign administration of modules to user groups
	-- in this case public_directory will correspond to the directory where files for site wide administration of that
	-- module are stored and admin_directory and site_wide_admin_directory are irrelevant 
	module_type                    varchar(20) default 'system' not null check(module_type in ('system', 'admin', 'site_wide_admin')),
	-- does module support scoping
	supports_scoping_p	char(1) default 'f' check(supports_scoping_p in ('t','f')),
	-- this is short description describing what module is doin
	description		varchar(4000),
	-- this is url of the html file containing module documentation
	-- can be a Tcl list of filenames
	documentation_url	varchar(200),
	-- this is url of the file containing date model of the module
	-- can be a Tcl list of filenames
	data_model_url		varchar(200),
	-- The registered_p flag is set to true if this module called ad_module_register when the
	-- private Tcl was last initialized
	registered_p		char(1) default 'f' check(registered_p in ('t','f')),
	-- version string for the module
	version			varchar(30),
	-- space separated list of email addresses of people responsible for a module
	owner_email_list		varchar(2000),
	-- cvs_host is the host that holds the CVS repository for the module which 
	-- can be used for auto-installs and upgrades
	cvs_host			varchar(400),
	-- Any file globbing patterns that can be used to uniquely identify files in this
	-- module that are not in the public, admin or site wide admin directories
	additional_paths		varchar(2000),
	-- web server where the bboard is held eg. www.arsdigita.com
	bboard_server			varchar(2000),
	-- web server where the Ticket Tracker is held for this module. www.arsdigita.com
	ticket_server			varchar(2000)
);


-- The insert statements directly into acs_modules should no longer be necessary because we have
-- an API ad_register_module that gets called in the module-name-defs.tcl files to do this job.
-- However, if we do delete the insert statements it breaks the install scripts. The reason is that
-- other scripts depend on having rows present in the acs_modules table otherwise they give
-- an error. 

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

insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)
values
('calendar', 'Calendar', '/calendar', '/calendar/admin', '/admin/calendar', 'system', 't', '/doc/calendar.html', '/doc/sql/calendar.sql', 'A site like photo.net might want to offer a calendar of upcoming events. This has nothing to do with displaying things in a wall-calendar style format, as provided by the calendar widget. In fact, a calendar of upcoming events is usually better presented as a list. ');


insert into acs_modules
(module_key, pretty_name, public_directory, admin_directory, site_wide_admin_directory, module_type, supports_scoping_p, documentation_url, data_model_url, description)
values
('chat', 'Chat', '/chat', '/chat/admin', '/admin/chat', 'system', 't', '/doc/chat.html', '/doc/sql/chat.sql', 'Why is a chat server useful? As traditionally conceived, it isnt. The Internet is good at coordinating people who are separated in space and time. If a bunch of folks could all
agree to meet at a specific time, the telephone would probably be a better way to support their interaction.');


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


