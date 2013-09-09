-- /www/doc/sql/extensions.sql
--
-- Author: kevin@arsdigita.com
--
-- Data model for a repository of non-aD modules or code
-- designed to complement the ACS.
--
-- extensions.sql,v 3.3 2000/05/17 17:35:19 luke Exp
--

-- Have to define some of the helper tables first because of 
-- referential integrity constraints in the table creation
-- statements

-- Tables to keep track of types of submissions (complete modules,
-- individual procedures, modified pieces of code, etc) and
-- categories of submission (site management tools, user services, etc)

create sequence ext_type_id_sequence;

create table extension_types (
	type_id		integer constraint ext_types_type_id_pk primary key,
	name		varchar(100) constraint ext_types_name_un unique,
	description	varchar(4000)
);

create sequence ext_cat_id_sequence;

create table extension_categories (
	category_id	integer constraint ext_cats_category_id_pk primary key,
	name		varchar(100) constraint ext_cats_name_un unique,
	description	varchar(4000)
);


create sequence extension_id_sequence;

create table extensions (
	extension_id	integer constraint ext_extension_id_pk primary key,
	-- The name of the module
	extension_name	varchar(400) 
			constraint ext_extension_name_un unique 
			constraint ext_extension_name_nn not null,
	-- A shortname we can use to create filenames
	-- We will use this both for the tarball and for
	-- a local copy of the documentation page.
	short_name	varchar(20) 
			constraint ext_short_name_un unique 
			constraint ext_short_name_nn not null,
	-- The person who uploaded this module
	owner_id	constraint ext_owner_id_fk
			references users(user_id) on delete set null,
	-- Date the module was first uploaded
	creation_date	date constraint ext_creation_date_nn not null,
	-- can anyone upload new versions of this extension or is
	-- it limited to a group controlled by the owner?
	scope		varchar(10) constraint ext_scope_nn not null,
	-- if scope=group, this is the permitted group_id
	group_id	constraint ext_group_id_fk references user_groups,
	-- Description of the module
	description	varchar(4000) constraint ext_description_nn not null,
	-- is the description in HTML?
	html_p		char(1) default 'f' 
			constraint ext_html_p_ck check(html_p in ('t','f')),
	-- A canonical example of the module in use
	example_url	varchar(200),
	-- What type of contribution is this?  
	-- Not everything needs to be a full module
	type_id		constraint ext_type_id_fk references extension_types,
	-- What category does this fall into?
	category_id	constraint ext_cat_id_fk 
			references extension_categories,
	-- Versions of the ACS this module works with
	compatability_message	varchar(400),
	-- a module might become obsolete, either because of
	-- conflicts with later version of the ACS or because
	-- its functionality was incorporated into the ACS
	obsolete_p	char(1) default 'f' 
			constraint ext_obsolete_p_ck
			check (obsolete_p in ('t','f')),
	-- ensure consistent state of scope variables
	constraint ext_scope_group_id_ck check ((scope='public') or
		(scope='group' and group_id is not null))
);


-- Tarballs will get named shortname-version_name.tar

create sequence ext_version_id_sequence;

create table extension_versions (
	version_id	integer 
			constraint ext_versions_version_id_pk
			primary key,
	extension_id	constraint ext_versions_extension_id_nn not null 
			constraint ext_versions_extension_id_fk
			references extensions on delete cascade,
	-- a name for the version like 3.2 or 1.0b15
	version_name	varchar(20)
			constraint ext_versions_version_name_nn not null,
	description	varchar(4000) 
			constraint ext_versions_description_nn not null,
	-- is the description HTML?
	html_p		char(1) default 'f' 
			constraint ext_versions_html_p_ck
			check(html_p in ('t','f')),
	submitter_id	constraint ext_versions_submitter_id_fk 
			references users(user_id) on delete set null,
	submitted_date	date 
			constraint ext_versions_submitted_date_nn not null,
	-- file size in bytes
	file_size	integer constraint ext_versions_file_size_nn not null
);



-- Some generic, default types

