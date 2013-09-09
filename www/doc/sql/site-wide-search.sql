--
-- site-wide-search.sql 
--
-- part of the ArsDigita Community System
-- created by philg@mit.edu on March 13, 1999
--
-- modified by: 
--   branimir@arsdigita.com 2000-02-02
--   lars@arsdigita.com March 14, 2000
--   mbryzek@arsdigita.com July 6, 2000
--     added length checking to provide better user error messages
--   bquinn@arsdigita.com July 25, 2000
--     made it easy to customize the name of the datastore and datastore_proc.
--   phong@arsdigita.com July 2000
-- 
-- Note: execute this script by calling load-site-wide-search
-- Expects three arguments: username password password-for-ctxsys
--
--
-- Note: Oracle names can only be a maximum of 30 characters
--       There two parts in this file that uses the user's 
--       service name as part of a procedure name. If your 
--       service name is longer than 16 characters, you will
--       have to shorten the below string.
--       
-- sws_user_proc_&1 (two occurences)
--
--
-- Read /doc/site-wide-search.html and upgrade your InterMedia 
-- to 8.1.5.1 or 8.1.6.
--
--
--------------------------------------------------------------------------------
connect &1/&2

create table site_wide_index (
	table_name	     	varchar(30) not null,
	the_key		     	varchar(700) not null,
	one_line_description 	varchar(4000) not null,
	datastore		char(1) not null, -- place holder for datastore column
        scope                   varchar(20) default 'public',
        group_id                references user_groups,
        user_id                 references users,
        constraint sws_scope_check check ((scope='group' and group_id is not null) or 
                                          (scope='user' and user_id is not null) or
                                          (scope='public')),
	primary key (table_name, the_key)
);

create table sws_properties (
  table_name varchar2(30) primary key not null,
  section_name varchar2(100) not null,
  user_url_stub varchar2(200) not null,
  admin_url_stub varchar2(200) not null,
  -- did the user add this, or is it a system added table
  user_defined_p char(1),
  constraint sws_properties_user_def_check check(user_defined_p in ('f', 't')),
  -- the name of the primary key column of the table             
  pk_column varchar2(30),
  -- if flag_column is not 0, then check this column against flag_value.
  -- if they are the same, then index it.
  flag_column varchar2(30),
  flag_value varchar2(4000),
  -- stores the select portion of sql query for one line description
  one_line_sql_select varchar2(4000),
  -- stores the from portion of sql query for one line description
  one_line_sql_from varchar2(4000),
  -- stores the where portion of sql query for one line description
  one_line_sql_where varchar2(4000),
  -- what type of query is the one line description query
  -- if it only references the same table then it is normal
  -- if it only references other tables then it is nonmutating
  -- if it references this table and other tables then it is mutating
  desc_type varchar2(20),
  constraint sws_properties_desc_type_check check(desc_type in ('normal','nonmutating','mutating')),
  -- a space separated list of columns to index
  indexed_columns varchar2(4000),
  -- should the public be able to view this table
  public_p char(1) not null,
  -- extend scoping functionality from indexed table if table supports it
  scope_p char(1) default 'f',
  constraint sws_properties_public_p_check check(public_p in ('f', 't')),
  -- rank the tables in order of relevancy
  rank integer      
);


--checks for general_permissions 
--v_owner_id is the user_id for the owner (if scope is user)
--v_group_id (for scope=group)
--v_user_id is the user_id for the connecting user 
CREATE or replace function sws_general_permissions (v_owner_id IN integer, v_group_id IN integer, v_scope IN varchar2, v_user_id IN integer) 
RETURN VARCHAR
AS
  allowed_p varchar(1);
BEGIN
  IF v_scope='public' THEN
    allowed_p:='t';
  ELSIF v_scope='group' THEN
    select decode(ad_group_member_p(v_user_id,v_group_id),'t','t',ad_group_member_p(v_user_id,group_id)) into allowed_p from user_groups where lower(group_name)='site-wide administration'; 
  ELSIF v_scope='user' AND v_owner_id=v_user_id THEN
    allowed_p :='t';
  ELSE
    allowed_p:='f';
  END IF;
  return allowed_p;
END;
/
show errors



-- BBoard indexing

insert into sws_properties (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, rank)
values ('bboard', 'Discussion Forums', '/bboard/redirect-for-sws.tcl?msg_id=', '/bboard/admin-q-and-a-fetch-msg.tcl', 'f', 't', 2);

CREATE or replace trigger bboard_sws_insert_tr
  after INSERT ON bboard FOR each row
BEGIN
  -- Only create new site wide index row if this is the start of
  -- a new thread.
  IF :NEW.refers_to IS NULL THEN
     insert into site_wide_index (table_name, the_key, one_line_description, datastore, group_id, scope)
       select 'bboard', :new.msg_id, :new.one_line, 'a', group_id, decode(read_access,'group','group','public')
       from bboard_topics where topic_id=:new.topic_id;
  ELSE
     -- Cause the datastore procedure to reindex this thread.
     UPDATE site_wide_index SET datastore = 'a' 
       WHERE table_name = 'bboard'
       AND the_key = substr(:NEW.sort_key, 1, 6);
  END IF;
END;
/
show errors

  -- No update trigger for bboard because
  -- a) it is tricky because we are only keeping one index row per thread
  -- b) it doesn't happen all that much, and doesn't matter when it does.

