-- upgrade from ACS 2.0 to 2.1
-- started by philg@mit.edu on September 5, 1999

-- general comments stuff

create table general_comments_table_map (
	table_name      varchar(30) primary key,
	section_name	varchar(100) not null,
	user_url_stub	varchar(200) not null,
	admin_url_stub	varchar(200) not null
);

declare
 n_news_rows		integer;
 n_calendar_rows	integer;
 n_classified_rows	integer;
begin
 select count(*) into n_news_rows from general_comments_table_map where table_name = 'news';
 if n_news_rows = 0 then 
   insert into general_comments_table_map
    (table_name, section_name, user_url_stub, admin_url_stub)
    values
    ('news','News','/news/item.tcl?news_id=','/admin/news/item.tcl?news_id=');
 end if;
 select count(*) into n_calendar_rows from general_comments_table_map where table_name = 'calendar';
 if n_calendar_rows = 0 then 
   insert into general_comments_table_map
    (table_name, section_name, user_url_stub, admin_url_stub)
    values
    ('calendar','Calendar','/calendar/item.tcl?calendar_id=','/admin/calendar/item.tcl?calendar_id=');
 end if;
 select count(*) into n_classified_rows from general_comments_table_map where table_name = 'classified_ads';
 if n_classified_rows = 0 then 
   insert into general_comments_table_map
    (table_name, section_name, user_url_stub, admin_url_stub)
    values
    ('classified_ads','Classifieds','/gc/view-one.tcl?classified_ad_id=','/admin/gc/edit-ad.tcl?classified_ad_id=');
 end if;
end;
/

update general_comments 
set one_line_item_desc = (select title from news where news_id = on_what_id)
where one_line_item_desc is null
and on_which_table = 'news' ;

update general_comments 
set one_line_item_desc = (select title from calendar where calendar_id = on_what_id)
where one_line_item_desc is null
and on_which_table = 'calendar' ;

update general_comments 
set one_line_item_desc = (select about || ' : ' || title from neighbor_to_neighbor where neighbor_to_neighbor_id = on_what_id)
where one_line_item_desc is null
and on_which_table = 'neighbor_to_neighbor' ;

--- let's now make attachments work 

alter table general_comments add (
	attachment		blob,
	client_file_name	varchar(500),
	file_type		varchar(100),
	file_extension		varchar(50),
	caption			varchar(4000),
	original_width		integer,
	original_height		integer
);

-- let's allow comment titles

alter table general_comments add (
	one_line		varchar(200)
);

--- add the procedure stuff for the intranet


create sequence intranet_procedure_id_seq;

create table intranet_procedures (
    procedure_id            integer not null primary key,
    name                    varchar(200) not null,
    note                    varchar(4000),
    creation_date           date not null,
    creation_user           integer not null references users,
    last_modified           date,
    last_modifying_user     integer references users
);

-- Users certified to do a certain procedure

create table intranet_procedure_users (
    procedure_id        integer not null references intranet_procedures,
    user_id             integer not null references users,
    note                varchar(400),
    certifying_user     integer not null references users,
    certifying_date     date not null,
    primary key(procedure_id, user_id)
);

-- Occasions the procedure was done by a junior person,
-- under the supervision of a certified person

create sequence intranet_proc_event_id_seq;

create table intranet_procedure_events (
    event_id            integer not null primary key,
    procedure_id        integer not null references intranet_procedures,
    -- the person who did the procedure
    user_id             integer not null references users,
    -- the certified user who supervised
    supervising_user    integer not null references users,
    event_date          date not null,
    note                varchar(1000)
);

-- allow file storage to take urls
alter table fs_files add ( 
   url varchar(200)
);

