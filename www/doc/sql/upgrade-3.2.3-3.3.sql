-- /www/doc/sql/upgrade-3.2-3.3.sql
--
-- Script to upgrade an ACS 3.2 database to ACS 3.3
--
-- *NOTE* that everything in this file should be cut-and-pasted
-- rather than loaded with the "@" command.  This is because 
-- the files referenced may change between versions but the upgrade
-- script must not change (i.e. if I need to do an upgrade from 
-- 3.2.1 to some future 3.3.2, I should be able to apply every upgrade 
-- script and have it work.  This would not work if the files were
-- included via @ in one version and then changed in a later version.)
--
--
-- upgrade-3.2.3-3.3.sql,v 3.3.2.1 2000/07/29 21:15:12 ron Exp

set scan off

-- BEGIN USER_GROUP_TYPE_MODULE_ADD

-- we need to associate modules with user group types. The following procedure
-- creates the mapping between the user_group_type and the module_key and updates
-- all user groups of the specified type that do not already have the associated
-- module
create or replace procedure user_group_type_module_add ( p_group_type IN varchar,  
							 p_module_key IN varchar ) 
IS
    v_module_pretty_name		acs_modules.pretty_name%TYPE;  
    v_section_type			varchar(100);
    v_group_id				user_groups.group_id%TYPE;
    v_section_key			varchar(100);

    -- Prepare the cursor to pull out all the user groups we need to modify

    CURSOR c_groups_to_update ( v_group_type IN varchar, v_module_key IN varchar ) IS
      	select ug.group_id, uniq_group_module_section_key(v_module_key, ug.group_id) 
          from user_groups ug
         where ug.group_type=v_group_type
	   and not exists (select 1 
                             from content_sections cs
                      	    where cs.scope='group'
                      	      and cs.group_id=ug.group_id
                      	      and cs.module_key=v_module_key)
 	   for update;

BEGIN

    BEGIN
	-- pull out the pretty name and section type from the acs_modules table.
	-- If we get an exception, then the specified module doesn't exist - 
	-- Return right away as we can't really do anything else!
    	select pretty_name, section_type_from_module_key(module_key) into v_module_pretty_name, v_section_type
      	  from acs_modules 
         where module_key=p_module_key;
        EXCEPTION WHEN OTHERS THEN 
            raise_application_error(-20000, 'Module key ' || p_module_key || ' not found in acs_modules tables');
    END;
 
    -- We take special care here not to remap the same module key twice! This means
    -- re-running this procedure for the same group_type/module_key will have no 
    -- side-effects
    insert into user_group_type_modules_map
    (group_type_module_id, group_type, module_key)
    select group_type_modules_id_sequence.nextval, p_group_type, p_module_key 
      from dual
     where not exists (select 1 
                         from user_group_type_modules_map
                        where group_type=p_group_type
                          and module_key=p_module_key);


    -- Now we need to select out all the groups of this group_type which do not already have this
    -- module installed. 

    open c_groups_to_update (p_group_type, p_module_key);

    LOOP 
    	FETCH c_groups_to_update into v_group_id, v_section_key;
    	EXIT WHEN c_groups_to_update%NOTFOUND;    

	-- associate the specified module key with the user group
	insert into content_sections
	(section_id, scope, section_type, requires_registration_p, visibility, group_id, 
	 section_key, module_key, section_pretty_name, enabled_p)
	values
	(content_section_id_sequence.nextval, 'group', v_section_type, 'f', 'public', v_group_id, 
	 v_section_key, p_module_key, v_module_pretty_name, 't');

    END LOOP;

END;
/ 
show errors;

-- END USER_GROUP_TYPE_MODULE_ADD

-- BEGIN APM
-- apm_packages contains one row for each package we know about, e.g.,
-- acs-core, bboard, etc.
create table apm_packages (
    package_id         integer
                       constraint apm_packages_package_id_pk primary key,
    -- package_key is what we call the package on this system.
    package_key        varchar(100)
                       constraint apm_packages_package_key_nn not null
                       constraint apm_packages_package_key_un unique,
    -- a unique identifier for the package
    package_url        varchar(1500)
                       constraint apm_packages_package_url_nn not null
                       constraint apm_packages_package_url_un unique,
    -- the path and mtime of the .info file (if any), last we checked
    spec_file_path     varchar(1500),
    spec_file_mtime    integer
);
create sequence apm_package_id_seq;

-- apm_package_versions contains one row for each version of each package
-- we know about, e.g., acs-core-3.3, acs-core-3.3.1, bboard-1.0,
-- bboard-1.0.1, etc.
create table apm_package_versions (
    version_id         integer
                       constraint apm_package_vers_id_pk primary key,
    package_id         constraint apm_package_vers_package_id_fk references apm_packages
                       constraint apm_package_vers_package_id_nn not null,
    package_name       varchar(500)
                       constraint apm_package_vers_pkg_name_nn not null,
    -- the version number (must adhere to the naming conventions listed in the
    -- package manager documentation). Perhaps we want a trigger to verify this?
    version_name       varchar(100)
                       constraint apm_package_vers_ver_name_nn not null,
    -- a unique identifier for the version
    version_url        varchar(1500)
                       constraint apm_package_vers_ver_url_nn not null
                       constraint apm_package_vers_ver_url_un unique,
    summary 	       varchar(3000),
    -- MIME content type for the description
    description_format varchar(100),
    description        clob,
    -- is the package part of a particular distribution, like ACS 3.3?
    distribution       varchar(500),
    release_date       date,
    vendor             varchar(500),
    vendor_url         varchar(1500),
    -- is the package in a logical group of packages?
    package_group      varchar(100),
    --
    -- information about the local state:
    --
    --   enabled_p = is the version scheduled to be loaded at startup?
    --   installed_p = is the version actually present in the filesystem?
    --   tagged_p = have we ever assigned all the files in this version
    --       a CVS tag?
    --   imported_p = did we perform a vendor import on this version?
    --   data_model_loaded_p = have we brought the data model up to date
    --       for this version?
    --
    enabled_p          char(1) default 'f'
                       constraint apm_package_vers_enabled_p_nn not null
                       constraint apm_package_vers_enabled_p_ck check(enabled_p in ('t','f')),
    installed_p        char(1) default 'f'
                       constraint apm_package_vers_inst_p_nn not null
                       constraint apm_package_vers_inst_p_ck check(installed_p in ('t','f')),
    tagged_p           char(1) default 'f'
                       constraint apm_package_vers_tagged_p_nn not null
                       constraint apm_package_vers_tagged_p_ck check(tagged_p in ('t','f')),
    imported_p         char(1) default 'f'
                       constraint apm_package_vers_imp_p_nn not null
                       constraint apm_package_vers_imp_p_ck check(imported_p in ('t','f')),
    data_model_loaded_p char(1) default 'f'
                       constraint apm_package_vers_dml_p_nn not null
                       constraint apm_package_vers_dml_p_ck check(data_model_loaded_p in ('t','f')),
    -- if imported_p = 't', the results of the CVS import, since we really
    -- don't want to perform the import twice
    cvs_import_results clob,
    -- when was the version enabled?
    activation_date    date,
    -- when was the version disabled?
    deactivation_date  date,
    -- the .apm file
    distribution_tarball blob,
    -- where was the distribution tarball downloaded from, and when?
    -- distribution_url is null if generated on this system
    distribution_url   varchar(1500),
    distribution_date  date,
    constraint apm_package_vers_id_name_un unique(package_id, version_name)
);
create sequence apm_package_version_id_seq;

-- which services are provided/required by a particular version?
create table apm_package_dependencies (
    dependency_id      integer 
                       constraint apm_package_deps_id_pk primary key,
    version_id         constraint apm_package_deps_version_id_fk references apm_package_versions on delete cascade
                       constraint apm_package_deps_version_id_nn not null,
    dependency_type    varchar(20)
                       constraint apm_package_deps_type_nn not null
                       constraint apm_package_deps_type_ck check(dependency_type in ('provides','requires')),
    service_url        varchar(1500)
                       constraint apm_package_deps_url_nn not null,
    -- version must adhere to version-naming conventions
    service_version    varchar(100)
                       constraint apm_package_deps_ver_name_nn not null,
    constraint apm_package_deps_un unique(version_id, service_url)
);
create sequence apm_package_dependency_id_seq;

-- which packages are included by a version?
create table apm_package_includes (
    include_id         integer
                       constraint apm_package_incls_pk primary key,
    version_id         constraint apm_package_incls_ver_id_fk references apm_package_versions on delete cascade
                       constraint apm_package_incls_ver_id_nn not null,
    version_url        varchar(1500)
                       constraint apm_package_incls_ver_url_nn not null,
    constraint apm_package_incls_vers_url_un unique(version_id, version_url)
);
create sequence apm_package_include_id_seq;

-- A list of all the different kinds of files.
create table apm_package_file_types (
    file_type_key      varchar(50)
                       constraint apm_package_file_types_pk primary key,
    pretty_name        varchar(200)
                       constraint apm_package_file_types_name_nn not null
);
insert into apm_package_file_types(file_type_key, pretty_name) values('documentation', 'Documentation');
insert into apm_package_file_types(file_type_key, pretty_name) values('tcl_procs', 'Tcl procedure library');
insert into apm_package_file_types(file_type_key, pretty_name) values('tcl_init', 'Tcl initialization');
insert into apm_package_file_types(file_type_key, pretty_name) values('content_page', 'Content page');
insert into apm_package_file_types(file_type_key, pretty_name) values('package_spec', 'Package specification');
insert into apm_package_file_types(file_type_key, pretty_name) values('data_model', 'Data model');
insert into apm_package_file_types(file_type_key, pretty_name) values('data_model_upgrade', 'Data model upgrade');
insert into apm_package_file_types(file_type_key, pretty_name) values('template', 'Template file');
insert into apm_package_file_types(file_type_key, pretty_name) values('shell', 'Shell utility');

-- Which files are contained in a version?
create table apm_package_files (
    file_id            integer
                       constraint apm_package_files_id_pk primary key,
    version_id         constraint apm_package_files_ver_id_fk references apm_package_versions on delete cascade
                       constraint apm_package_files_ver_id_nn not null,
    -- the relative path of the file, *not* containing "packages" or the
    -- package key. e.g., packages/address-book/www/index.tcl would have
    -- 'www/index.tcl' as a path.
    path               varchar(1500)
                       constraint apm_package_files_path_nn not null,
    -- the file type can be null if not known
    file_type          constraint apm_package_files_type_fk references apm_package_file_types,
    constraint apm_package_files_un unique(version_id, path)
);
create sequence apm_package_file_id_seq;
create index apm_package_files_by_path on apm_package_files(path);
create index apm_package_files_by_version on apm_package_files(version_id);

create or replace view apm_file_info as
    select f.*, p.package_key, 'packages/' || p.package_key || '/' || f.path full_path
    from   apm_package_files f, apm_package_versions v, apm_packages p
    where  f.version_id = v.version_id
    and    v.package_id = p.package_id;

-- Who owns a version?
create table apm_package_owners (
    version_id         constraint apm_package_owners_ver_id_fk references apm_package_versions on delete cascade,
    -- if the url is an email address, it should look like 'mailto:alex@arsdigita.com'
    owner_url          varchar(1500),
    owner_name         varchar(200)
                       constraint apm_package_owners_name_nn not null,
    sort_key           integer
);