-- this update trigger uses the bboard_topics table to set scoping values    
CREATE OR replace trigger bboard_topics_sws_update_tr
  after UPDATE on bboard_topics for each row
BEGIN
  IF :old.read_access<>'group' and :new.read_access='group' THEN
    update site_wide_index
      set group_id=:new.group_id,
          scope='group'
      where table_name='bboard' and
            the_key in (select msg_id from bboard where topic_id=:new.topic_id);
  ELSIF :old.read_access='group' and :new.read_access<>'group' THEN
    update site_wide_index 
      set group_id=:new.group_id,
          scope='public'
      where table_name='bboard' and
            the_key in (select msg_id from bboard where topic_id=:new.topic_id);
  ELSE
    update site_wide_index
      set scope=(select decode(:new.read_access,'group','group','public') from dual),
          group_id=:new.group_id,
          datastore='a'
      where table_name='bboard'
      and the_key in (select msg_id from bboard where topic_id=:new.topic_id);
  END IF;
END;
/
show errors

    
CREATE OR replace trigger bboard_sws_delete_tr
  after DELETE ON bboard FOR each row
BEGIN
  IF :old.refers_to IS NULL THEN
     -- we're deleting the whole thread, remove the index row.
     DELETE FROM site_wide_index
       WHERE the_key = :old.msg_id
       AND table_name = 'bboard';
  ELSE
     -- just reindex the thread
     UPDATE site_wide_index
       SET datastore = 'a'
       WHERE the_key = substr(:old.sort_key, 1, 6)
       AND table_name = 'bboard';
  END IF;
END;
/
show errors
  

