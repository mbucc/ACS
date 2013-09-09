--
-- /www/doc/sql/table-metadata.sql
--
-- This is the main table containing metadata about tables in the system.  Currently it's used
-- only by the general permissions administration, in order to generate UI
--
-- Author: markc@arsdigita.com, March 2000
-- 
-- table-metadata.sql,v 3.1 2000/03/12 00:09:03 markc Exp
--

create table general_table_metadata (
    table_name varchar(30) primary key,
    -- pretty name for the type of object that inhabits this table. e.g. "user group"
    pretty_table_name_singular varchar(50) not null,
    -- same as above, but plural. e.g. "user groups"
    pretty_table_name_plural varchar(50) not null,
    id_column_name varchar(50) not null,
    -- the name of a view created by joining this row with others that might
    -- be useful for viewing, sorting, selecting on, etc.
    -- if you don't have anything to join in, you can set this equal to the table name
    denorm_view_name varchar(30) not null,
    -- either a column from the denorm view or a valid SQL select
    -- list item e.g. "first_names || ' '|| last_name" for the
    -- users table.  This should be displayable in a single line.
    one_line_row_descriptor varchar(4000) not null
);

--
-- this table lists the columns from the denormalized 
-- view that should be included in a standard view of the record
--


create table table_metadata_denorm_columns (
    table_name varchar(30) references general_table_metadata,
    -- this is a column in the denormalized view, not the base table
    column_name varchar(50) not null,
    column_pretty_name varchar(50) not null,
    display_ordinal integer not null,
    is_date_p char(1) default 'f' check (is_date_p in ('t','f')),
    use_as_link_p char(1) default 'f' check (use_as_link_p in ('t','f')),
    primary key(table_name,column_name)
);


create view fs_versions_denorm_view as (
    select
        fs_versions.file_id,
        file_title,
        folder_p,
        owner_id,
        public_p,
        fs_versions.version_id,
        version_description,
        creation_date,
        client_file_name,
        file_type,
        file_extension,
        n_bytes, 
        author_id,
        author_user.first_names || ' ' || author_user.last_name as author_name,
        owner_user.first_names || ' ' || owner_user.last_name as owner_name,
        deleted_p
    from
        fs_versions,
        fs_files,
        users author_user,
        users owner_user
    where
        fs_versions.author_id = author_user.user_id and
        fs_files.owner_id = owner_user.user_id and
        fs_versions.file_id = fs_files.file_id
);


insert into general_table_metadata (
    table_name,
    pretty_table_name_singular,
    pretty_table_name_plural,
    id_column_name,
    denorm_view_name,
    one_line_row_descriptor
) values (
    'FS_VERSIONS',
    'stored file version',
    'stored file versions',
    'VERSION_ID',
    'FS_VERSIONS_DENORM_VIEW',
    'file_title || '' '' || author_name'   
);




insert into table_metadata_denorm_columns (
    table_name,
    column_name,
    column_pretty_name,
    display_ordinal,
    is_date_p
) values (
    'FS_VERSIONS',
    'version_id',
    'Version ID',
    0,
    'f'
);


insert into table_metadata_denorm_columns (
    table_name,
    column_name,
    column_pretty_name,
    display_ordinal,
    is_date_p,
    use_as_link_p
) values (
    'FS_VERSIONS',
    'file_title',
    'File Title',
    1,
    'f',
    't'
);

insert into table_metadata_denorm_columns (
    table_name,
    column_name,
    column_pretty_name,
    display_ordinal,
    is_date_p
) values (
    'FS_VERSIONS',
    'author_name',
    'Author Name',
    2,
    'f'
);

insert into table_metadata_denorm_columns (
    table_name,
    column_name,
    column_pretty_name,
    display_ordinal,
    is_date_p
) values (
    'FS_VERSIONS',
    'creation_date',
    'Creation Date',
    3,
    't'
);

insert into table_metadata_denorm_columns (
    table_name,
    column_name,
    column_pretty_name,
    display_ordinal,
    is_date_p
) values (
    'FS_VERSIONS',
    'version_description',
    'Version Description',
    4,
    'f'
);


























