-- /packages/acs-core/apm.sql
--
-- Data model for the package manager.
--
-- jsalz@mit.edu, 30 April 2000
--
-- apm.sql,v 1.10 2000/06/17 18:47:49 ron Exp

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
-- PARAMETER STUFF (kscaldef@theory.caltech.edu)
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