CREATE OR replace procedure bboard_sws_helper (rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_pages_row bboard%ROWTYPE;
  cursor bboard_cursor(v_msg_id CHAR) IS
    SELECT one_line, message, u.first_names || ' ' || u.last_name AS author_name
      FROM bboard b, users u
      WHERE b.sort_key LIKE v_msg_id || '%'
      AND b.user_id = u.user_id;
BEGIN
      -- Get data from every message in the thread.
      FOR bboard_record IN bboard_cursor(p_primary_key) LOOP
         dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');
	 IF bboard_record.one_line IS NOT NULL THEN
	    dbms_lob.writeappend(tlob, length(bboard_record.one_line) + 1, bboard_record.one_line || ' ');
	 END IF;
         dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');
	 dbms_lob.writeappend(tlob, length(bboard_record.author_name) + 1, bboard_record.author_name || ' ');
         IF bboard_record.message IS NOT NULL THEN
	     dbms_lob.append(tlob, bboard_record.message);
	 END IF;
      -- (branimir 2000-02-02 02:02:02) : Add a space so that the last word of this message doesn't get
      -- glued together with the first word of the next message:
      dbms_lob.writeappend(tlob, 1, ' ');
      END LOOP;
END;
/
show errors;

  
-- static pages indexing

insert into sws_properties (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, rank)
values ('static_pages', 'Static Pages', '/search/static-page-redirect.tcl?page_id=', '/admin/static/page-summary.tcl?page_id=', 'f', 't', 1);

-- the old trigger relied upon the index_p column for security
-- since we have scoping, remove all index_p references
CREATE or replace trigger static_pages_sws_insert_tr
  after INSERT ON static_pages FOR each row
BEGIN
  -- we have to create a new row in the index table for this row.
  insert into site_wide_index (table_name, the_key, one_line_description, datastore)
    values ('static_pages', :new.page_id, :new.page_title, 'a');
END;
/
show errors
  

CREATE OR replace trigger static_pages_sws_update_tr
  after UPDATE ON static_pages FOR each row
BEGIN
     update site_wide_index 
       set the_key = :new.page_id, 
           one_line_description = nvl(:new.page_title, '(no title)'), 
           datastore = 'a'
       where table_name = 'static_pages'
       and the_key = :old.page_id;
end;
/
show errors
  
  
CREATE OR replace trigger static_pages_sws_delete_tr
  after DELETE ON static_pages FOR each row
BEGIN
  DELETE FROM site_wide_index
    WHERE table_name = 'static_pages'
    AND the_key = :old.page_id;
END;
/
show errors


CREATE OR replace procedure static_pages_sws_helper (rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_static_pages_row static_pages%ROWTYPE;
BEGIN
  SELECT * INTO v_static_pages_row
    FROM static_pages
    WHERE page_id = p_primary_key;
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
  dbms_lob.append(tlob, v_static_pages_row.PAGE_BODY);
END;
/
show errors;


-- user comments indexing

insert into sws_properties (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, rank)
  values ('comments', 'User Comments', '/comments/one.tcl?comment_id=', '/admin/comments/persistent-edit.tcl?comment_id=', 'f', 't', 3);


CREATE OR replace FUNCTION subject_for_comment (v_page_id INTEGER) return VARCHAR IS
   v_page_title static_pages.page_title%TYPE;
BEGIN
   SELECT 'Comment on <i>' || nvl(page_title, 'untitled static page') || '</i>' INTO v_page_title
     FROM static_pages
     WHERE page_id = v_page_id;
   RETURN v_page_title;
END;
/
show errors
  

create or replace trigger comments_sws_insert_tr
  after INSERT ON comments FOR each row
  WHEN (NEW.deleted_p = 'f' AND NEW.comment_type = 'alternative_perspective')
BEGIN
  insert into site_wide_index (table_name, the_key, one_line_description, datastore)
    values ('comments', :new.comment_id, subject_for_comment(:NEW.page_id), 'a');
END;
/
show errors


CREATE OR replace trigger comments_sws_update_tr
  after UPDATE ON comments
  FOR each row
  WHEN (NEW.comment_type = 'alternative_perspective')
BEGIN
  IF :old.deleted_p = 't' AND :NEW.deleted_p = 'f' THEN
     insert into site_wide_index (table_name, the_key, one_line_description, datastore)
       values ('comments', :new.comment_id, subject_for_comment(:NEW.page_id), 'a');
  ELSIF :old.deleted_p = 'f' AND :NEW.deleted_p = 't' THEN
     DELETE FROM site_wide_index
       WHERE table_name = 'comments'
       AND the_key = :old.comment_id;
  ELSIF :NEW.deleted_p = 'f' THEN
     update site_wide_index 
       set the_key = :new.comment_id, one_line_description = subject_for_comment(:NEW.page_id), datastore = 'a'
       where table_name = 'comments'
       AND the_key = :old.comment_id;
  END IF;
end;
/
show errors
  
  
CREATE OR replace trigger comments_sws_delete_tr
  after DELETE ON comments FOR each row
  WHEN (old.deleted_p = 'f' AND old.comment_type = 'alternative_perspective')
BEGIN
  DELETE FROM site_wide_index
    WHERE table_name = 'comments'
    AND the_key = :old.comment_id;
END;
/
show errors


CREATE OR replace procedure comments_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
   TYPE comment_rec IS RECORD (
     message clob,
     author_name VARCHAR(300));
   v_comment_row comment_rec;
BEGIN
      SELECT message, u.first_names || ' ' || u.last_name AS author_name
        INTO v_comment_row
	FROM comments c, users u
	WHERE c.user_id = u.user_id
	AND c.comment_id = p_primary_key;
      dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
      dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
      dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
      dbms_lob.writeappend(tlob, length(v_comment_row.author_name) + 1, v_comment_row.author_name || ' ');
      dbms_lob.append(tlob, v_comment_row.message);
END;
/
show errors

-- wimpy point indexing

insert into sws_properties
  (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, pk_column, flag_column, flag_value, one_line_sql_select, one_line_sql_from, one_line_sql_where, desc_type, indexed_columns, public_p, scope_p, rank)
  values
  ('wp_slides', 'Wimpy Point', '/wp/redirect-for-sws?slide_id=', '/wp/redirect-for-sws?slide_id=', 't', 'slide_id', '', '', 'title', 'wp_slides', 'slide_id=p_primary_key', 'normal', 'BULLET_ITEMS POSTAMBLE PREAMBLE TITLE', 'f', 't', 4);

create or replace function wp_slides_sws_scope_fn (v_public_p IN varchar2,v_group_id IN integer)
return varchar2
IS
BEGIN
  IF v_public_p='t' THEN
    return 'public';
  ELSIF v_group_id is NULL THEN
    return 'user';
  ELSE 
    return 'group';
  END IF;
END;
/
show errors

create or replace trigger wp_slides_sws_insert_tr
  after insert on wp_slides for each row
BEGIN
  insert into site_wide_index (table_name, the_key, one_line_description, datastore, scope, group_id, user_id)
  select 'wp_slides', :new.slide_id, :new.title, 'a', wp_slides_sws_scope_fn(public_p,group_id),group_id,creation_user
  from wp_presentations
  where presentation_id=:new.presentation_id;
END;
/
show errors

-- we need to triggers for wimpy point updates
create or replace trigger wp_slides_sws_update_tr
  after update on wp_slides FOR each row
BEGIN
    update site_wide_index
      set one_line_description = :new.title,
          the_key = :new.slide_id,
          datastore = 'a'
      where table_name = 'wp_slides' and
            the_key = :old.slide_id;
END;
/
show errors;

create or replace trigger wp_presentations_sws_update_tr
  after update on wp_presentations for each row
BEGIN
  update site_wide_index
  set scope=(select wp_slides_sws_scope_fn(:new.public_p,:new.group_id) from dual),
      group_id=:new.group_id,
      user_id=:new.creation_user,
      datastore = 'a'
  where table_name='wp_slides'
        and the_key in (select slide_id from wp_slides where presentation_id=:old.presentation_id);
END;
/
show errors

create or replace trigger wp_slides_sws_delete_tr
  after delete on wp_slides for each row
BEGIN
  delete from site_wide_index
  where table_name = 'wp_slides' and the_key = :old.slide_id;
END;
/
show errors;

create or replace procedure wp_slides_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_pages_row wp_slides%ROWTYPE;  
BEGIN
  SELECT *
    INTO v_pages_row
    FROM wp_slides
    WHERE slide_id = p_primary_key;
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
  dbms_lob.append(tlob, v_pages_row.BULLET_ITEMS);
  dbms_lob.append(tlob, v_pages_row.POSTAMBLE);
  dbms_lob.append(tlob, v_pages_row.PREAMBLE);
  IF (v_pages_row.TITLE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.TITLE) + 1, v_pages_row.TITLE || ' ');
  END IF;
END;
/
show errors;


-- intranet facilities indexing

insert into sws_properties
  (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, pk_column, flag_column, flag_value, one_line_sql_select, one_line_sql_from, one_line_sql_where, desc_type, indexed_columns)
  values
  ('im_facilities', 'Facilities', '/intranet/facilities/view?facility_id=', '/intranet/facilities/view?facility_id=', 'f', 'f', 'facility_id', '0', '', 'facility_name', 'im_facilities', 'facility_id=p_primary_key', 'normal', 'FACILITY_NAME PHONE FAX ADDRESS_LINE1 ADDRESS_LINE2 ADDRESS_CITY ADDRESS_STATE ADDRESS_POSTAL_CODE ADDRESS_COUNTRY_CODE LANDLORD SECURITY NOTE');

create or replace trigger im_facilities_sws_insert_tr
  after insert on im_facilities FOR each row
BEGIN
  insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_facilities', :new.facility_id, :new.facility_name, 'a');
END;
/
show errors;

create or replace trigger im_facilities_sws_update_tr
  after update on im_facilities FOR each row
BEGIN
    update site_wide_index
      set one_line_description = :new.facility_name,
          the_key = :new.facility_id,
          datastore = 'a'
      where table_name = 'im_facilities' and
            the_key = :old.facility_id;
END;
/
show errors;

create or replace trigger im_facilities_sws_delete_tr
  after delete on im_facilities for each row
BEGIN
  delete from site_wide_index
  where table_name = 'im_facilities' and the_key = :old.facility_id;
END;
/
show errors;

create or replace procedure im_facilities_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_pages_row im_facilities%ROWTYPE;  
BEGIN
  SELECT *
    INTO v_pages_row
    FROM im_facilities
    WHERE facility_id = p_primary_key;
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
  IF (v_pages_row.FACILITY_NAME IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.FACILITY_NAME) + 1, v_pages_row.FACILITY_NAME || ' ');
  END IF;
  IF (v_pages_row.PHONE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.PHONE) + 1, v_pages_row.PHONE || ' ');
  END IF;
  IF (v_pages_row.FAX IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.FAX) + 1, v_pages_row.FAX || ' ');
  END IF;
  IF (v_pages_row.ADDRESS_LINE1 IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.ADDRESS_LINE1) + 1, v_pages_row.ADDRESS_LINE1 || ' ');
  END IF;
  IF (v_pages_row.ADDRESS_LINE2 IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.ADDRESS_LINE2) + 1, v_pages_row.ADDRESS_LINE2 || ' ');
  END IF;
  IF (v_pages_row.ADDRESS_CITY IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.ADDRESS_CITY) + 1, v_pages_row.ADDRESS_CITY || ' ');
  END IF;
  IF (v_pages_row.ADDRESS_STATE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.ADDRESS_STATE) + 1, v_pages_row.ADDRESS_STATE || ' ');
  END IF;
  IF (v_pages_row.ADDRESS_POSTAL_CODE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.ADDRESS_POSTAL_CODE) + 1, v_pages_row.ADDRESS_POSTAL_CODE || ' ');
  END IF;
  IF (v_pages_row.ADDRESS_COUNTRY_CODE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.ADDRESS_COUNTRY_CODE) + 1, v_pages_row.ADDRESS_COUNTRY_CODE || ' ');
  END IF;
  IF (v_pages_row.LANDLORD IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.LANDLORD) + 1, v_pages_row.LANDLORD || ' ');
  END IF;
  IF (v_pages_row.SECURITY IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.SECURITY) + 1, v_pages_row.SECURITY || ' ');
  END IF;
  IF (v_pages_row.NOTE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.NOTE) + 1, v_pages_row.NOTE || ' ');
  END IF;
