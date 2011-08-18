--
-- data model for ACS security
--
-- created by jsalz@mit.edu on Feb 2, 2000
-- adapted from code by kai@arsdigita.com
--

create table sec_sessions (
    -- Unique ID (don't care if everyone knows this)
    session_id            integer primary key,
    user_id               references users,
    -- A secret used for unencrypted connections
    token                 varchar(50) not null,
    -- A secret used for encrypted connections only. not generated until needed
    secure_token          varchar(50),
    browser_id            integer not null,
    -- Make sure all hits in this session are from same host
    last_ip               varchar(50) not null,
    -- When was the last hit from this session? (seconds since the epoch)
    last_hit              integer not null
);

create table sec_login_tokens (
    -- A table to track tokens assigned for permanent login. The login_token
    -- is isomorphic to the password, i.e., the user can use the login_token
    -- to log back in.
    user_id	references users not null,
    password    varchar(30) not null,
    login_token varchar2(50) not null,
    primary key(user_id, password)
);

-- When a user changes his password, delete any login tokens associated
-- with the old password.
create or replace trigger users_update_login_token
before update on users
for each row
begin
    delete from sec_login_tokens
    where user_id = :new.user_id and password != :new.password;
end;
/
show errors

create table sec_session_properties (
    session_id     references sec_sessions not null,
    module         varchar2(50) not null,
    property_name  varchar2(50) not null,
    property_value clob,
    -- transmitted only across secure connections?
    secure_p       char(1) check(secure_p in ('t','f')),
    primary key(session_id, module, property_name),
    foreign key(session_id) references sec_sessions on delete cascade
);

create table sec_browser_properties (
    browser_id     integer not null,
    module         varchar2(50) not null,
    property_name  varchar2(50) not null,
    property_value clob,
    -- transmitted only across secure connections?
    secure_p       char(1) check(secure_p in ('t','f')),
    primary key(browser_id, module, property_name)
);

create sequence sec_id_seq;

create or replace procedure sec_rotate_last_visit(
    v_browser_id IN sec_browser_properties.browser_id%TYPE,
    v_time IN integer
) is
begin
    delete from sec_browser_properties
        where browser_id = v_browser_id and module = 'acs' and property_name = 'second_to_last_visit';
    update sec_browser_properties
        set property_name = 'second_to_last_visit'
        where module = 'acs' and property_name = 'last_visit' and browser_id = v_browser_id;
    insert into sec_browser_properties(browser_id, module, property_name, property_value, secure_p)
        values(v_browser_id, 'acs', 'last_visit', to_char(v_time), 'f');
end;
/
show errors
