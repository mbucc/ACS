--
-- content-tagging.sql 
--
-- by philg@mit.edu on April 26, 1999
--

-- if upgrading from an older version of the ACS
-- alter table users_preferences add content_mask integer;

create table content_tags (
    word               varchar(100) primary key,
    tag		       integer not null,
    creation_user      integer not null references users,
    creation_date      date
);

-- for cases when users are posting naughty stuff 

create table naughty_events (
    table_name            varchar(30),
    the_key               varchar(700),
    offensive_text        clob,
    creation_user         integer not null references users,
    creation_date         date,
    reviewed_p            char(1) default 'f' check (reviewed_p in ('t','f'))
);

create table naughty_table_to_url_map (
    table_name      varchar(30) primary key,
    url_stub        varchar(200) not null
);      