END;
/
show errors;

-- intranet customers indexing

insert into sws_properties
  (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, pk_column, flag_column, flag_value, one_line_sql_select, one_line_sql_from, one_line_sql_where, desc_type, indexed_columns)
  values
  ('im_customers', 'Customers', '/intranet/customers/view?group_id=', '/intranet/customers/view?group_id=', 'f', 'f', 'group_id', 'DELETED_P', 't', 'group_name', 'user_groups', 'group_id=p_primary_key', 'nonmutating', 'NOTE REFERRAL_SOURCE');

create or replace function im_customers_sws_desc (p_primary_key IN varchar)
RETURN VARCHAR
AS
  v_one_line varchar2(4000);
BEGIN

  select group_name 
    INTO v_one_line
  from user_groups
  where group_id=p_primary_key;

  -- make sure that one line description is not empty
  IF v_one_line IS NULL OR v_one_line = ' ' THEN
    v_one_line := 'not available';
  END IF;

  RETURN(v_one_line);
END;
/
show errors;

create or replace trigger im_customers_sws_insert_tr
  after insert on im_customers FOR each row
  WHEN (NEW.DELETED_P = 'f')
BEGIN
  insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_customers', :new.group_id, im_customers_sws_desc(:new.group_id), 'a');
END;
/
show errors;

create or replace trigger im_customers_sws_update_tr
  after update on im_customers FOR each row
