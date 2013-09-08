-- 
-- A general comment facility 
--
-- created by philg@mit.edu on 11/20/98
-- (and substantially upgraded by philg 9/5/99)
-- (and upgrade to use table_acs_properties by philg on 10/31/99)

-- this is used for when people want to comment on a news article
-- or calendar posting or other tables that are yet to be 
-- built; we don't mix in the page comments or the discussion
-- forums here, though perhaps we should...

create sequence general_comment_id_sequence start with 1;

create table general_comments (
	comment_id		integer primary key,
	on_what_id		integer not null,
	on_which_table		varchar(50),
	-- a description of what we're commenting on 
	one_line_item_desc	varchar(200) not null,
	user_id			not null references users,
        scope			varchar(20) default 'public' not null,
	constraint general_comments_scope_check check (scope in ('public', 'group')),
	-- group_id of the group for which this general comment was submitted
	group_id		references user_groups,
	comment_date		date not null,
	ip_address		varchar(50) not null,
	modified_date		date,
	one_line		varchar(200),
	content			clob,
	-- is the content in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	approved_p		char(1) default 't' check(approved_p in ('t','f')),
	-- columns useful for attachments, column names
	-- lifted from file-storage.sql and bboard.sql
	-- this is where the actual content is stored
	attachment		blob,
	-- file name including extension but not path
	client_file_name	varchar(500),
	file_type		varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	file_extension		varchar(50), 	-- e.g., "jpg"
	-- fields that only make sense if this is an image
	caption			varchar(4000),
	original_width		integer,
	original_height		integer
);

create trigger general_comments_modified
before insert or update on general_comments
for each row
begin
 :new.modified_date :=SYSDATE;
end;
/
show errors

-- an index useful when printing out content to the public 

create index general_comments_cidx on general_comments(on_which_table, on_what_id);

-- an index useful when printing out a user history

create index general_comments_uidx on general_comments(user_id);


-- store pre-modification content
-- these are all pre-modification values

-- no integrity constraints because we don't want to interfere with a
-- comment being deleted

create table general_comments_audit (
	comment_id		integer,
	-- who did the modification and from where
	user_id			integer not null,
	ip_address		varchar(50) not null,
	audit_entry_time	date,
	-- the old modified date that goes with this content
	modified_date		date,
	content			clob,
	one_line		varchar(200)
);

declare
 n_news_rows		integer;
 n_calendar_rows	integer;
 n_classified_rows	integer;
 n_neighbor_rows	integer;
begin
 select count(*) into n_news_rows from table_acs_properties where table_name = 'news';
 if n_news_rows = 0 then 
   insert into table_acs_properties
    (table_name, module_key, section_name, user_url_stub, admin_url_stub)
    values
    ('news_items', 'news', 'News','/news/item.tcl?news_item_id=','/news/admin/item.tcl?news_item_id=');
 end if;
 select count(*) into n_calendar_rows from table_acs_properties where table_name = 'calendar';
 if n_calendar_rows = 0 then 
   insert into table_acs_properties
    (table_name, module_key, section_name, user_url_stub, admin_url_stub)
    values
    ('calendar', 'calendar', 'Calendar','/calendar/item.tcl?calendar_id=','/calendar/admin/item.tcl?calendar_id=');
 end if;
 select count(*) into n_classified_rows from table_acs_properties where table_name = 'classified_ads';
 if n_classified_rows = 0 then 
   insert into table_acs_properties
    (table_name, section_name, user_url_stub, admin_url_stub)
    values
    ('classified_ads','Classifieds','/gc/view-one.tcl?classified_ad_id=','/admin/gc/edit-ad.tcl?classified_ad_id=');
 end if;
 select count(*) into n_neighbor_rows from table_acs_properties where table_name = 'neighbor_to_neighbor';
 if n_neighbor_rows = 0 then 
   insert into table_acs_properties
    (table_name, section_name, user_url_stub, admin_url_stub)
    values
    ('neighbor_to_neighbor','Neighbor to Neighbor','/neighbor/view-one.tcl?neighbor_to_neighbor_id=','/admin/neighbor/view-one.tcl?neighbor_to_neighbor_id=');
 end if;
end;
/


CREATE OR replace trigger news_gc_delete
  after DELETE
  ON news_items
  FOR each row
BEGIN
  DELETE FROM general_comments
    WHERE on_which_table = 'news_items'
    AND on_what_id = :old.news_item_id;
END;
/

CREATE OR replace trigger calendar_gc_delete
  after DELETE
  ON calendar
  FOR each row
BEGIN
  DELETE FROM general_comments
    WHERE on_which_table = 'calendar'
    AND on_what_id = :old.calendar_id;
END;
/

CREATE OR replace trigger classified_ads_gc_delete
  after DELETE
  ON classified_ads
  FOR each row
BEGIN
  DELETE FROM general_comments
    WHERE on_which_table = 'classified_ads'
    AND on_what_id = :old.classified_ad_id;
END;
/

CREATE OR replace trigger n_to_n_gc_delete
  after DELETE
  ON neighbor_to_neighbor
  FOR each row
BEGIN
  DELETE FROM general_comments
    WHERE on_which_table = 'neighbor_to_neighbor'
    AND on_what_id = :old.neighbor_to_neighbor_id;
END;
/