insert into extension_types
(type_id, name, description)
values
(ext_type_id_sequence.nextval, 'Module', 
'A complete module with data model, documentation, TCL procedures, 
 user and admin pages.');

insert into extension_types
(type_id, name, description)
values
(ext_type_id_sequence.nextval, 'Procedure', 
'A useful procedure suitable for inclusion in ad-custom.tcl.postload.');

insert into extension_types
(type_id, name, description)
values
(ext_type_id_sequence.nextval, 'Code Modification', 
'A patch or set of patches to add or modify functionality in existing
 ACS files.');

insert into extension_types
(type_id, name, description)
values
(ext_type_id_sequence.nextval, 'Other',
'Anything that doesn''t belong in another category.');

-- We want to collect statistics on how many people have downloaded 
-- a module and how recently

create sequence ext_download_id_sequence;

create table extension_downloads (
	download_id	integer 
			constraint ext_downloads_download_id_pk
			primary key,
	user_id		constraint ext_downloads_user_id_fk
			references users on delete set null,
	version_id	constraint ext_downloads_versions_id_fk
			references extension_versions on delete cascade,
	-- the time of the most recent download
	download_time	date 
			constraint ext_downloads_download_time_nn not null,
	-- how does this person rate this module?
	rating		integer 
			constraint ext_downloads_rating_ck
			check (rating between 0 and 10)
);


-- We ought to create some views (possibly materialized) for things like
-- most frequently downloaded modules, newest modules, most highly rated
-- modules, new changes

create or replace view current_versions
as
select * 
from   extension_versions v1
where  submitted_date = (select max(submitted_date)
			 from   extension_versions v2
			 where  v1.extension_id = v2.extension_id);

create or replace function current_version
  (id IN integer)
return varchar
AS
  current_version_name extension_versions.version_name%TYPE;
  current_version_date date;
BEGIN
  select max(submitted_date) into current_version_date
    from extension_versions
    where extension_id = id;

  select version_name into current_version_name
    from extension_versions
    where submitted_date = current_version_date
    and   extension_id = id;

  return current_version_name;
END;
/
show errors


-- It is debatable whether this is actually the right way to average
-- the ratings.

create or replace function ext_rating
  (id IN integer)
return number
AS
  rating number;
BEGIN
  select avg(rating) into rating
    from extension_downloads ed
    where ed.version_id in (select version_id from extension_versions ev
                            where ev.extension_id = id);
  return rating;
END;
/
show errors


-- Should this be per extension or per version?

create or replace function n_downloads
  (id IN integer)
return integer
AS
  num integer;
BEGIN
  select count(*) into num
    from extension_downloads ed
    where ed.version_id in (select version_id from extension_versions ev
                            where ev.extension_id = id);
  return num;
END;
/
show errors


-- can't make this view work the way I want
--
--create or replace view extension_statistics
--as
--select e.extension_id,
--	 count(*) as n_downloads, 
--	 avg(rating) as rating
--from   extensions e, extension_downloads ed
--where  ed.version_id in (select ev.version_id from extension_versions ev
--			   where ev.extension_id = e.extension_id)
--group by e.extension_id;


-- insert for general_comments and site-wide search

insert into table_acs_properties
  (table_name, section_name, user_url_stub, admin_url_stub)
values
  ('extensions', 'Toolkit Extensions',
   '/extensions/one.tcl',
   '/extensions/admin/one.tcl');


-- create a new group type

insert into user_group_types
(group_type, pretty_name, pretty_plural, approval_policy, 
 default_new_member_policy, group_module_administration, user_group_types_id)
values
('extensions','Toolkit Extensions','Toolkit Extension Groups','open',
 'closed','none', user_group_types_seq.nextval);

-- need this table or some user group functions get upset

create table extensions_info (
	group_id	integer
			constraint ext_info_group_id_fk references user_groups
			constraint ext_info_group_id_nn not null
);

-- there should be some triggers to create the necessary
-- projects/feature areas in the ticket tracker. 

-- Extension category = ticket project
-- Extension = ticket feature


create table ext_cat_ticket_proj_map (
	category_id	integer
			constraint ectpm_category_id_fk 
			  references extension_categories on delete cascade
			constraint ectpm_category_id_nn not null
			constraint ectpm_category_id_un unique,
	project_id	integer
			constraint ectpm_project_id_fk
			  references ticket_projects on delete set null
			constraint ectpm_project_id_nn not null
			constraint ectpm_project_id_un unique
);

create table ext_ticket_domain_map (
	extension_id	integer
			constraint etdm_extension_id_fk references extensions
			  on delete cascade
			constraint etdm_extension_id_nn not null
			constraint etdm_extension_in_un unique,
	domain_id	integer
			constraint etdm_domain_id_fk references ticket_domains
			  on delete set null
			constraint etdm_domain_id_nn not null
			constraint etdm_domain_id_un unique
);

create or replace trigger ext_cat_ticket_tr
  after insert or update on extension_categories for each row
DECLARE
  new_project_id integer;
BEGIN
  IF inserting THEN
    select ticket_project_id_sequence.nextval into new_project_id from dual;
  
    insert into ticket_projects
      (project_id, title, title_long, created_by, start_date, public_p,
       description, code_set, default_mode)
    values
      (new_project_id, substr(:new.name,1,30), :new.name,
       1,sysdate,'t',:new.description, 'ad', 'full');
  
    insert into ext_cat_ticket_proj_map
      (category_id,project_id)
    values
      (:new.category_id,new_project_id);

  ELSE
    update ticket_projects
      set title       = substr(:new.name,1,30), 
          title_long  = :new.name, 
          description = :new.description
      where project_id = (select project_id from ext_cat_ticket_proj_map
                          where category_id = :old.category_id);

  END IF;
END;
/
show errors

-- deletions must be done before.  Unfortunately, I don't think a deletion
-- of a ticket project will work in general anyways.  I think the
-- ticket tracker will choke.


create or replace trigger ext_ticket_tr
  after insert or update or delete on extensions for each row
DECLARE
  new_domain_id integer;
BEGIN
  IF inserting THEN
    select ticket_domain_id_sequence.nextval into new_domain_id from dual;
  
    insert into ticket_domains
      (domain_id, title, title_long, created_by, default_assignee,
       group_id, public_p, description)
    values
      (new_domain_id, :new.short_name, substr(:new.extension_name,0,100),
       :new.owner_id, :new.owner_id, :new.group_id, 't', :new.description);
  
    insert into ticket_domain_project_map
      (project_id,domain_id)
    select project_id, new_domain_id
      from ext_cat_ticket_proj_map
      where category_id = :new.category_id;
  
    insert into ext_ticket_domain_map
      (extension_id,domain_id)
    values
      (:new.extension_id,new_domain_id);

  ELSIF updating THEN
    update ticket_domains
    set title = :new.short_name,
        title_long = substr(:new.extension_name,0,100),
        description = :new.description
    where domain_id = (select domain_id from ext_ticket_domain_map
                       where extension_id = :old.extension_id);

    update ticket_domain_project_map
    set project_id = (select project_id from ext_cat_ticket_proj_map
                      where category_id = :new.category_id)
    where domain_id = (select domain_id from ext_ticket_domain_map
                       where extension_id = :old.extension_id);

  -- ELSE  -- deleting
    -- again, this won't work.  However since we currently offer people
    -- the ability to delete extensions, I don't want to put code
    -- here that will break that capability.

  END IF;
END;
/
show errors
  