BEGIN
  IF NOT (:old.DELETED_P = 'f') AND :new.DELETED_P = 'f' THEN
    insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_customers', :new.group_id, im_customers_sws_desc(:new.group_id), 'a');
  ELSIF :old.DELETED_P = 'f' AND NOT (:new.DELETED_P = 'f') THEN
    delete from site_wide_index
    where table_name = 'im_customers' and
          the_key = :old.group_id;
  ELSIF :new.DELETED_P = 'f' THEN
    update site_wide_index
      set one_line_description = im_customers_sws_desc(:new.group_id),
          the_key = :new.group_id,
          datastore = 'a'
      where table_name = 'im_customers' and
            the_key = :old.group_id;
  END IF;
END;
/
show errors;

create or replace trigger im_customers_sws_delete_tr
  after delete on im_customers for each row
  WHEN (old.DELETED_P = 'f')
BEGIN
  delete from site_wide_index
  where table_name = 'im_customers' and the_key = :old.group_id;
END;
/
show errors;

create or replace procedure im_customers_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_pages_row im_customers%ROWTYPE;  
BEGIN
  SELECT *
    INTO v_pages_row
    FROM im_customers
    WHERE group_id = p_primary_key;
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
  IF (v_pages_row.NOTE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.NOTE) + 1, v_pages_row.NOTE || ' ');
  END IF;
  IF (v_pages_row.REFERRAL_SOURCE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.REFERRAL_SOURCE) + 1, v_pages_row.REFERRAL_SOURCE || ' ');
  END IF;
END;
/
show errors;


-- intranet offices indexing

insert into sws_properties
  (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, pk_column, flag_column, flag_value, one_line_sql_select, one_line_sql_from, one_line_sql_where, desc_type, indexed_columns)
  values
  ('im_offices', 'Offices', '/intranet/offices/view?group_id=', '/intranet/offices/view?group_id=', 'f', 'f', 'group_id', 'PUBLIC_P', 't', 'group_name', 'user_groups', 'group_id=p_primary_key', 'nonmutating', '');


create or replace function im_offices_sws_desc (p_primary_key IN varchar)
RETURN VARCHAR
AS
  v_one_line varchar2(4000);
BEGIN

  select group_name 
    INTO v_one_line
  from user_groups
  where group_id=p_primary_key;

  -- make sure that one line description is not empty
  IF v_one_line IS NULL OR v_one_line = ' ' THEN
    v_one_line := 'not available';
  END IF;

  RETURN(v_one_line);
END;
/
show errors;


create or replace trigger im_offices_sws_insert_tr
  after insert on im_offices FOR each row
  WHEN (NEW.PUBLIC_P = 't')
BEGIN
  insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_offices', :new.group_id, im_offices_sws_desc(:new.group_id), 'a');
END;
/
show errors;


create or replace trigger im_offices_sws_update_tr
  after update on im_offices FOR each row
BEGIN
  IF NOT (:old.PUBLIC_P = 't') AND :new.PUBLIC_P = 't' THEN
    insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_offices', :new.group_id, im_offices_sws_desc(:new.group_id), 'a');
  ELSIF :old.PUBLIC_P = 't' AND NOT (:new.PUBLIC_P = 't') THEN
    delete from site_wide_index
    where table_name = 'im_offices' and
          the_key = :old.group_id;
  ELSIF :new.PUBLIC_P = 't' THEN
    update site_wide_index
      set one_line_description = im_offices_sws_desc(:new.group_id),
          the_key = :new.group_id,
          datastore = 'a'
      where table_name = 'im_offices' and
            the_key = :old.group_id;
  END IF;
END;
/
show errors;


create or replace trigger im_offices_sws_delete_tr
  after delete on im_offices for each row
  WHEN (old.PUBLIC_P = 't')
BEGIN
  delete from site_wide_index
  where table_name = 'im_offices' and the_key = :old.group_id;
END;
/
show errors;

create or replace procedure im_offices_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
BEGIN
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
END;
/
show errors;


-- intranet projects indexing
insert into sws_properties
  (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, pk_column, flag_column, flag_value, one_line_sql_select, one_line_sql_from, one_line_sql_where, desc_type, indexed_columns)
  values
  ('im_projects', 'Projects', '/intranet/projects/view?group_id=', '/intranet/projects/view?group_id=', 'f', 'f', 'group_id', '0', '', 'group_name', 'user_groups', 'group_id=p_primary_key', 'nonmutating', 'DESCRIPTION NOTE');

create or replace function im_projects_sws_desc (p_primary_key IN varchar)
RETURN VARCHAR
AS
  v_one_line varchar2(4000);
BEGIN

  select group_name 
    INTO v_one_line
  from user_groups
  where group_id=p_primary_key;

  -- make sure that one line description is not empty
  IF v_one_line IS NULL OR v_one_line = ' ' THEN
    v_one_line := 'not available';
  END IF;

  RETURN(v_one_line);
END;
/
show errors;

create or replace trigger im_projects_sws_insert_tr
  after insert on im_projects FOR each row
BEGIN
  insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_projects', :new.group_id, im_projects_sws_desc(:new.group_id), 'a');
END;
/
show errors;

create or replace trigger im_projects_sws_update_tr
  after update on im_projects FOR each row
BEGIN
    update site_wide_index
      set one_line_description = im_projects_sws_desc(:new.group_id),
          the_key = :new.group_id,
          datastore = 'a'
      where table_name = 'im_projects' and
            the_key = :old.group_id;
END;
/
show errors;

create or replace trigger im_projects_sws_delete_tr
  after delete on im_projects for each row