create or replace view apm_package_version_info as
    select p.package_key, p.package_url, v.version_id, v.package_id, v.package_name, v.version_name,
           v.version_url, v.summary, v.description_format, v.description, v.distribution, v.release_date,
           v.vendor, v.vendor_url, v.package_group, v.enabled_p, v.installed_p, v.tagged_p, v.imported_p, v.data_model_loaded_p,
           v.activation_date, v.deactivation_date,
           dbms_lob.getlength(distribution_tarball) tarball_length,
           distribution_url, distribution_date
    from   apm_packages p, apm_package_versions v
    where  v.package_id = p.package_id;

create or replace view apm_enabled_package_versions as
    select * from apm_package_version_info
    where  enabled_p = 't';

create or replace procedure apm_register_file(v_version_id in integer, v_path in varchar, v_file_type in varchar) is
begin
    insert into apm_package_files(file_id, version_id, path, file_type)
        select apm_package_file_id_seq.nextval, v_version_id, v_path, v_file_type from dual
        where not exists (select 1 from apm_package_files where path = v_path and version_id = v_version_id);
end;
/
show errors

-- Turns a version number into something which can be ordered lexicographically.
-- We tokenize the version name into numbers and letters, turning each token into
-- a four-character block followed by a period:
--
--   any number  => that number, zero-padded
--     'd'       => '  0D'
--     'a'       => '  1A'
--     'b'       => '  2B'
--   (no letter) => '  3F' at end of string (indicating released version)
--
-- e.g., 3.3a10 would turn into '0003.0003.  1A.0010.'
--       3.3    would turn into '0003.0003.  3F.'
create or replace function apm_version_order(v_version_name in varchar) return varchar is
    a_start integer;
    a_end   integer;
    a_order varchar(1000);
    a_char  char(1);
    a_seen_letter char(1) := 'f';
