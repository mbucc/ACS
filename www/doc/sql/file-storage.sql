--
-- file-storage.sql
--
-- created June 1999 by aure@arsdigita.com and dh@arsdigita.com
-- 

-- modified January 2000 by randyg@arsdigita.com
-- All permissions are now taken care of by the general-permissions module
-- (general-permissions.sql).  Permissions are per version.

create sequence fs_file_id_seq;

create table fs_files (
	file_id			integer primary key,
	file_title		varchar(500) not null,
	-- sort_key and depth help us with displaying contents quickly
        sort_key		integer not null,
        depth                   integer not null,
	folder_p		char(1) default 'f' check (folder_p in ('t','f')),
	-- the group_id and public_p are used solely for display purposes
        -- if there is a group_id then we display this file under the group folder
	group_id                integer references user_groups(group_id),
	-- if public_p is 't' we show the file in the public folder
	public_p                char(1) default 'f' check (public_p in ('t','f')),
	-- if group_id is null and public_p <> 't'
	-- the folder or document is in the users' tree
	owner_id		integer not null references users(user_id),
	deleted_p		char(1) default 'f' check (deleted_p in ('t','f')),
	-- parent_id is null for top level items
	parent_id		integer references fs_files(file_id)
);

-- Oracle appears to not like composite indices because it messes up
-- the primary key index. We index the foreign key columns for the
-- connect by. (richardl@arsdigita.com, 26 September 2000).
create index fs_files_parent_id on fs_files(parent_id);

-- folders are also stored in fs_versions so that general_permissions can be
-- wrapped around the folders as well.  This way, is someone ever wants to 
-- put permissions on folders the functionality will already be in place.

create sequence fs_version_id_seq;

create table fs_versions (
	version_id		integer primary key,
	-- this is a version of the file key defined by file_key
	file_id			integer not null references fs_files,
	-- this is where the actual content is stored
	version_content		blob,
	-- description can be keywords, version notes, etc.
	version_description 	varchar(500),
	creation_date		date not null,
	author_id		integer not null references users(user_id),
	-- file name including extension but not path
	client_file_name	varchar(500),
	file_type		varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	file_extension		varchar(50), 	-- e.g., "jpg"
	-- this value is null for the most recent version or equal to the id 
        -- of the version that supersedes this one
	superseded_by_id	integer references fs_versions(version_id),
	-- can be useful when deciding whether to present all of something
	n_bytes			integer,
	-- added so we can store URLs
	url			varchar(200)
);

-- we'll often be asking "show me all the versions of file #4"
create index fs_versions_by_file on fs_versions(file_id);

create or replace view fs_versions_latest 
as
select * from fs_versions where superseded_by_id is null;


-- lets create an easy way to walk the tree so that we can join the connect by
-- with the permissions tables

create or replace view fs_files_tree
as
select
   file_id,	
   file_title,
   sort_key,
   depth,   
   folder_p,
   owner_id,
   deleted_p,
   group_id,
   public_p,
   parent_id,
   level as the_level
from fs_files
connect by prior fs_files.file_id = parent_id
start with parent_id is null;


-- if you have Intermedia installed (Oracle 8i only + additional
-- sysadmin/dbadmin nightmares)

-- create index fs_versions_content_idx 
-- on fs_versions (version_content)
-- indextype is ctxsys.context;

-- Seed the general_permission_types table with data for
-- administering permissions on this module (markc@arsdigita.com)
--
insert into general_permission_types (
    table_name,
    permission_type
) values (
    'FS_VERSIONS',
    'read'
);

insert into general_permission_types (
    table_name,
    permission_type
) values (
    'FS_VERSIONS',
    'write'
);

insert into general_permission_types (
    table_name,
    permission_type
) values (
    'FS_VERSIONS',
    'comment'
);

insert into general_permission_types (
    table_name,
    permission_type
) values (
    'FS_VERSIONS',
    'owner'
);