BEGIN
  delete from site_wide_index
  where table_name = 'im_projects' and the_key = :old.group_id;
END;
/
show errors;

create or replace procedure im_projects_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_pages_row im_projects%ROWTYPE;  
BEGIN
  SELECT *
    INTO v_pages_row
    FROM im_projects
    WHERE group_id = p_primary_key;
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
  IF (v_pages_row.DESCRIPTION IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.DESCRIPTION) + 1, v_pages_row.DESCRIPTION || ' ');
  END IF;
  IF (v_pages_row.NOTE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.NOTE) + 1, v_pages_row.NOTE || ' ');
  END IF;
END;
/
show errors;


-- intranet partners indexing

insert into sws_properties
  (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p, pk_column, flag_column, flag_value, one_line_sql_select, one_line_sql_from, one_line_sql_where, desc_type, indexed_columns)
  values
  ('im_partners', 'Partners', '/intranet/partners/view.tcl?group_id=', '/intranet/partners/view.tcl?group_id=', 'f', 'f', 'group_id', 'DELETED_P', 'f', 'group_name', 'user_groups', 'group_id=p_primary_key', 'nonmutating', 'URL NOTE REFERRAL_SOURCE');


create or replace function im_partners_sws_desc (p_primary_key IN varchar)
RETURN VARCHAR
AS
  v_one_line varchar2(4000);
BEGIN

  select group_name 
    INTO v_one_line
  from user_groups
  where group_id=p_primary_key;

  -- make sure that one line description is not empty
  IF v_one_line IS NULL OR v_one_line = ' ' THEN
    v_one_line := 'not available';
  END IF;

  RETURN(v_one_line);
END;
/
show errors;

create or replace trigger im_partners_sws_insert_tr
  after insert on im_partners FOR each row
  WHEN (NEW.DELETED_P = 'f')
BEGIN
  insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_partners', :new.group_id, im_partners_sws_desc(:new.group_id), 'a');
END;
/
show errors;

create or replace trigger im_partners_sws_update_tr
  after update on im_partners FOR each row
BEGIN
  IF NOT (:old.DELETED_P = 'f') AND :new.DELETED_P = 'f' THEN
    insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
    values
    ('im_partners', :new.group_id, im_partners_sws_desc(:new.group_id), 'a');
  ELSIF :old.DELETED_P = 'f' AND NOT (:new.DELETED_P = 'f') THEN
    delete from site_wide_index
    where table_name = 'im_partners' and
          the_key = :old.group_id;
  ELSIF :new.DELETED_P = 'f' THEN
    update site_wide_index
      set one_line_description = im_partners_sws_desc(:new.group_id),
          the_key = :new.group_id,
          datastore = 'a'
      where table_name = 'im_partners' and
            the_key = :old.group_id;
  END IF;
END;
/
show errors;

create or replace trigger im_partners_sws_delete_tr
  after delete on im_partners for each row
  WHEN (old.DELETED_P = 'f')
BEGIN
  delete from site_wide_index
  where table_name = 'im_partners' and the_key = :old.group_id;
END;
/
show errors;

create or replace procedure im_partners_sws_helper ( rid IN ROWID, tlob IN OUT nocopy clob, p_primary_key IN varchar, p_one_line_description IN varchar)
IS
  v_pages_row im_partners%ROWTYPE;  
BEGIN
  SELECT *
    INTO v_pages_row
    FROM im_partners
    WHERE group_id = p_primary_key;
  dbms_lob.writeappend(tlob, length('<oneline>'), '<oneline>');      
  dbms_lob.writeappend(tlob, length(p_one_line_description), p_one_line_description);
  dbms_lob.writeappend(tlob, length('</oneline>'), '</oneline>');      
  IF (v_pages_row.URL IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.URL) + 1, v_pages_row.URL || ' ');
  END IF;
  IF (v_pages_row.NOTE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.NOTE) + 1, v_pages_row.NOTE || ' ');
  END IF;
  IF (v_pages_row.REFERRAL_SOURCE IS NOT NULL) THEN
    dbms_lob.writeappend(tlob, length(v_pages_row.REFERRAL_SOURCE) + 1, v_pages_row.REFERRAL_SOURCE || ' ');
  END IF;
END;
/
show errors;


-----------------------------

CREATE OR replace procedure sws_user_datastore_proc ( rid IN ROWID, tlob IN OUT nocopy clob )
IS
   v_table_name  VARCHAR(30);
   v_primary_key VARCHAR(700);
   v_one_line VARCHAR(4000);

BEGIN
     -- get various info on table and columns to index
   SELECT table_name, the_key, one_line_description
     INTO v_table_name, v_primary_key, v_one_line
     FROM site_wide_index
     WHERE rid = site_wide_index.ROWID;
   
   -- clean out the clob we're going to stuff
   dbms_lob.trim(tlob, 0);
   
   -- handle different sections
   IF v_table_name = 'bboard' THEN
      bboard_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'static_pages' THEN
      static_pages_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'comments' THEN
      comments_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'im_facilities' THEN
      im_facilities_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'im_customers' THEN
      im_customers_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'im_offices' THEN
      im_offices_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'im_projects' THEN
      im_projects_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'im_partners' THEN
      im_partners_sws_helper(rid, tlob, v_primary_key, v_one_line);
   ELSIF v_table_name = 'wp_slides' THEN
      wp_slides_sws_helper(rid, tlob, v_primary_key, v_one_line);
   END IF;