begin
    a_start := 1;
    loop
        a_end := a_start;

        -- keep incrementing a_end until we run into a non-number        
        while substr(v_version_name, a_end, 1) >= '0' and substr(v_version_name, a_end, 1) <= '9' loop
            a_end := a_end + 1;
        end loop;
        if a_end = a_start then
            raise_application_error(-20000, 'Expected number at position ' || a_start);
        end if;
        if a_end - a_start > 4 then
            raise_application_error(-20000, 'Numbers within versions can only be up to 4 digits long');
        end if;

        -- zero-pad and append the number
        a_order := a_order || substr('0000', 1, 4 - (a_end - a_start)) ||
            substr(v_version_name, a_start, a_end - a_start) || '.';
        if a_end > length(v_version_name) then
            -- end of string - we're outta here
            if a_seen_letter = 'f' then
                -- append the "final" suffix if there haven't been any letters
                -- so far (i.e., not development/alpha/beta)
                a_order := a_order || '  3F.';
            end if;
            return a_order;
        end if;

        -- what's the next character? if a period, just skip it
        a_char := substr(v_version_name, a_end, 1);
        if a_char = '.' then
            null;
        else
            -- if the next character was a letter, append the appropriate characters
            if a_char = 'd' then
                a_order := a_order || '  0D.';
            elsif a_char = 'a' then
                a_order := a_order || '  1A.';
            elsif a_char = 'b' then
                a_order := a_order || '  2B.';
            else
                -- uhoh... some wacky character. bomb
                raise_application_error(-20000, 'Illegal character ''' || a_char ||
                    ' in version name ' || v_version_name || '''');
            end if;

            -- can't have something like 3.3a1b2 - just one letter allowed!
            if a_seen_letter = 't' then
                raise_application_error(-20000, 'Not allowed to have two letters in version name '''
                    || v_version_name || '''');
            end if;
            a_seen_letter := 't';

            -- end of string - we're done!
            if a_end = length(v_version_name) then
                return a_order;
            end if;
        end if;
        a_start := a_end + 1;
    end loop;
end;
/
show errors

-- Compare two versions (apply apm_version_order, comparing the results
-- lexicographically).
create or replace function apm_version_compare(v_version_name_a in varchar, v_version_name_b in varchar) return integer is
    a_order_a varchar(1000);
    a_order_b varchar(1000);
begin
    a_order_a := apm_version_order(v_version_name_a);
    a_order_b := apm_version_order(v_version_name_b);
    if a_order_a < a_order_b then
        return -1;
    elsif a_order_a > a_order_b then
        return 1;
    end if;
    return 0;
end;
/
show errors

-- Mark the latest version of a particular package as enabled - useful
-- for stuff like the core which we know *has* to be installed and
-- enabled.
create or replace procedure apm_insure_package_enabled(v_package_key in varchar) is
    cursor cur is
        select v.rowid
        from   apm_package_versions v, apm_packages p
        where  v.package_id = p.package_id
        and    p.package_key = v_package_key
        order by apm_version_order(version_name) desc
        for update of enabled_p;
    a_rowid rowid;
    a_count integer;
begin
    select count(*) into a_count
    from   apm_enabled_package_versions
    where  package_key = v_package_key;

    if a_count = 0 then
        open cur;
        fetch cur into a_rowid;
        if not cur%notfound then
            update apm_package_versions set enabled_p = 't' where current of cur;
            return;
        end if;
    end if;
end;
/
show errors

-- Should a data model upgrade script named v_path be executed when
-- upgrading from a version named a_initial_version_name to one named
-- v_final_version_name?
create or replace function apm_upgrade_for_version_p(
    v_path in varchar,
    v_initial_version_name in varchar,
    v_final_version_name in varchar
)
return char
is
    a_pos1 integer;
    a_pos2 integer;
    a_path varchar(4000);
    a_version_from varchar(4000);
    a_version_to varchar(4000);
begin
    -- Set a_path to the tail of the path (the file name).
    a_path := substr(v_path, instr(v_path, '/', -1) + 1);

    -- Remove the extension, if it's .sql.
    a_pos1 := instr(a_path, '.', -1);
    if a_pos1 > 0 and substr(a_path, a_pos1) = '.sql' then
        a_path := substr(a_path, 1, a_pos1 - 1);
    end if;

    -- Figure out the from/to version numbers for the individual file.
    a_pos1 := instr(a_path, '-', -1, 2);
    a_pos2 := instr(a_path, '-', -1);
    if a_pos1 = 0 or a_pos2 = 0 then
        -- There aren't two hyphens in the file name. Bail.
        return 'f';
    end if;

    a_version_from := substr(a_path, a_pos1 + 1, a_pos2 - a_pos1 - 1);
    a_version_to := substr(a_path, a_pos2 + 1);

    if apm_version_order(v_initial_version_name) <= apm_version_order(a_version_from) and
        apm_version_order(v_final_version_name) >= apm_version_order(a_version_to) then
        return 't';
    end if;
    
    return 'f';
exception when others then
    -- Invalid version number.
    return 'f';
end;
/
show errors

-- Given a path to a data-model upgrade file, returns a string which can be
-- used to place the file in order amongst other data-model upgrade files
-- (see version-install.tcl for an example).
create or replace function apm_upgrade_order(
    v_path in varchar
)
return char
is
    a_pos1 integer;
    a_pos2 integer;
    a_path varchar(4000);
begin
    -- Set a_path to the tail of the path (the file name).
    a_path := substr(v_path, instr(v_path, '/', -1) + 1);

    -- Figure out the from/to version numbers for the individual file.
    a_pos1 := instr(a_path, '-', -1, 2);
    a_pos2 := instr(a_path, '-', -1);
    if a_pos1 = 0 or a_pos2 = 0 then
        -- There aren't two hyphens in the file name. Just return the path.
        return a_path;
    end if;

    -- Return the root path, plus two dashes, plus the version order string for the
    -- from version of the upgrade script.
    return substr(a_path, 1, a_pos1 - 1) || '--' ||
        apm_version_order(substr(a_path, a_pos1 + 1, a_pos2 - a_pos1 - 1));
end;
/
show errors

-- Copy *all* the information about a version of a package to a new version.
-- Just a bunch of INSERT INTO ... SELECTs, mostly.
create or replace function apm_upgrade_version(
    v_version_id in integer,
    v_new_version_name in varchar,
    v_new_version_url in varchar
)
return integer
is
    a_version_id integer;
begin
    select apm_package_version_id_seq.nextval into a_version_id from dual;

    insert into apm_package_versions(version_id, package_id, package_name, version_name,
                                    version_url, summary, description_format, description,
                                    distribution, release_date, vendor, vendor_url, package_group)
        select a_version_id, package_id, package_name, v_new_version_name,
               v_new_version_url, summary, description_format, description, distribution,
               release_date, vendor, vendor_url, package_group
        from apm_package_versions
        where version_id = v_version_id;

    insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_url, service_version)
        select apm_package_dependency_id_seq.nextval, a_version_id, dependency_type, service_url, service_version
        from apm_package_dependencies
        where version_id = v_version_id;

    insert into apm_package_files(file_id, version_id, path, file_type)
        select apm_package_file_id_seq.nextval, a_version_id, path, file_type
        from apm_package_files
        where version_id = v_version_id;

    insert into apm_package_owners(version_id, owner_url, owner_name, sort_key)
        select a_version_id, owner_url, owner_name, sort_key
        from apm_package_owners
        where version_id = v_version_id;

    return a_version_id;
end;
/
show errors

--
-- PARAMETER STUFF (kevin@theory.caltech.edu)
--

create table ad_parameter_elements (
    element_id          integer
                        constraint ad_param_elts_id_pk primary key,
    version_id          constraint ad_param_elts_version_id_fk references apm_package_versions on delete cascade
                        constraint ad_param_elts_version_id_nn not null,
    element_name        varchar(100)
                        constraint ad_param_elts_name_nn not null,
    element_type        varchar(50)
                        constraint ad_param_elts_type_nn not null
                        constraint ad_param_elts_type_ck check(element_type in ('text','integer','boolean')),
    description         varchar(4000),
    default_value       varchar(4000),
    -- module_key and parameter_key are the two arguments to ad_parameter
    module_key          varchar(100),
    parameter_key       varchar(100)
                        constraint ad_param_elts_parameter_key_nn not null,
    change_on_restart_p char(1) default 'f'
                        constraint ad_param_elts_restart_nn not null
                        constraint ad_param_elts_restart_ck check(change_on_restart_p in ('t','f')),
    multiple_values_p   char(1) default 'f'
                        constraint ad_param_elts_mult_nn not null
                        constraint ad_param_elts_mult_ck check(multiple_values_p in ('t','f')),
    mandatory_p         char(1) default 'f'
                        constraint ad_param_elts_mandatory_nn not null
                        constraint ad_param_elts_mandatory_ck check(mandatory_p in ('t','f')),
    constraint ad_param_elts_un unique(version_id, module_key, parameter_key)
);
create sequence ad_param_element_id_sequence;

create table ad_parameter_values (
	value_id	integer
			constraint ad_param_vals_val_id_pk primary key,
	element_id	constraint ad_param_vals_elts_id_fk references ad_parameter_elements on delete cascade
			constraint ad_param_vals_elts_id_nn not null,
	value		varchar(4000)
			constraint ad_param_vals_val_nn not null
	-- lack of multi-table constraints means we have to do
	-- all the rest of the integrity checking in the TCL scripts.
	-- In particular, there are no unique constraints because of
	-- the possibility of multiple values.
);
create sequence ad_param_value_id_sequence;

create or replace procedure apm_insert_unique_param_val(
  p_element_id in integer, 
  p_value in varchar)
is
  exists_p integer;
begin
  select count(*) into exists_p
    from ad_parameter_values
    where element_id = p_element_id;

  if exists_p <> 0 then

    update ad_parameter_values
      set value = p_value
      where element_id = p_element_id;

  else

    insert into ad_parameter_values
      (value_id,element_id,value)
      values
      (ad_param_value_id_sequence.nextval,p_element_id,p_value);

  end if;

end;
/
show errors

create or replace trigger apm_unique_param_value_ck
before insert on ad_parameter_values for each row
declare
  multi_val_p char(1);
begin
  select multiple_values_p into multi_val_p
    from ad_parameter_elements
    where element_id = :new.element_id;

  if multi_val_p = 'f' then

    delete from ad_parameter_values where element_id = :new.element_id;

  end if;

end;
/
show errors
-- END APM

-- BEGIN IS-CHECKER

--
-- SELF MONITORING
--
create table is_global_state (
        last_system_reboot	date
);

create table is_test_state (
	test_type		varchar(12) primary key,
	last_starttime		date,
	last_stoptime		date,
	run_count		integer,
	enabled_p		char(1) default 't'
                                   check(enabled_p in ('t','f')),
	run_period_secs		integer
);

INSERT INTO is_global_state (last_system_reboot) VALUES (NULL);

INSERT INTO is_test_state ( test_type ) VALUES ('tcp');
INSERT INTO is_test_state ( test_type ) VALUES ('web');
INSERT INTO is_test_state ( test_type ) VALUES ('ping');
INSERT INTO is_test_state ( test_type ) VALUES ('mail');
-- 'notify' isn't really a test, but we want to track the
-- state of the notify schedule process...
INSERT INTO is_test_state ( test_type ) VALUES ('notify');

create sequence is_mail_run_number start with 1;

create sequence is_test_sequence start with 10000;

create table is_test_proc_log (
	test_id			integer not null primary key,
	test_type		not null references is_test_state,
	proc_id			integer,
	num_up                  integer,
	num_down                integer,
	test_starttime		date not NULL,
	test_stoptime		date
);

-- This table is to track emails that are sent out
create sequence is_sent_email_seq start with 10000;

create table is_sent_email_log (
	sent_email_id		integer not null primary key,
	sent_date		date not null,
	sent_to			varchar(30),
	subject			varchar(80),
	sent_cc			varchar(1000)
);
	


-- how are we going to use this machine
create sequence is_machine_use_id_seq start with 1;
create table is_machine_uses (
	machine_use_id	integer primary key,
	machine_use	varchar(100) not null unique,
	display_order	integer default 1
);

insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'Development', 1);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'Staging', 100);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'Production', 200);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, '6.916 - MIT', 300);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, '6.916 - Other', 400);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'Bootcamp', 500);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'R&D', 600);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'RocketStart - Solaris', 700);
insert into is_machine_uses (machine_use_id, machine_use, display_order)
values (is_machine_use_id_seq.nextval, 'RocketStart - Linux', 800);


-- =================================================================
-- add a new table is_machines
--
CREATE TABLE is_machines (
       machine_id           integer NOT NULL,
       machine_use_id    integer references is_machine_uses,
       hostname             varchar2(100) NULL,
       ip_address           varchar2(50) NULL,
       os_version           varchar2(50) NULL,
       description          varchar2(4000) NULL,
       model_and_serial     varchar2(4000) NULL,
       street_address       varchar2(4000) NULL,
       remote_console_instructions varchar2(4000) NULL,
       service_phone_number varchar2(100) NULL,
       service_contract     varchar2(4000) NULL,
       facility_phone       varchar2(100) NULL,
       facility_contact     varchar2(4000) NULL,
       backup_strategy      varchar2(4000) NULL,
       rdbms_backup_strategy varchar2(4000) NULL,
       further_docs_url     varchar2(200) NULL,
       PRIMARY KEY (machine_id)
);
comment on table is_machines is 'one row per machine, a machine has many IPs, ports and services';

create sequence is_machines_seq;


-- associate machines with a group
-- ie, an intranet group or projects

create table is_group_machine_map (
	group_id	integer not null references user_groups,
	machine_id	integer not null references is_machines,
	unique (group_id, machine_id)
);


--
-- SERVICES
-- Tables to record 'what' we are monitoring, with mostly one table per
-- 'test'. i.e. we will be testing vanilla TCP, email, web, and ping
-- (icmp) response.
--
create sequence is_services_seq start with 1000;

create table is_services (
	service_id		integer not null primary key,
	ip_or_hostname		varchar(60) not null,
	port			integer not null,
	protocol		varchar(20),
	name			varchar(100),
	tcp_response		varchar(50),
	first_monitored		date,
	timeout			integer default 20 not null,
	company			varchar(100),
	enabled_p		char(1) default 'f'
                                   check(enabled_p in ('t','f')),
        ping_enabled_p		char(1) default 'f'
                                   check(ping_enabled_p in ('t','f')),
        machine_id              integer null,
	unique (ip_or_hostname, port)
);

-- add a nullable foreign key from is_services to is_machines
--
ALTER TABLE IS_SERVICES
       ADD  ( FOREIGN KEY (machine_id)
                             REFERENCES is_machines ) ;
-- might as well index the foreign key
CREATE INDEX XIF24IS_SERVICES ON IS_SERVICES
(
       machine_id                  ASC
);


create or replace view is_services_active
as
select *
from is_services
where enabled_p = 't';


create sequence is_mail_services_seq start with 1000;

create table is_mail_services (
	mail_service_id		integer
        	constraint mail_service_id_pk primary key,
	service_id		integer 
		constraint service_id_null not null
		constraint service_id_is_service_ref references is_services,
	bouncer_email		varchar(100) default 'mmon_bouncer'
		constraint bouncer_email_null not null,
	   -- This is the special email address which should exist
	   -- on the monitored server.  Anything sent to that address
	   -- should return to sender.  It can be an address
	   -- without the '@hostname' part if the monitored server
	   -- will recognize it.
	last_unbounced_emailet_id	varchar(70),
	run_period		integer default 1
		constraint run_period_null not null,	
	   -- might not need run_period
	bounce_timeout_secs	integer default 60
		constraint bounce_timeout_secs_null not null,
	smtp_ok_p		char(1) default 't'
		constraint smtp_ok_boolean check(smtp_ok_p in ('t','f')),
	enabled_p		char(1) default 't'
		constraint enabled_boolean check(enabled_p in ('t','f'))
);

create or replace view is_mail_services_active
as
select 
     MAIL_SERVICE_ID,
     SERVICE_ID,
     BOUNCER_EMAIL,
     LAST_UNBOUNCED_EMAILET_ID,
     RUN_PERIOD,
     BOUNCE_TIMEOUT_SECS,
     SMTP_OK_P,
     ENABLED_P
from is_mail_services
where enabled_p = 't';

	
create sequence is_web_services_seq start with 1000;

create table is_web_services (
	web_service_id		integer not null primary key,
	service_id		integer not null references is_services,
	return_string		varchar(100) default 'success' not null,
	url			varchar(200) not null,
	query_string		varchar(200),
	enabled_p		char(1) default 't'
                                   check(enabled_p in ('t','f')),
	unique (service_id,url,return_string,query_string)
);

create or replace view is_web_services_active
as
select *
from is_web_services
where enabled_p = 't';


-- 
-- Logs and Alerts
--
create sequence is_event_log_sequence start with 1000;

create table is_event_log (
	event_id		integer not null primary key,
	service_id		references is_services,
        sub_service_id		integer,
	event_time		date,
	  -- discoverer is either a user_id for a test identification tag
	discoverer		varchar(30),
	event_description	varchar(40),
	test_type		not null references is_test_state,
	error_message		varchar(200),
	status_ok_p		char(1) default 't'
                                   check(status_ok_p in ('t','f')),
        remarks                 varchar2(1000)
);


-- this is a log for the MTA SMTP test
create table is_mail_log (
	event_id		references is_event_log,
	emailet_id		varchar(70)
);

create sequence is_alert_sequence start with 1000;

create table is_alerts (
	alert_id		integer not null primary key,
	service_id		references is_services not null,
        sub_service_id		integer,
	event_id		references is_event_log not null,
	test_type		not null references is_test_state,
	status_ok_p		char(1) default 't'
                                   check(status_ok_p in ('t','f')),
	notified_p		char(1) default 'f'
				   check(notified_p in ('t','f')),
	unique (service_id, sub_service_id, test_type)
);


--
-- NOTIFICATIONS
--
create sequence is_notification_rules_seq start with 1000;

-- The is_notification_rules table contains the rules and defaults
-- for the creation of a notice.  There is much duplication between
-- the is_notification_rules table and the is_notices table because
-- the 'rules' are 'new notices'.  After a notice is generate, it seems
-- better to allow the attributes of the notice to be changeable as
-- opposed to be controlled by a parent rule.  This way, someone can
-- change the 'notification_mode' of a rule for a service so that 
-- all future notices follow the new mode, but all existing notices
-- remain the same.

create table is_notification_rules (
	rule_id			integer not null primary key,
	service_id		integer not null references is_services,
	sub_service_id		integer,
	user_id			integer not null references users,
	group_id		integer references user_groups,
	test_type		not null references is_test_state,
	  -- does this notification require acknowledgement?
	acknowledge_p		char(1) default 'f'
                                   check(acknowledge_p in ('t','f')),
	  -- should use be informed of server bounces? (quick up/down)
	bounce_notify_p		char(1) default 'f' not null
                                   check(bounce_notify_p in ('t','f')),
	  -- should a trouble ticket be opened?
	open_ticket_p		char(1) default 'f'
                                   check(open_ticket_p in ('t','f')),
	mail_cc			varchar(1000),
  	  -- the following are for people who have beepers
	  -- and need a special tag or something in the subject
	custom_subject	varchar(80),
	custom_body	varchar(500),
	  -- we always send email when the server is down, we can
	  -- also send email when the server comes back up
	notification_mode	varchar(30), 	-- 'down_then_up', 'periodic'
	-- these two are only used when notification_mode is 'periodic'
	notification_interval_hours	number default 2,
	last_notification	date,
	unique (service_id, user_id, group_id, test_type)
);

create sequence is_notices_seq start with 1000;

-- A notice is a reaction to an event created as a result of a
-- notification rule.
create table is_notices (
	notice_id		integer not null primary key,
	rule_id			references is_notification_rules,
	service_id		not NULL references is_services,
        sub_service_id          integer,
	user_id			not NULL references users,
	group_id		references user_groups,
	event_id		references is_event_log,
	test_type		not null references is_test_state,
	note			varchar(500),
	acknowledged_p		char(1) default NULL
				   check(acknowledged_p in ('t','f',NULL)),
	  -- 'f' means it should be acknowledged, but isn't yet
	  -- NULL means it doesn't need acknowledgement
	bounce_notify_p		char(1) default 'f' not null
                                   check(bounce_notify_p in ('t','f')),
	ticket_id		integer,
	mail_cc			varchar(1000),
  	  -- the following are for people who have beepers
	  -- and need a special tag or something in the subject
	custom_subject	varchar(80),
	custom_body	varchar(500),
	acknowledged_id		references users(user_id),
	creation_time		date,
	acknowledged_time	date,
	notification_mode	varchar(30), 	-- 'down_then_up', 'periodic'
	notification_interval_hours	integer default 2,
	last_notification	date
);
	

create table is_users (
     user_id  integer not null,
     disable_is_mail_p char(1) default 'f' not null
                         check( disable_is_mail_p in ('t','f')),
     primary key (user_id)
);
comment on table is_users is 'users who want no IS mail are in here with f, users who want mail have t or are not in table';

alter table is_users add ( foreign key (user_id) references users);

-- we need to add a row to user_group_types
-- I add it in such a way that it will not give 
-- an erro if you do it twice
insert into  user_group_types 
    (GROUP_TYPE,
     PRETTY_NAME,
     PRETTY_PLURAL,
     APPROVAL_POLICY,
     DEFAULT_NEW_MEMBER_POLICY,
     GROUP_MODULE_ADMINISTRATION,
     HAS_VIRTUAL_DIRECTORY_P,
     GROUP_TYPE_PUBLIC_DIRECTORY,
     GROUP_TYPE_ADMIN_DIRECTORY,
     GROUP_PUBLIC_DIRECTORY,
     GROUP_ADMIN_DIRECTORY)
select
     'is_service',
     'IS Checker Service',
     'IS Checker Services',
     'open',
     'open',
     'none',
     'f',
     NULL,
     NULL,
     NULL,
     NULL
from dual
where not exists
    (select x.group_type
     from user_group_types x
     where x.group_type = 'is_service');


-- this function is needed to compare Intranet and IS Checker
-- hostnames since different conventions are used in these
-- two modules
create or replace function is_parse_hostname
       (
       	input_url in varchar2
       )
       	-- Dave Abercrombie, abe@arsdigita.com, 2000-04-07
       	--
       	-- Example:
       	--
       	-- Input                                Output
       	-- -------------------                  -----------
	-- http://arsdigita.com/index.tcl       arsdigita.com
        -- https://arsdigita.com/index.tcl      arsdigita.com
	-- nonsense_url                         nonsense_url
       	--
       	return varchar2
       	is parsed_hostname varchar2(4000);

begin -- need a nested block to get a declarations section
	declare

		len integer;  -- length of input URL (used for trunaction

		lpos integer; -- position from left as found by a instr search

		tpos integer; -- position from the left for truncating

	begin

		-- length of string is needed during truncation
		len := length(input_url);

		-- starting at the begining of input_url, look
		-- forwards for the first double slash
		lpos := instr(input_url, '//', 1, 1);

		-- if we did not find a double slash
		-- then lpos will be equal to 0

		-- we want to skip the // itself, so we add 2 to 
		-- the lpos to calculate the truncate position. 
		-- Also if did not find a // then we do not want to add 1
		if lpos=0
		then
			tpos := lpos;
		else
			tpos := lpos + 2 ;
		end if;

		-- truncate at the calculated position from the left
		-- starting at tpos and getting all remaining (need to add 1)
		parsed_hostname := substr(input_url,tpos,(len-tpos+1));

		-- now we need to trim off the end of the URL leaving
		-- just the hostname (and the port if present)

		-- starting at begining of input_url, look
		-- forwards for the first double slash
		lpos := instr(parsed_hostname, '/', 1, 1);

		-- if we did not find a slash
		-- then lpos will be equal to 0

		-- we want to skip the // itself, so we add 2 to 
		-- the lpos to calculate the truncate position. 
		-- Also if did not find a // then we do not want to do substr
		if lpos <> 0
		then
			tpos := lpos -1;
			parsed_hostname := substr(parsed_hostname,1,tpos);
		end if;

		-- if we end up with an empty string, then return input
		if length(parsed_hostname)=0
		then
			parsed_hostname := input_url;
		end if;

		-- return the parsed_hostname
		return(parsed_hostname);

	end; -- of nested block

end; -- of function

-- INSTR   http://oradoc.photo.net/ora81/DOC/server.815/a67779/function.htm#1025362
-- SUBSTR  http://oradoc.photo.net/ora81/DOC/server.815/a67779/function.htm#1025168

/ 
show errors

--  END IS-CHECKER



-- begin download

-- PL/SQL proc
-- returns 'authorized' if a user can view a file, 'not authorized' otherwise.
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_viewable_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_visibility download_rules.visibility%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select visibility into v_visibility
	from   download_rules
	where  version_id = v_version_id;
	
	if v_visibility = 'all' 
	then	
		return 'authorized';
	elsif v_visibility = 'group_members' then	

		select group_id into v_group_id
		from   downloads d, download_versions dv
		where  dv.version_id  = v_version_id
		and    dv.download_id = d.download_id;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from   user_group_map 
                where  user_id  = v_user_id 
		and    group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from   users 
  	        where  user_id = v_user_id;

		return v_return_value;
	end if; 

     END download_viewable_p;
/
show errors

-- PL/SQL proc
-- returns 'authorized' if a user can download, 'not authorized' if not 
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_authorized_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_availability download_rules.availability%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select availability into v_availability
	from   download_rules
	where  version_id = v_version_id;
	
	if v_availability = 'all' 
	then	
		return 'authorized';
	elsif v_availability = 'group_members' then	

		select group_id into v_group_id
		from   downloads d, download_versions dv
		where  dv.version_id  = v_version_id
		and    dv.download_id = d.download_id;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from   user_group_map 
		where  user_id  = v_user_id 
		and    group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from   users 
		where  user_id = v_user_id;
		
		return v_return_value;
	end if; 

     END download_authorized_p;
/
show errors
	
	
-- BEGIN SPAM --
alter table daily_spam_files add (	
	day_of_week		integer,
	day_of_month		integer,
	day_of_year		integer);
-- END SPAM --


-- BEGIN INTRANET --

-- Associate intranet user groups with a few modules
-- This doesn't do anything if the modules are already associated with each other
BEGIN
   user_group_type_module_add('intranet', 'news');
   user_group_type_module_add('intranet', 'address-book');
   user_group_type_module_add('intranet', 'download');
END;
/
show errors;



-- add customer status

-- What type of customers can we have
create sequence im_customer_types_seq start with 1;
create table im_customer_types (
	customer_type_id	integer primary key,
	customer_type		varchar(100) not null unique,
	display_order		integer default 1
);

alter table im_customers add ( customer_type_id	references im_customer_types);


alter table im_project_url_map add (
	machine_id 	references is_machines);

alter table im_employee_info add (termination_date          date);


-- Add the intranet user_group teams
BEGIN user_group_add ('intranet', 'Team', 'team', 'f'); END;
/
show errors;

alter table im_projects add requires_report_p       char(1) default('t')
		            constraint im_project_requires_report_p check (requires_report_p in ('t','f'));
-- update it to take us back to the original state
update im_projects set requires_report_p='f' where parent_id is not null;

create or replace function im_first_letter_default_to_a ( p_string IN varchar ) 
RETURN char
IS
   v_initial   char(1);
BEGIN

   v_initial := substr(upper(p_string),1,1);

   IF v_initial IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z') THEN
	RETURN v_initial;
   END IF;
  
   RETURN 'A';

END;
/
show errors;

-- generalize table names used in general comments
update general_comments set on_which_table = 'user_groups' where on_which_table in ('im_customers','im_partners','im_projects');


alter table im_employee_info add (
    	referred_by_recording_user  	integer references users,
	experience_id			integer references categories,
	source_id			integer references categories,		
	original_job_id			integer references categories,
	current_job_id			integer references categories,
	qualification_id		integer references categories,
	department_id			integer references categories,
	termination_reason		varchar(4000),
        recruiting_blurb clob,
        recruiting_blurb_html_p char(1) default 'f'
              constraint recruiting_blurb_html_p_con check (recruiting_blurb_html_p in ('t','f'))
);

create sequence im_employee_checkpoint_id_seq;

create table im_employee_checkpoints (
	checkpoint_id	integer primary key,
	stage		varchar(100) not null,
	checkpoint	varchar(500) not null
);

create table im_emp_checkpoint_checkoffs (
	checkpoint_id	integer references im_employee_checkpoints,
	checkee		integer not null references users,
	checker		integer not null references users,
	check_date	date,
	check_note	varchar(1000),
	primary key (checkee, checkpoint_id)
);

create sequence im_facilities_seq start with 1;

create table im_facilities (
        facility_id             integer primary key,
        facility_name           varchar(80) not null,
	phone                   varchar(50),
	fax                     varchar(50),
	address_line1           varchar(80),
	address_line2           varchar(80),
	address_city            varchar(80),
	address_state           varchar(80),
	address_postal_code     varchar(80),
	address_country_code    char(2) 
                                constraint if_address_country_code_fk references country_codes(iso),
	contact_person_id       integer references users,
	landlord                varchar(4000),
	-- who supplies the security service, the code for
	-- the door, etc.
	security                varchar(4000),
	note                    varchar(4000)
);



alter table im_offices add (
        facility_id 	integer
                    	constraint im_offices_facility_id references im_facilities
                    	constraint im_offices_facility_id_nn not null
);

-- migrate entries in im_offices to im_facilities
declare
 cursor c1 is 
  select * from im_offices;
 facilityid integer;
begin
 for rec in c1 loop
  select im_facilities_seq.nextval into facilityid from dual;
  insert into im_facilities (facility_id, facility_name, phone, fax, 
	address_line1, address_line2, address_city, address_state,
	address_postal_code, address_country_code, contact_person_id,
	landlord, security, note)
  values (facilityid, rec.address_line1, rec.phone, rec.fax, 
	rec.address_line1, rec.address_line2, rec.address_city, 
	rec.address_state, rec.address_postal_code, 
	rec.address_country_code, rec.contact_person_id, rec.landlord, 
	rec.security, rec.note);
  update im_offices set facility_id = facilityid
  where group_id = rec.group_id;
 end loop;
end;
/

alter table im_offices drop column address_city;
alter table im_offices drop column address_country_code;
alter table im_offices drop column address_line1;
alter table im_offices drop column address_line2;
alter table im_offices drop column address_postal_code;
alter table im_offices drop column address_state;
alter table im_offices drop column contact_person_id;
alter table im_offices drop column fax;
alter table im_offices drop column landlord;
alter table im_offices drop column note;
alter table im_offices drop column phone;
alter table im_offices drop column security;


-- returns a list of all the groups a user is in, separated by
-- commas
 
Create or replace function group_names_of_user (
	v_user_id IN Integer) Return varchar2 IS
	   counter integer;
	   return_string 	varchar(2000);
	CURSOR c_user_groups is
		select group_name
		from user_groups, user_group_map
		where user_groups.group_id = user_group_map.group_id
		and user_group_map.user_id = v_user_id;
BEGIN
	counter := 0;
	for v_group_data in c_user_groups LOOP
		counter := counter + 1;
		if counter = 1 then				
			return_string := v_group_data.group_name;
		else
			return_string := return_string || ', ' || v_group_data.group_name;
		end if;
	End Loop;
	Return return_string;
END;
/
show errors

-- returns a list of all the groups a user is in, separated by
-- commas 
create or replace function group_names_of_user_by_type ( p_user_id IN Integer, p_group_type IN varchar) 
Return varchar2 IS
	   v_counter integer;
	   v_return_string 	varchar(2000);
	CURSOR c_user_groups is
           select group_name
	     from user_groups, user_group_map
	    where user_groups.group_id = user_group_map.group_id
	      and user_groups.group_type = p_group_type
	      and user_group_map.user_id = p_user_id;
BEGIN
	v_counter := 0;
	for v_group_data in c_user_groups LOOP
		v_counter := v_counter + 1;
		if v_counter = 1 then				
			v_return_string := v_group_data.group_name;
		else
			v_return_string := v_return_string || ', ' || v_group_data.group_name;
		end if;
	End Loop;
	Return v_return_string;
END;
/
show errors


-- We need to keep track of in influx of employees.
-- For example, what employees have received offer letters?

create table im_employee_pipeline (
	user_id			integer primary key references users,
	state_id		integer not null references categories,
	office_id		integer references user_groups,
	team_id		 	integer references user_groups,
	prior_experience_id 	integer references categories,
	experience_id		integer references categories,
	source_id		integer references categories,		
	job_id			integer references categories,
	projected_start_date	date,
	-- the person at the company in charge of reeling them in.
	recruiter_user_id	integer references users,	
	referred_by		integer references users,
	note			varchar(4000),
	probability_to_start	integer
);

-- allows us to track allocation assignments that we don't expect to
-- take a lot of time

alter table im_allocations add (
	too_small_to_give_percentage_p   char(1) default 'f' check (too_small_to_give_percentage_p in ('t','f')));

alter table im_employee_info add (voluntary_termination_p		char(1) default 'f'
              constraint iei_voluntary_termination_p_ck check (voluntary_termination_p in ('t','f')));

-- we need to store answers to the question "how did you hear about us?"
alter table im_customers add (referral_source varchar(1000));
alter table im_partners  add (referral_source varchar(1000));

-- Switch im_partners contact_id to refer to address_book
alter table im_partners add temp_primary_contact_id references address_book;
update im_partners
   set temp_primary_contact_id = (select address_book_id 
				  from address_book
				  where (user_id=im_partners.primary_contact_id)
				   and (rownum = 1));
alter table im_partners drop column primary_contact_id;
alter table im_partners add primary_contact_id references address_book;
update im_partners set primary_contact_id = temp_primary_contact_id;
alter table im_partners drop column temp_primary_contact_id;


-- we need an easy way to get all information about
-- active employees
create or replace view im_employees_active as
select u.*, 
       info.JOB_TITLE,
       info.JOB_DESCRIPTION,
       info.TEAM_LEADER_P,
       info.PROJECT_LEAD_P,
       info.PERCENTAGE,
       info.SUPERVISOR_ID,
       info.GROUP_MANAGES,
       info.CURRENT_INFORMATION,
       info.LAST_MODIFIED,
       info.SS_NUMBER,
       info.SALARY,
       info.SALARY_PERIOD,
       info.DEPENDANT_P,
       info.ONLY_JOB_P,
       info.MARRIED_P,
       info.DEPENDANTS,
       info.HEAD_OF_HOUSEHOLD_P,
       info.BIRTHDATE,
       info.SKILLS,
       info.FIRST_EXPERIENCE,
       info.YEARS_EXPERIENCE,
       info.EDUCATIONAL_HISTORY,
       info.LAST_DEGREE_COMPLETED,
       info.RESUME,
       info.RESUME_HTML_P,
       info.START_DATE,
       info.RECEIVED_OFFER_LETTER_P,
       info.RETURNED_OFFER_LETTER_P,
       info.SIGNED_CONFIDENTIALITY_P,
       info.MOST_RECENT_REVIEW,
       info.MOST_RECENT_REVIEW_IN_FOLDER_P,
       info.FEATURED_EMPLOYEE_APPROVED_P,
       info.FEATURED_EMPLOYEE_BLURB_HTML_P,
       info.FEATURED_EMPLOYEE_BLURB,
       info.REFERRED_BY
from users_active u, 
     (select * 
        from im_employee_info info 
       where sysdate>info.start_date
         and sysdate > info.start_date
         and sysdate <= nvl(info.termination_date, sysdate)
         and ad_group_member_p(info.user_id, (select group_id from user_groups where short_name='employee')) = 't'
     ) info
where info.user_id=u.user_id;


-- need to quickly find percentage_time for a given start_block/user_id
create unique index im_employee_perc_time_idx on im_employee_percentage_time (start_block, user_id, percentage_time);


-- keep track of the last_modified on im_employee_info
create or replace trigger im_employee_info_last_modif_tr
before update on im_employee_info
for each row
DECLARE
BEGIN
     :new.last_modified := sysdate;
END;
/
show errors;


-- update im_start_blocks to flag start_of_larger_unit_p
alter table im_start_blocks add ( 
	-- We might want to tag a larger unit
	-- For example, if start_block is the first
	-- Sunday of a week, those tagged with
	-- start_of_larger_unit_p might tag
	-- the first Sunday of a month
	start_of_larger_unit_p	char(1) default 'f'  check (start_of_larger_unit_p in ('t','f'))
);

update im_start_blocks 
   set start_of_larger_unit_p='t' 
 where start_block in (select min(start_block) 
                         from im_start_blocks 
                        group by to_char(start_block,'YYYY-MM'))
   and start_of_larger_unit_p='f';

-- END INTRANET --

-- BEGIN INTRANET: use categories

-- we don't want these categories showing up in the user interests list
alter table categories modify enabled_p default 'f';

alter table im_customers add new_customer_status_id integer;
alter table im_customers add new_old_customer_status_id integer;
alter table im_customers add new_customer_type_id integer;
alter table im_partners add new_partner_status_id integer;
alter table im_partners add new_partner_type_id integer;
alter table im_projects add new_project_status_id integer;
alter table im_projects add new_project_type_id integer;

-- migrate entries in im_customer_status to categories

declare
 cursor c1 is 
  select * from im_customer_status;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.customer_status, 'Intranet Customer Status', 'f');

  update im_customers set new_customer_status_id = catid
  where customer_status_id = rec.customer_status_id;

  update im_customers set new_old_customer_status_id = catid
  where old_customer_status_id = rec.customer_status_id;
 end loop;
end;
/

-- migrate entries in im_customer_types to categories
declare
 cursor c1 is 
  select * from im_customer_types;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.customer_type, 'Intranet Customer Type', 'f');

  update im_customers set new_customer_type_id = catid
  where customer_type_id = rec.customer_type_id;
 end loop;
end;
/

-- migrate entries in im_partner_status to categories
declare
 cursor c1 is 
  select * from im_partner_status;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.partner_status, 'Intranet Partner Status', 'f');

  update im_partners set new_partner_status_id = catid
  where partner_status_id = rec.partner_status_id;
 end loop;
end;
/

-- migrate entries in im_partner_types to categories
declare
 cursor c1 is 
  select * from im_partner_types;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.partner_type, 'Intranet Partner Type', 'f');

  update im_partners set new_partner_type_id = catid
  where partner_type_id = rec.partner_type_id;
 end loop;
end;
/

-- migrate entries in im_project_status to categories
declare
 cursor c1 is 
  select * from im_project_status;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.project_status, 'Intranet Project Status', 'f');

  update im_projects set new_project_status_id = catid
  where project_status_id = rec.project_status_id;
 end loop;
end;
/

-- migrate entries in im_project_types to categories
declare
 cursor c1 is 
  select * from im_project_types;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.project_type, 'Intranet Project Type', 'f');

  update im_projects set new_project_type_id = catid
  where project_type_id = rec.project_type_id;
 end loop;
end;
/

-- drop the foreign-key constraints 
-- this ought to teach us to name our constraints!

declare
 cursor customer_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'IM_CUSTOMERS' and 
  column_name in ('CUSTOMER_TYPE_ID', 'CUSTOMER_STATUS_ID', 'OLD_CUSTOMER_STATUS_ID');
 v_sql_stmt varchar(400);
begin
 for cc in customer_constraints loop
  v_sql_stmt := 'alter table im_customers drop constraint ' || cc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

declare
 cursor partner_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'IM_PARTNERS' and 
  column_name in ('PARTNER_TYPE_ID', 'PARTNER_STATUS_ID');
 v_sql_stmt varchar(400);
begin
 for pc in partner_constraints loop
  v_sql_stmt := 'alter table im_partners drop constraint ' || pc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

-- these columns have check constraints (for not null) in addition to fk reference constraints
declare
 cursor project_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'IM_PROJECTS' and 
  column_name in ('PROJECT_TYPE_ID', 'PROJECT_STATUS_ID');
 v_sql_stmt varchar(400);
begin
 for pc in project_constraints loop
  v_sql_stmt := 'alter table im_projects drop constraint ' || pc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

update im_customers set customer_type_id = new_customer_type_id;
update im_customers set customer_status_id = new_customer_status_id;
update im_customers set old_customer_status_id = new_old_customer_status_id;
update im_partners set partner_type_id = new_partner_type_id;
update im_partners set partner_status_id = new_partner_status_id;
update im_projects set project_type_id = new_project_type_id;
update im_projects set project_status_id = new_project_status_id;

alter table im_customers drop column new_customer_status_id;
alter table im_customers drop column new_old_customer_status_id;
alter table im_customers drop column new_customer_type_id;
alter table im_partners drop column new_partner_status_id;
alter table im_partners drop column new_partner_type_id;
alter table im_projects drop column new_project_status_id;
alter table im_projects drop column new_project_type_id;

alter table im_customers add constraint customers_type_fk 
 foreign key (customer_type_id) references categories;

alter table im_customers add constraint customers_status_fk 
 foreign key (customer_status_id) references categories;

alter table im_customers add constraint customers_old_status_fk 
 foreign key (old_customer_status_id) references categories;

alter table im_partners add constraint partners_type_fk
 foreign key (partner_type_id) references categories;

alter table im_partners add constraint partners_status_fk
 foreign key (partner_status_id) references categories;

alter table im_projects add constraint projects_type_fk
 foreign key (project_type_id) references categories;

alter table im_projects add constraint projects_status_fk
 foreign key (project_status_id) references categories;

alter table im_projects add constraint projects_type_nnull 
 check(project_type_id is not null);

alter table im_projects add constraint projects_status_nnull 
 check(project_status_id is not null);

create or replace function im_category_from_id ( v_category_id IN integer )
return varchar
IS 
  v_category    categories.category%TYPE;
BEGIN
  select category into v_category from categories where category_id = v_category_id;
  return v_category;
END;
/
show errors;

drop table im_project_status;
drop table im_project_types;
drop table im_customer_status;
drop table im_customer_types;
drop table im_partner_status;
drop table im_partner_types;

-- views on intranet categories to make queries cleaner

create view im_project_status as 
select category_id as project_status_id, category as project_status
from categories 
where category_type = 'Intranet Project Status';

create view im_project_types as
select category_id as project_type_id, category as project_type
from categories
where category_type = 'Intranet Project Type';

create view im_customer_status as 
select category_id as customer_status_id, category as customer_status
from categories 
where category_type = 'Intranet Customer Status';

create view im_customer_types as
select category_id as customer_type_id, category as customer_type
from categories
where category_type = 'Intranet Customer Type';

create view im_partner_status as 
select category_id as partner_status_id, category as partner_status
from categories 
where category_type = 'Intranet Partner Status';

create view im_partner_types as
select category_id as partner_type_id, category as partner_type
from categories
where category_type = 'Intranet Partner Type';

create view im_prior_experiences as
select category_id as experience_id, category as experience
from categories
where category_type = 'Intranet Prior Experience';

create view im_hiring_sources as
select category_id as source_id, category as source
from categories
where category_type = 'Intranet Hiring Source';

create view im_job_titles as
select category_id as job_title_id, category as job_title
from categories
where category_type = 'Intranet Job Title';

create view im_departments as
select category_id as department_id, category as department
from categories
where category_type = 'Intranet Department';

create view im_qualification_processes as
select category_id as qualification_id, category as qualification
from categories
where category_type = 'Intranet Qualification Process';

create view im_annual_revenue as
select category_id as revenue_id, category as revenue
from categories
where category_type = 'Intranet Annual Revenue';

create view im_employee_pipeline_states as
select category_id as state_id, category as state
from categories
where category_type = 'Intranet Employee Pipeline State';


alter table im_customers add annual_revenue integer;
alter table im_customers add constraint cust_revenue_fk
  foreign key (annual_revenue) references categories;

alter table im_partners add annual_revenue integer;
alter table im_partners add constraint part_revenue_fk
  foreign key (annual_revenue) references categories;

-- END INTRANET: use categories


-- BEGIN EDUCATION --

-- fixes to triggers that did not quite work in the 
-- first release

drop table edu_role_change_state_info;
drop trigger edu_role_before_update_tr;

CREATE OR REPLACE TRIGGER edu_class_role_update_tr
AFTER UPDATE OF role ON user_group_roles
FOR EACH ROW
BEGIN
	-- we want to update the existing row
	update edu_role_pretty_role_map
        set role = :new.role
	where group_id = :new.group_id
        and role = :old.role;

END;
/
show errors



CREATE OR REPLACE TRIGGER edu_class_role_delete_tr
BEFORE DELETE ON user_group_roles
FOR EACH ROW
BEGIN
	delete from edu_role_pretty_role_map 
	where group_id = :old.group_id
        and role = :old.role;
END;
/
show errors


CREATE OR REPLACE TRIGGER edu_class_role_insert_tr
AFTER INSERT ON user_group_roles
FOR EACH ROW
DECLARE
	v_class_p	integer;
BEGIN
	select count(group_id) into v_class_p
	from user_groups
	where group_type = 'edu_class'
        and group_id = :new.group_id;

	IF v_class_p > 0 THEN

		insert into edu_role_pretty_role_map (
        	       group_id, 
	               role, 
        	       pretty_role,
                       pretty_role_plural, 
	               sort_key,
                       priority) 
        	    select
	               :new.group_id, 
  		       :new.role, 
		       :new.role, 
                       :new.role || 's',
    		       nvl(max(sort_key),0) + 1,
    		       nvl(max(priority),0) + 1
	             from edu_role_pretty_role_map
        	    where group_id = :new.group_id;
	END IF;
END;
/
show errors



-- update edu_subjects

alter table edu_student_answers add team_id references user_groups;

alter table edu_subjects add(description_html_p	char(1) default 'f' constraint edu_sub_desc_html_p_ck check(description_html_p in ('t','f')));

update edu_subjects set description_html_p = 'f';

alter table edu_subjects_audit add(description_html_p char(1));

insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
values
('edu_class', 'description_html_p', 'Description HTML?', 'boolean', 'char(1)', 'default ''f'' check(description_html_p in (''t'',''f''))', 17);


create or replace trigger edu_subjects_audit_trigger
before update or delete on edu_subjects
for each row
begin
   insert into edu_subjects_audit (
	subject_id,
	subject_name,
	description,
	description_html_p,
	credit_hours,
	prerequisites,
	professors_in_charge,
	last_modified,
        last_modifying_user,
        modified_ip_address)
   values (
	:old.subject_id,
	:old.subject_name,
	:old.description,
	:old.description_html_p,
	:old.credit_hours,
	:old.prerequisites,
	:old.professors_in_charge,
	:old.last_modified,
        :old.last_modifying_user,
        :old.modified_ip_address);
end;
/
show errors	




alter table edu_class_info add(description_html_p char(1) default 'f' constraint edu_class_desc_html_p_ck check(description_html_p in ('t','f')));

update edu_class_info set description_html_p = 'f';

alter table edu_class_info_audit add(description_html_p char(1));

create or replace view edu_current_classes
as
select
	user_groups.group_id as class_id,
	group_name as class_name,
	edu_class_info.term_id,
	subject_id,
	edu_class_info.start_date,
	edu_class_info.end_date,
	description,
	description_html_p,
	where_and_when,
	syllabus_id,
	lecture_notes_folder_id,
	handouts_folder_id,
	assignments_folder_id,
	projects_folder_id,
	exams_folder_id,
	public_p,
	grades_p,
	teams_p,
	exams_p,
	final_exam_p
from user_groups, edu_class_info
where user_groups.group_id = edu_class_info.group_id
and group_type = 'edu_class'
and active_p = 't'
and existence_public_p='t'
and approved_p = 't'
and sysdate<edu_class_info.end_date
and sysdate>=edu_class_info.start_date;

create or replace view edu_classes
as
select
	user_groups.group_id as class_id,
	group_name as class_name,
	edu_class_info.term_id,
	subject_id,
	edu_class_info.start_date,
	edu_class_info.end_date,
	description,
	description_html_p,
	where_and_when,
	syllabus_id,
	lecture_notes_folder_id,
	handouts_folder_id,
	assignments_folder_id,
	projects_folder_id,
	exams_folder_id,
	public_p,
	grades_p,
	teams_p,
	exams_p,
	final_exam_p
from user_groups, edu_class_info
where user_groups.group_id = edu_class_info.group_id
and group_type = 'edu_class'
and active_p = 't'
and existence_public_p='t'
and approved_p = 't';


create or replace trigger edu_class_info_audit_trigger
before update or delete on edu_class_info
for each row
begin
   insert into edu_class_info_audit (
	group_id,		
	term_id,			
	subject_id,		
	start_date,		
	end_date,		
	description, 		
	description_html_p, 		
	where_and_when,		
	syllabus_id,		
	assignments_folder_id,	
	projects_folder_id,	
	lecture_notes_folder_id, 
	handouts_folder_id,	
	exams_folder_id,		
	public_p,		
	grades_p,  		
	teams_p,			
	exams_p,                 
	final_exam_p,            
	last_modified,          	
        last_modifying_user,     
        modified_ip_address)
    values (
	:old.group_id,		
	:old.term_id,			
	:old.subject_id,		
	:old.start_date,		
	:old.end_date,		
	:old.description, 		
	:old.description_html_p, 		
	:old.where_and_when,		
	:old.syllabus_id,		
	:old.assignments_folder_id,	
	:old.projects_folder_id,	
	:old.lecture_notes_folder_id, 
	:old.handouts_folder_id,	
	:old.exams_folder_id,		
	:old.public_p,		
	:old.grades_p,  		
	:old.teams_p,			
	:old.exams_p,                 
	:old.final_exam_p,            
	:old.last_modified,          	
        :old.last_modifying_user,     
        :old.modified_ip_address);
end;
/
show errors


alter table edu_class_info modify (
	subject_id integer constraint edu_class_info_subject_nn not null,
	term_id integer constraint edu_class_info_term_id_nn not null
);


create or replace view edu_terms_current
as
select
  term_id,
  term_name,
  start_date,
  end_date
from edu_terms 
where start_date < sysdate
  and end_date > sysdate;



create table edu_task_instances  (
	task_instance_id 	integer not null primary key,
	task_instance_name	varchar(200),
	task_instance_url	varchar(500),
	-- which task is this an instance of?
	task_id		integer not null references edu_student_tasks,
	description		varchar(4000),
	approved_p		char(1) default 'f' check(approved_p in ('t','f')),
        approved_date           date,
        approving_user          references users(user_id),
	-- we want to be able to generate a consistent user interface so
	-- we record the type of task.
	-- (aileen 4/00) renamed this from task_type because task_type is
	-- a reserved column name in edu_student_tasks  
	team_or_user 		varchar(10) default 'team' check(team_or_user in ('user','team')),
	min_body_count		integer,
	max_body_count		integer,
	-- we want to be able to "delete" task instances so we have active_p
	active_p		char(1) default 't' check(active_p in ('t','f'))
);


-- we want to be able to assign students and teams to tasks
-- we use an index instead of a multi-column primary key because
-- team_id and student_id an both be null

create table edu_task_user_map (
	task_instance_id	integer not null references edu_task_instances,
	team_id			integer references user_groups,
	student_id		integer references users,
	constraint edu_task_user_map_check check ((team_id is null and student_id is not null) or (team_id is not null and student_id is null))
);


-- END EDUCATION ---




-- ------------------------------------------------
-- - START EVENTS ---
alter table event_info add(contact_user_id integer references users);

insert into user_group_type_fields 
(group_type, column_name, pretty_name, column_type, 
column_actual_type, sort_key)
values
('event', 'contact_user_id', 'Event Contact Person', 'integer', 'integer', 1);

-- create default contact users for each existing event
create or replace procedure event_contact_create
IS
	i_group_count		integer;

	cursor c1 is
	select event_id, group_id, creator_id
	from events_events;
BEGIN
	FOR e in c1 LOOP
	    -- check if this group_id already has a user
	    select count(group_id) into i_group_count
	    from event_info
	    where group_id = e.group_id;

	    IF i_group_count = 0 THEN
	       -- insert if there isn't a row for this group
	       INSERT into event_info
	       (group_id, contact_user_id)
	       VALUES
	       (e.group_id, e.creator_id);
	    ELSE
	       --update if there is a row
	       UPDATE event_info
	       set contact_user_id = e.creator_id
	       where group_id = e.group_id
	       ;
	    END IF;
	END LOOP;
END event_contact_create;
/
show errors;

execute event_contact_create();

drop procedure event_contact_create;

-- edit events_activities to support default contact person
alter table events_activities add(default_contact_user_id integer references users);

-- activities are owned by groups
alter table events_activities drop column user_id;

-- add more info the the venues data model
alter table events_venues add(fax_number varchar(30));
alter table events_venues add(phone_number varchar(30));
alter table events_venues add(email varchar(100));

-- change the administration url for events to /events/admin/
update administration_info set url = '/events/admin/' where url =
'/admin/events/';


-- change max_people in events_venues to be an integer
create table tmp_events_venues (
       venue_id		 integer,
       max_people	 number
);

insert into tmp_events_venues (venue_id, max_people)
select venue_id, max_people from events_venues where max_people is not null;

alter table events_venues drop column max_people;
alter table events_venues add(max_people integer);

create or replace procedure event_venues_num_to_int
IS
	cursor c1 is
	select venue_id as venue_id, 
	round(max_people) as max_people
	from tmp_events_venues;
BEGIN
	FOR e in c1 LOOP
	    update events_venues set max_people = e.max_people
	    where venue_id = e.venue_id;
	END LOOP;
END event_venues_num_to_int;
/
show errors;

execute event_venues_num_to_int();
drop procedure event_venues_num_to_int;
drop table tmp_events_venues;


-- change max_people in events_events to be an integer
create table tmp_events_events (
       event_id		 integer,
       max_people	 number
);

insert into tmp_events_events (event_id, max_people)
select event_id, max_people from events_events where max_people is not null;

alter table events_events drop column max_people;
alter table events_events add(max_people integer);

create or replace procedure event_events_num_to_int
IS
	cursor c1 is
	select event_id as event_id, 
	round(max_people) as max_people
	from tmp_events_events;
BEGIN
	FOR e in c1 LOOP
	    update events_events set max_people = e.max_people
	    where event_id = e.event_id;
	END LOOP;
END event_events_num_to_int;
/
show errors;

execute event_events_num_to_int();
drop procedure event_events_num_to_int;
drop table tmp_events_events;

-- normalize event organizers and their roles
create table tmp_events_organizers_map (
       event_id		      integer not null references events_events,  
       user_id		      integer not null references users,
       role		      varchar(200) default 'organizer' not null,
       responsibilities	      clob
);
insert into tmp_events_organizers_map (event_id, user_id, role,
responsibilities)
select event_id, user_id, role, responsibilities from events_organizers_map;

drop table events_organizers_map;

-- create default organizer roles for an activity
create sequence events_activity_org_roles_seq start with 1;
create table events_activity_org_roles (
       role_id			integer 
				constraint evnt_act_org_roles_role_id_pk 
				primary key ,
       activity_id		integer 
				constraint evnt_act_role_activity_id_fk 
				references events_activities
				constraint evnt_act_role_activity_id_nn
				not null,  
       role			varchar(200) 
				constraint evnt_act_org_roles_role_nn
				not null,
       responsibilities		clob,
       -- is this a role that we want event registrants to see?
       public_role_p		char(1) default 'f' 
				constraint evnt_act_role_public_role_p
				check (public_role_p in ('t', 'f'))
);

-- create actual organizer roles for each event
create sequence events_event_org_roles_seq start with 1;
create table events_event_organizer_roles (
       role_id			integer 
				constraint evnt_ev_org_roles_role_id_pk 
				primary key,
       event_id			integer 
				constraint evnt_ev_org_roles_event_id_fk 
				references events_events
				constraint evnt_ev_org_roles_event_id_nn
				not null,  
       role			varchar(200) 
				constraint evnt_ev_org_roles_role_nn
				not null,
       responsibilities		clob,
       -- is this a role that we want event registrants to see?
       public_role_p		char(1) default 'f' 
				constraint evnt_ev_roles_public_role_p
				check (public_role_p in ('t', 'f'))
);

create table events_organizers_map (
       user_id			   constraint evnt_org_map_user_id_nn
				   not null
				   constraint evnt_org_map_user_id_fk
				   references users,
       role_id			   integer 
				   constraint evnt_org_map_role_id_nn
				   not null 
				   constraint evnt_org_map_role_id_fk
				   references events_event_organizer_roles,
       constraint events_org_map_pk primary key (user_id, role_id)
);

-- create a view to see event organizer roles and the people in those roles
create or replace view events_organizers 
as
select eor.*, eom.user_id
from events_event_organizer_roles eor, events_organizers_map eom
where eor.role_id=eom.role_id(+);

create or replace procedure event_copy_organizers
IS
	i_role_id	integer;
	i_group_id	integer;
	cursor c1 is
	select event_id, user_id, role, responsibilities
	from tmp_events_organizers_map;
BEGIN
	FOR e in c1 LOOP
	    select events_event_org_roles_seq.nextval into i_role_id from dual;

	    -- create the appropriate role
	    insert into events_event_organizer_roles
	    (role_id, event_id, role, responsibilities)
	    values
	    (i_role_id, e.event_id, e.role, e.responsibilities);

	    -- assign the user his role
	    insert into events_organizers_map
	    (user_id, role_id)
	    values
	    (e.user_id, i_role_id);

	    -- add this user and his role into the event's user group
	    select group_id into i_group_id 
	    from events_events 
	    where event_id = e.event_id;

	    insert into user_group_map
	    (group_id, user_id, role, registration_date,
	    mapping_user, mapping_ip_address)
	    values
	    (i_group_id, e.user_id, e.role, sysdate, 1, 
	    'EVENTS 3.2->3.3 UPGRADE SCRIPT');
	END LOOP;
END event_copy_organizers;
/
show errors;


execute event_copy_organizers;
drop procedure event_copy_organizers;
drop table tmp_events_organizers_map;

-- - END EVENTS ---
-- ------------------------------------------------

-- - BEGIN MONITORING ---
-- where top's output looks like this (from dev0103-001:/usr/local/bin/top): 

-- load averages:  0.21,  0.18,  0.23                   21:52:56
-- 322 processes: 316 sleeping, 3 zombie, 1 stopped, 2 on cpu
-- CPU states:  3.7% idle,  9.2% user,  7.1% kernel, 80.0% iowait,  0.0% swap
-- Memory: 1152M real, 17M free, 593M swap in use, 1432M swap free
--
--   PID USERNAME THR PRI NICE  SIZE   RES STATE   TIME    CPU COMMAND
-- 17312 oracle     1  33    0  222M  189M sleep  17:54  0.95% oracle
--  9834 root       1  33    0 2136K 1528K sleep   0:00  0.43% sshd1


create sequence ad_monitoring_top_top_id start with 1;
create table ad_monitoring_top (
	top_id			integer
				constraint ad_monitoring_top_top_id primary key,
        timestamp               date default sysdate,
	-- denormalization: an indexable column for fast time comparisons.
	timehour		number(2),
	-- the three load averages taken from uptime/top
        load_avg_1              number,
        load_avg_5              number,
        load_avg_15             number,
	-- basic stats on current memory usage
        memory_real             number,
        memory_free             number,
        memory_swap_free        number,
        memory_swap_in_use      number,
	-- basic stats on the number of running procedures
	procs_total		integer,
	procs_sleeping		integer,
	procs_zombie		integer,
	procs_stopped		integer,
	procs_on_cpu		integer,
	-- basic stats on cpu usage
	cpu_idle		number,
	cpu_user		number,
	cpu_kernel		number,
	cpu_iowait		number,
	cpu_swap		number
);


-- this table stores information about each of the top 10 or so
-- processes running. Every time we take a snapshot, we record
-- this basic information to help track down stray or greedy 
-- processes
create sequence ad_monitoring_top_proc_proc_id start with 1;
create table ad_monitoring_top_proc (
    proc_id   		integer 
			constraint ad_mntr_top_proc_proc_id primary key,
    top_id       	integer not null 
			constraint ad_mntr_top_proc_top_id references ad_monitoring_top,
    pid         	integer not null,      -- the process id  
    username    	varchar(10) not null,  -- user running this command
    threads             integer,   -- the # of threads this proc is running
    priority            integer,  
    nice                integer,   -- the value of nice for this process
    proc_size           varchar(10),
    resident_memory     varchar(10),
    state               varchar(10),
    cpu_total_time      varchar(10),   -- total cpu time used to date
    cpu_pct             varchar(10),   -- percentage of cpu currently used
    -- the command this process is running
    command     	varchar(30) not null 
);
 
-- - END MONITORING ---


-- - BEGIN BBOARD ---

--
-- bboard_icons contains all icons available to the unified bboard
-- module.
--
CREATE TABLE bboard_icons (
       icon_id			integer NOT NULL PRIMARY KEY,
       -- A short name for the icon (the system will pick a
       -- non-descriptive name if the user doesn't
       icon_name                varchar(25),
       -- Actual filename of the icon.  The path name is in IconDir
       -- under the bboard/unified key in the
       -- parameters/<servername>.ini file 
       icon_file		varchar(250),
       -- The width (in pixels) that the icon will be scaled to
       icon_width		integer,
       -- The height (in pixels) that the icon will be scaled to
       icon_height		integer
);

-- add an explicit not null constraint on bboard(one_line)
update bboard set one_line = 'BBoard Posting - ' || posting_time where one_line is null;
alter table bboard modify one_line constraint bboard_one_line_nn not null;

-- Default forums, color, and icon_id for the web service
ALTER TABLE bboard_topics add (
       -- default_topic_p is 't' if the web service admin wants that
       -- topic to be a default bboard forum for users
       default_topic_p            varchar(1) default 't' check (default_topic_p in ('t','f')),
       -- the default color set by the web service admin for
       -- displaying topic summary lines for a forum 
       -- in #XXXXXX format (Hexadecimal)
       color			  varchar(7),
       -- the default icon set by the web service admin for displaying
       -- topic summary lines for the forum 
       icon_id			  integer REFERENCES bboard_icons
);

create sequence icon_id_seq;

--
-- Map users to their customizable unified set of Forums they want to
-- participate in
--
CREATE TABLE bboard_unified (
       user_id		 	 integer NOT NULL REFERENCES users,
       topic_id			 integer NOT NULL REFERENCES bboard_topics,
       -- default_topic_p is 't' if the user wants that topic to be in
       -- his/her unified bboard view
       default_topic_p           varchar(1) DEFAULT 't' CHECK (default_topic_p IN ('t','f')),
       -- the color used to display topic summary lines for the forum,
       -- in #XXXXXX format (Hexadecimal)
       color			 varchar(7),
       -- the icon used in displaying topic summary lines for the forum
       icon_id			 integer REFERENCES bboard_icons
);


-- - END BBOARD ---

-- - BEGIN SURVSIMP

alter table survsimp_surveys add (
	-- limit to one response per user
	single_response_p	char(1) default 'f' check(single_response_p in ('t','f')),
	single_editable_p	char(1) default 't' check(single_editable_p in ('t','f'))
);

-- Sometimes you release a survey, and then later decide that 
-- you only want to include one response per user. The following
-- view includes only the latest response from all users
create or replace view survsimp_responses_unique as 
select r1.* from survsimp_responses r1
where r1.response_id=(select max(r2.response_id) 
                        from survsimp_responses r2
                       where r1.survey_id=r2.survey_id
                         and r1.user_id=r2.user_id);


-- - Add ability to handle blob responses, mostly borrowed from general-comments

alter table survsimp_question_responses add (
	attachment_answer	blob,
	-- file name including extension but not path
	attachment_file_name	varchar(500),
	attachment_file_type	varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	attachment_file_extension varchar(50) 	-- e.g., "jpg"
);


-- We create a view that selects out only the last response from each
-- user to give us at most 1 response from all users.
create or replace view survsimp_question_responses_un as 
select qr.* 
  from survsimp_question_responses qr, survsimp_responses_unique r
 where qr.response_id=r.response_id;


--Yuk, alter the constraint on presentation_type
declare
 cursor presentation_type_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'SURVSIMP_QUESTIONS' and 
  column_name in ('PRESENTATION_TYPE');
 v_sql_stmt varchar(400);
begin
 for pc in presentation_type_constraints loop
  v_sql_stmt := 'alter table survsimp_questions drop constraint ' || pc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

alter table survsimp_questions add constraint survsimp_questions_pres_type
    check(presentation_type in ('textbox','textarea','select','radio', 'checkbox', 'date'));

-- - END Survey-simple.sql

-- - BEGIN GENERAL COMMENTS ---
update table_acs_properties set table_name='news_items' where table_name='news';
update table_acs_properties set user_url_stub='/news/item.tcl?news_item_id=' where table_name='news_items';
update table_acs_properties set admin_url_stub='/news/admin/item.tcl?news_item_id=' where table_name='news_items';
commit;
-- - END GENERAL COMMENTS ---


-- - BEGIN TICKET ---
update table_acs_properties set user_url_stub='/ticket/issue-view.tcl?msg_id=' where table_name='ticket_issues';
update table_acs_properties set admin_url_stub='/ticket/issue-new.tcl?msg_id=' where table_name='ticket_issues';
update table_acs_properties set user_url_stub='/ticket/issue-view.tcl?msg_id=' where table_name='ticket_issues_i';
update table_acs_properties set admin_url_stub='/ticket/issue-new.tcl?msg_id=' where table_name='ticket_issues_i';
commit;
-- - END TICKET ---


-- - BEGIN USER GROUPS ---

-- remove the constraint on group_spam_history.send_to

declare
 v_constraint_name      varchar(50);
 v_sql_stmt 		varchar(400);
begin

  v_constraint_name := null;

  BEGIN 
    select constraint_name into v_constraint_name
      from user_cons_columns
     where table_name = 'GROUP_SPAM_HISTORY'
       and column_name = 'SEND_TO';
    exception when others then null;
  END;

  IF v_constraint_name is not null THEN 
    v_sql_stmt := 'alter table group_spam_history drop constraint ' || v_constraint_name;
    execute immediate v_sql_stmt;
  END IF;

end;
/
show errors;

-- - END USER GROUPS ---

-- --  change in group_spam_history to support multi-role spamming

create table group_spam_history_temp (
	spam_id			integer primary key,
	group_id		references user_groups not null,
	sender_id		references users(user_id) not null,
	sender_ip_address	varchar(50) not null,
	from_address		varchar(100),
	subject			varchar(200),
 	body			clob,
	send_to			varchar (50) default 'members',
	creation_date		date not null,
	-- approved_p matters only for spam policy='wait'
	-- approved_p = 't' indicates administrator approved the mail 
	-- approved_p = 'f' indicates administrator disapproved the mail, so it won't be listed for approval again
	-- approved_p = null indicates the mail is not approved/disapproved by the administrator yet 
	approved_p		char(1) default null check (approved_p is null or approved_p in ('t','f')),
	send_date		date,
	-- this holds the number of intended recipients
	n_receivers_intended	integer default 0,
	-- we'll increment this after every successful email
	n_receivers_actual	integer default 0
);


insert into group_spam_history_temp
	(spam_id,group_id,sender_id,sender_ip_address,from_address, 
	 subject,body,send_to,creation_date,approved_p,send_date,
	 n_receivers_intended,n_receivers_actual)
select   spam_id,group_id,sender_id,sender_ip_address,from_address, 
         subject,body, send_to,creation_date,approved_p,send_date,
         n_receivers_intended,n_receivers_actual
from group_spam_history;

commit;

drop table group_spam_history;
alter table group_spam_history_temp rename to group_spam_history;

-- --- end change in group_spam_history -------

-- BEGIN CRM --

alter table crm_states add (
	initial_state_p char(1) default 'f' check (initial_state_p in ('t', 'f'))
);

-- END CRM --

create table ad_db_log_messages (
	severity	varchar(7) not null check (severity in 
			 ('notice', 'warning', 'error', 'fatal',
			  'bug', 'debug')),
	message		varchar(4000) not null,
	creation_date	date default sysdate not null
);

create or replace procedure ad_db_log (
 v_severity in ad_db_log_messages.severity%TYPE,
 v_message in ad_db_log_messages.message%TYPE
)
as
pragma autonomous_transaction;
begin
 insert into ad_db_log_messages(severity, message)
 values(v_severity, v_message);

 commit;
end ad_db_log;
/
show errors

create table contest_votes (
	user_id		integer not null 
			constraint contest_votes_user_id_fk references users,
	entry_date	date,
	domain_id	integer 
			constraint contest_votes_domain_id_fk references contest_domains,
	entry_id	integer,
	ipaddress	varchar(100),
	integer_vote	integer,
	comments	varchar(4000),
	constraint cv_entry_user_domain_pk primary key (entry_id, user_id, domain_id)
);



create sequence wap_user_agent_id_sequence start with 1;

create table wap_user_agents (
	user_agent_id		integer
				  constraint wap_user_agent_id_pk primary key
				  constraint wap_user_agent_id_nn not null,
	name			varchar(200)
				  constraint wap_user_agent_name_nn not null,
	creation_comment        varchar(4000),
	creation_date		date default sysdate,
	creation_user		constraint wap_user_agt_create_user_fk
				  references users,
        -- NULL implies it is active.
	deletion_date		date,
	deletion_user		constraint wap_user_agt_delete_user_fk
				  references users
);

-- A bunch of user-agent data

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'ALAV UP/4.0.7',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Alcatel-BE3/1.0 UP/4.0.6c',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'AUR PALM WAPPER',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Device V1.12',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'EricssonR320/R1A',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'fetchpage.cgi/0.53',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Java1.1.8',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Java1.2.2',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'm-crawler/1.0 WAP',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Materna-WAPPreview/1.1.3',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'MC218 2.0 WAP1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Mitsu/1.1.A',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'MOT-CB/0.0.19 UP/4.0.5j',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'MOT-CB/0.0.21 UP/4.0.5m',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia-WAP-Toolkit/1.2',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia-WAP-Toolkit/1.3beta',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 ()',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.67)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.69)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.70)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.71)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.73)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.74)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.76)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.77)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (04.80)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Nokia7110/1.0 (30.05)',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'PLM''s WapBrowser',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'QWAPPER/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'R380 2.0 WAP1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'SIE-IC35/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'SIE-P35/1.0 UP/4.1.2a',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'SIE-P35/1.0 UP/4.1.2a',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.01-IG01',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.01-QC31',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.02-MC01',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.02-SY01',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/3.1-UPG1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UP.Browser/4.1.2a-XXXX',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'UPG1 UP/4.0.7',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Wapalizer/1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Wapalizer/1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapIDE-SDK/2.0; (R320s (Arial))',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPJAG Virtual WAP',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPJAG Virtual WAP',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPman Version 1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WAPman Version 1.1 beta:Build W2000020401',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Waptor 1.0',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.00',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.20371',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.28',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.37',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.46',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WapView 0.47',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'WinWAP 2.2 WML 1.1',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'wmlb',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'YourWap/0.91',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'YourWap/1.16',
       NULL,
       NULL,
       sysdate
from dual;

insert into wap_user_agents
(user_agent_id,name,creation_comment,creation_user,creation_date)
select wap_user_agent_id_sequence.nextval,
       'Zetor',
       NULL,
       NULL,
       sysdate
from dual;


alter table acs_modules add (
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


alter table contest_domains add (
	confirm_entry	varchar(4000),
	voting_p	char(1) 
			constraint cd_voting_p_ck check(voting_p in ('t','f'))
);


alter table contest_extra_columns add (	
	-- entry form will sort by this column
	sort_column		integer,
	constraint cec_domain_id_actual_name_pk primary key (domain_id, column_actual_name)
);

alter table contest_extra_columns modify (column_pretty_name varchar(200));

alter table ec_orders add (tax_exempt_p char(1) default 'f' check(tax_exempt_p in ('t', 'f')));

create or replace view ec_orders_reportable
as 
select * 
from ec_orders 
where order_state <> 'in_basket'
and order_state <> 'void';

-- orders that have items which still need to be shipped
create or replace view ec_orders_shippable
as
select *
from ec_orders
where order_state in ('authorized_plus_avs','authorized_minus_avs','partially_fulfilled');


alter table ec_products add (
	-- for stuff that can't be shipped like services
	no_shipping_avail_p	char(1) default 'f' check(no_shipping_avail_p in ('t', 'f')),
	-- email this list on purchase
	email_on_purchase_list	varchar(4000)
);

create or replace view ec_products_displayable
as
select * from ec_products
where active_p='t';

create or replace view ec_products_searchable
as
select * from ec_products
where active_p='t' and present_p='t';


alter table ec_shipments add (shippable_p char(1) default 't' check(shippable_p in ('t', 'f')));


alter table ticket_domain_project_map add (mapping_key varchar(200) unique);


-- views for assignments, exams, and projects
create or replace view edu_projects
as 
  select
  task_id as project_id,
  class_id,
  task_type,
  assigned_by as teacher_id,
  grade_id,
  task_name as project_name,
  description,
  date_assigned,
  last_modified,
  due_date,
  file_id,
  self_assignable_p,
  self_assign_deadline,
  weight,
  requires_grade_p,
  online_p as electronic_submission_p
from edu_student_tasks 
where task_type='project'
and active_p='t';



-- we want to bump up the constraint on the column from 30 to 4000
alter table wp_presentations add (temp_page_signature varchar2(4000));
update wp_presentations set temp_page_signature = page_signature;
alter table wp_presentations drop column page_signature;
alter table wp_presentations add (page_signature varchar2(4000));
update wp_presentations set page_signature = temp_page_signature;
alter table wp_presentations drop column temp_page_signature;


create or replace function ec_tax (v_price IN number, v_shipping IN number, v_order_id IN integer) return number
IS
	taxes			ec_sales_tax_by_state%ROWTYPE;
	tax_exempt_p		ec_orders.tax_exempt_p%TYPE;
BEGIN
	SELECT tax_exempt_p INTO tax_exempt_p
	FROM ec_orders
	WHERE order_id = v_order_id;

	IF tax_exempt_p = 't' THEN
		return 0;
	END IF;	
	
	SELECT t.* into taxes
	FROM ec_orders o, ec_addresses a, ec_sales_tax_by_state t
	WHERE o.shipping_address=a.address_id
	AND a.usps_abbrev=t.usps_abbrev(+)
	AND o.order_id=v_order_id;

	IF nvl(taxes.shipping_p,'f') = 'f' THEN
		return nvl(taxes.tax_rate,0) * v_price;
	ELSE
		return nvl(taxes.tax_rate,0) * (v_price + v_shipping);
	END IF;
END;
/
show errors


create or replace function ticket_one_if_high_priority (priority IN integer, status IN varchar)
return integer
is
BEGIN
  IF ((priority = 1) AND (status <> 'closed') AND (status <> 'deferred')) THEN
    return 1;
  ELSE 
    return 0;   
  END IF;
END ticket_one_if_high_priority;
/
show errors


create or replace function ticket_one_if_blocker (severity IN varchar, status IN varchar)
return integer
is
BEGIN
  IF ((severity = 'showstopper') AND (status <> 'closed') AND (status <> 'deferred')) THEN
    return 1;
  ELSE 
    return 0;   
  END IF;
END ticket_one_if_blocker;
/
show errors
