-- /www/doc/sql/upgrade-3.4.4-3.4.5.sql
--
-- Script to upgrade an ACS 3.4.5 database to ACS 3.4.6
-- 
-- upgrade-3.4.5-3.4.6.sql,v 1.1.2.6 2000/10/13 21:23:15 kevin Exp


-- Use with caution! The below commands fix some primary key index
-- corruption errors under Oracle in file storage. However, they are
-- not transactional and they disable the PK for a little while while
-- the index is dropped, so duplicate PKs MAY be entered while you are
-- recreating the PK. richardl@arsdigita.com, 26 September 2000.

-- drop all the constraints and indices we don't want.
alter table fs_files drop primary key cascade;
drop index fs_files_idx2;
drop index fs_files_idx1;

-- add the primary key back in
alter table fs_files add constraint pk_fs primary key(file_id);
-- add the foreign key back in
alter table fs_files add constraint fk_fs_parent_id_file_id foreign key (parent_id) references fs_files(file_id);
-- recreate the other index
create index fs_files_parent_id_idx on fs_files(parent_id);



--
-- INTRANET
--
-- add back in things that really shouldn't have been dropped
--

declare
    v_count	integer;
begin

    select count(*) into v_count
    from   user_tables
    where  table_name = 'IM_PROJECT_URL_MAP';

    if v_count = 0 then

	execute immediate 'create table im_project_url_map (
	    group_id		not null references im_projects,
	    url_type_id		not null references im_url_types,
	    url			varchar(250),
	    primary key (group_id, url_type_id)
        )';

	execute immediate 'create index im_proj_url_url_proj_idx on im_project_url_map(url_type_id, group_id)';

    end if;

end;
/
show errors

create or replace function im_proj_url_from_type ( v_group_id IN integer, v_url_type IN varchar )
return varchar
IS 
  v_url 		im_project_url_map.url%TYPE;
BEGIN
  begin
    select url into v_url 
      from im_url_types, im_project_url_map
     where group_id=v_group_id
       and im_url_types.url_type_id=im_project_url_map.url_type_id
       and url_type=v_url_type;
  exception when others then null;
  end;
  return v_url;
END;
/
show errors;