END;
/
show errors;


--------------------------------------------------------------------------------

connect ctxsys/&3

CREATE OR replace procedure sws_user_proc_&1 ( rid IN ROWID, tlob IN OUT nocopy clob )
AS
BEGIN
   &1..sws_user_datastore_proc(rid, tlob);
END;
/
show errors;

grant execute on sws_user_proc_&1 to &1;

grant ctxapp to &1;

-- stuff to make interMedia faster
exec ctx_adm.set_parameter('max_index_memory', '1G');

--------------------------------------------------------------------------------
 
connect &1/&2


-- Table to support query by example. Session specific
-- so we don't have to keep using new query_id's, as long
-- as we clean up after each use.
create global temporary table sws_result_table (
	query_id	number,
	theme		varchar(2000),
	weight		number
) on commit preserve rows;


-- create section groups for within clauses
begin
  ctx_ddl.create_section_group('swsgroup', 'basic_section_group');
  ctx_ddl.add_field_section('swsgroup', 'oneline', 'oneline', TRUE);
end;
/  

-- create intermedia index for site wide index
begin
  ctx_ddl.create_preference('sws_user_datastore', 'user_datastore');
  ctx_ddl.set_attribute('sws_user_datastore', 'procedure', 'sws_user_proc_&1');
end;
/

create index sws_ctx_index on site_wide_index (datastore)
indextype is ctxsys.context parameters ('datastore sws_user_datastore memory 250M section group swsgroup');


-- file-storage indexing, can't use sws_user_datastore since it's only clobs
-- NOTE: the inso_filter is only available on Solaris, HP-UX, AIX and NT.
--       uncomment the below if you have it. 
-- create index sws_ctx_index_b on fs_versions (version_content)
-- indextype is ctxsys.context parameters ('filter ctxsys.inso_filter memory 250M');
-- create an entry in sws_properties
-- insert into sws_properties (table_name, section_name, user_url_stub, admin_url_stub, user_defined_p, public_p)
-- values ('fs_versions', 'File storage', '/file-storage/one-file?file_id=/', '/file-storage/one-file?file_id=', 'f', 'f');


-- SQL to stuff the site wide index from scratch.
--
---------- bboard ----------
-- insert into site_wide_index (table_name, the_key, one_line_description, datastore, group_id, scope)
-- select 'bboard', bb.msg_id, nvl(bb.one_line, '(no subject)'), 'a', 
--        bt.group_id, decode(bt.read_access,'group','group','public')
--   from bboard bb, bboard_topics bt
--   WHERE refers_to IS NULL and
--         bb.topic_id=bt.topic_id;
--
---------- static_pages ---------- 
-- insert into site_wide_index (table_name, the_key, one_line_description, datastore)
-- select 'static_pages', page_id, nvl(page_title, '(no title)'), 'a'
-- from static_pages;
--
---------- comments ----------
-- INSERT INTO site_wide_index (table_name, the_key, one_line_description, datastore)
--   SELECT 'comments', comment_id, subject_for_comment(page_id), 'a'
--     FROM comments
--     WHERE deleted_p = 'f'
--     AND comment_type = 'alternative_perspective';
--
---------- wp_slides ----------
-- INSERT INTO site_wide_index (table_name, the_key, one_line_description, datastore,scope,group_id,user_id)
--   select 'wp_slides',slide_id,wp.title,'a',ws_sws_scope_fn(public_p,group_id),group_id,creation_user
--     from wp_slides ws,wp_presentations wp
--     where ws.presentation_id=wp.presentation_id;
--
---------- im_facilities ----------
-- insert into site_wide_index (table_name, the_key, one_line_description, datastore)
--   select 'im_facilities', facility_id, facility_name, 'a'
--     from im_facilities;
--
---------- im_customers ----------
--  declare
--    cursor v_cursor is
--      select *
--      from im_customers;
--    v_cursor_val v_cursor%ROWTYPE;
--  BEGIN
--    open v_cursor;
--    LOOP
--      fetch v_cursor into v_cursor_val;
--      exit when v_cursor%NOTFOUND;
--      IF v_cursor_val.DELETED_P = 'f' THEN
--        insert into site_wide_index
--        (table_name, the_key, one_line_description, datastore)
--         values
--        ('im_customers', v_cursor_val.group_id, im_customers_sws_desc(v_cursor_val.group_id), 'a');
--      END IF;
--    END LOOP;
--  END;
--  /
--
---------- im_offices ----------
--  declare
--    cursor v_cursor is
--      select *
--      from im_offices;
--    v_cursor_val v_cursor%ROWTYPE;
--  BEGIN
--    open v_cursor;
--    LOOP
--     fetch v_cursor into v_cursor_val;
--      exit when v_cursor%NOTFOUND;
--    IF v_cursor_val.PUBLIC_P = 't' THEN
--      insert into site_wide_index
--      (table_name, the_key, one_line_description, datastore)
--       values
--      ('im_offices', v_cursor_val.group_id, im_offices_sws_desc(v_cursor_val.group_id), 'a');
--    END IF;
--    END LOOP;
--  END;
--  /
--
---------- im_projects ----------
--  declare
--    cursor v_cursor is
--      select *
--      from im_projects;
--    v_cursor_val v_cursor%ROWTYPE;
--  BEGIN
--    open v_cursor;
--    LOOP
--      fetch v_cursor into v_cursor_val;
--      exit when v_cursor%NOTFOUND;    
--      insert into site_wide_index
--      (table_name, the_key, one_line_description, datastore)
--       values
--      ('im_projects', v_cursor_val.group_id, im_projects_sws_desc(v_cursor_val.group_id), 'a');
--    END LOOP;
--  END;
--  /
--
---------- im_partners ----------
--  declare
--    cursor v_cursor is
--      select *
--      from im_partners;
--    v_cursor_val v_cursor%ROWTYPE;
--  BEGIN
--    open v_cursor;
--    LOOP
--      fetch v_cursor into v_cursor_val;
--      exit when v_cursor%NOTFOUND;
--      IF v_cursor_val.DELETED_P = 'f' THEN
--        insert into site_wide_index
--        (table_name, the_key, one_line_description, datastore)
--         values
--        ('im_partners', v_cursor_val.group_id, im_partners_sws_desc(v_cursor_val.group_id), 'a');
--      END IF;
--    END LOOP;
--  END;
--  /
--
--
--
--


-- Query to take free text user entered query and frob it into something
-- that will make interMedia happy. Provided by Oracle.
create or replace function im_convert(
	query in varchar2 default null
	) return varchar2
is
  i   number :=0;
  len number :=0;
  char varchar2(1);
  minusString varchar2(256);
  plusString varchar2(256); 
  mainString varchar2(256);
  mainAboutString varchar2(500);
  finalString varchar2(500);
  hasMain number :=0;
  hasPlus number :=0;
  hasMinus number :=0;
  token varchar2(256);
  tokenStart number :=1;
  tokenFinish number :=0;
  inPhrase number :=0;
  inPlus number :=0;
  inWord number :=0;
  inMinus number :=0;
  completePhrase number :=0;
  completeWord number :=0;
  code number :=0;  
begin
  
  len := length(query);

-- we iterate over the string to find special web operators
  for i in 1..len loop
    char := substr(query,i,1);
    if(char = '"') then
      if(inPhrase = 0) then
        inPhrase := 1;
	tokenStart := i;
      else
        inPhrase := 0;
        completePhrase := 1;
	tokenFinish := i-1;
      end if;
    elsif(char = ' ') then
      if(inPhrase = 0) then
        completeWord := 1;
        tokenFinish := i-1;
      end if;
    elsif(char = '+') then
      inPlus := 1;
      tokenStart := i+1;
    elsif((char = '-') and (i = tokenStart)) then
      inMinus :=1;
      tokenStart := i+1;
    end if;

    if(completeWord=1) then
      token := '{ '||substr(query,tokenStart,tokenFinish-tokenStart+1)||' }';      
      if(inPlus=1) then
        plusString := plusString||','||token||'*10';
	hasPlus :=1;	
      elsif(inMinus=1) then
        minusString := minusString||'OR '||token||' ';
	hasMinus :=1;
      else
        mainString := mainString||' NEAR '||token;
	mainAboutString := mainAboutString||' '||token; 
	hasMain :=1;
      end if;
      tokenStart  :=i+1;
      tokenFinish :=0;
      inPlus := 0;
      inMinus :=0;
    end if;
    completePhrase := 0;
    completeWord :=0;
  end loop;

  -- find the last token
  token := '{ '||substr(query,tokenStart,len-tokenStart+1)||' }';
  if(inPlus=1) then
    plusString := plusString||','||token||'*10';
    hasPlus :=1;	
  elsif(inMinus=1) then
    minusString := minusString||'OR '||token||' ';
    hasMinus :=1;
  else
    mainString := mainString||' NEAR '||token;
    mainAboutString := mainAboutString||' '||token; 
    hasMain :=1;
  end if;

  
  mainString := substr(mainString,6,length(mainString)-5);
  mainAboutString := replace(mainAboutString,'{',' ');
  mainAboutString := replace(mainAboutString,'}',' ');
  mainAboutString := replace(mainAboutString,')',' ');	
  mainAboutString := replace(mainAboutString,'(',' ');
  plusString := substr(plusString,2,length(plusString)-1);
  minusString := substr(minusString,4,length(minusString)-4);

  -- we find the components present and then process them based on the specific combinations
  code := hasMain*4+hasPlus*2+hasMinus;
  if(code = 7) then
    finalString := '('||plusString||','||mainString||'*2.0,about('||mainAboutString||')*0.5) NOT ('||minusString||')';
  elsif (code = 6) then  
    finalString := plusString||','||mainString||'*2.0'||',about('||mainAboutString||')*0.5';
  elsif (code = 5) then  
    finalString := '('||mainString||',about('||mainAboutString||')) NOT ('||minusString||')';
  elsif (code = 4) then  
    finalString := mainString;
    finalString := replace(finalString,'*1,',NULL); 
    finalString := '('||finalString||')*2.0,about('||mainAboutString||')';
  elsif (code = 3) then  
    finalString := '('||plusString||') NOT ('||minusString||')';
  elsif (code = 2) then  
    finalString := plusString;
  elsif (code = 1) then  
    -- not is a binary operator for intermedia text
    finalString := 'totallyImpossibleString'||' NOT ('||minusString||')';
  elsif (code = 0) then  
    finalString := '';
  end if;

  return finalString;
end;
/
