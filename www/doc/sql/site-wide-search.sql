--
-- site-wide-search.sql 
--
-- part of the ArsDigita Community System
-- created by philg@mit.edu on March 13, 1999
--
-- modified by branimir@arsdigita.com 2000-02-02
-- and lars@arsdigita.com March 14, 2000

-- user datastore procedure for site wide index

-- Note: execute this script by calling load-site-wide-search
-- Expects three arguments: username password password-for-ctxsys

-- Read /doc/site-wide-search.html and upgrade your InterMedia 
-- to 8.1.5.1 or 8.1.6.


connect &1/&2

create table site_wide_index (
	table_name	     	varchar(30) not null,
	the_key		     	varchar(700) not null,
	one_line_description 	varchar(4000) not null,
	datastore		char(1) not null, -- place holder for datastore column
	primary key (table_name, the_key)
);

connect ctxsys/&3

CREATE OR replace procedure sws_user_datastore_proc ( rid IN ROWID, tlob IN OUT nocopy clob )
IS
   v_table_name  VARCHAR(30);
   v_primary_key VARCHAR(700);
   v_one_line VARCHAR(700);
   v_static_pages_row &1..static_pages%ROWTYPE;
   TYPE comment_rec IS RECORD (
     message clob,
     author_name VARCHAR(300));
   v_comment_row comment_rec;
   cursor bboard_cursor(v_msg_id CHAR) IS
     SELECT one_line, message, u.first_names || ' ' || u.last_name AS author_name
       FROM &1..bboard b, &1..users u
       WHERE b.sort_key LIKE v_msg_id || '%'
       AND b.user_id = u.user_id;
       
BEGIN
     -- get various info on table and columns to index
   SELECT table_name, the_key, one_line_description
     INTO v_table_name, v_primary_key, v_one_line
     FROM &1..site_wide_index
     WHERE rid = site_wide_index.ROWID;
   
   -- clean out the clob we're going to stuff
   dbms_lob.trim(tlob, 0);
   
   -- handle different sections
   IF v_table_name = 'bboard' THEN

      -- Get data from every message in the thread.
      FOR bboard_record IN bboard_cursor(v_primary_key) LOOP
	 IF bboard_record.one_line IS NOT NULL THEN
	    dbms_lob.writeappend(tlob, length(bboard_record.one_line) + 1, bboard_record.one_line || ' ');
	 END IF;
	 dbms_lob.writeappend(tlob, length(bboard_record.author_name) + 1, bboard_record.author_name || ' ');
         IF bboard_record.message IS NOT NULL THEN
	     dbms_lob.append(tlob, bboard_record.message);
	 END IF;
      -- (branimir 2000-02-02 02:02:02) : Add a space so that the last word of this message doesn't get
      -- glued together with the first word of the next message:
      dbms_lob.writeappend(tlob, 1, ' ');
      END LOOP;
   ELSIF v_table_name = 'static_pages' THEN
      SELECT * INTO v_static_pages_row
	FROM &1..static_pages
	WHERE page_id = v_primary_key;
      
      IF v_static_pages_row.page_title IS NOT NULL THEN
	 dbms_lob.writeappend(tlob, length(v_static_pages_row.page_title) + 1, v_static_pages_row.page_title || ' ');
      END IF;
      dbms_lob.append(tlob, v_static_pages_row.PAGE_BODY);
   ELSIF v_table_name = 'comments' THEN
      SELECT message, u.first_names || ' ' || u.last_name INTO v_comment_row
	FROM &1..comments c, &1..users u
	WHERE c.user_id = u.user_id
	AND c.comment_id = v_primary_key;
      dbms_lob.writeappend(tlob, length(v_comment_row.author_name) + 1, v_comment_row.author_name || ' ');
      dbms_lob.append(tlob, v_comment_row.message);
   END IF;
END;
/
show errors

grant execute on sws_user_datastore_proc to &1;

grant ctxapp to &1;

-- stuff to make interMedia faster
exec ctx_adm.set_parameter('max_index_memory', '1G');

 
connect &1/&2

-- BBoard indexing

insert into table_acs_properties (table_name, section_name, user_url_stub, admin_url_stub)
values ('bboard', 'Discussion Forums', '/bboard/redirect-for-sws.tcl?msg_id=', '/bboard/admin-q-and-a-fetch-msg.tcl');


create or replace trigger bboard_sws_insert_tr
  after insert on bboard for each row
BEGIN
  -- Only create new site wide index row if this is the start of
  -- a new thread.
  IF :NEW.refers_to IS NULL THEN
     insert into site_wide_index (table_name, the_key, one_line_description, datastore)
       values ('bboard', :new.msg_id, :new.one_line, 'a');
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
  
  
-- static pages indexing
insert into table_acs_properties (table_name, section_name, user_url_stub, admin_url_stub)
values ('static_pages', 'Static Pages', '/search/static-page-redirect.tcl?page_id=', '/admin/static/page-summary.tcl?page_id=');

create or replace trigger static_pages_sws_insert_tr
  after insert on static_pages for each row
  WHEN (NEW.index_p = 't')
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
  IF :old.index_p = 'f' AND :NEW.index_p = 't' THEN
     insert into site_wide_index (table_name, the_key, one_line_description, datastore)
       values ('static_pages', :new.page_id, :new.page_title, 'a');
  ELSIF :old.index_p = 't' AND :NEW.index_p = 'f' THEN
     DELETE FROM site_wide_index
       WHERE table_name = 'static_pages'
       AND the_key = :old.page_id;
  ELSIF :NEW.index_p = 't' THEN
     update site_wide_index 
       set the_key = :new.page_id, one_line_description = nvl(:new.page_title, '(no title)'), datastore = 'a'
       where table_name = 'static_pages'
       and the_key = :old.page_id;
  END IF;
end;
/
show errors
  
  
CREATE OR replace trigger static_pages_sws_delete_tr
  after DELETE ON static_pages FOR each row
  WHEN (old.index_p = 't')
BEGIN
  DELETE FROM site_wide_index
    WHERE table_name = 'static_pages'
    AND the_key = :old.page_id;
END;
/
show errors


-- indexing for user comments
insert into table_acs_properties (table_name, section_name, user_url_stub, admin_url_stub)
  values ('comments', 'User Comments', '/comments/one.tcl?comment_id=', '/admin/comments/persistent-edit.tcl?comment_id=');

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
  after insert on comments for each row
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
  
-- Table to support query by example. Session specific
-- so we don't have to keep using new query_id's, as long
-- as we clean up after each use.
create global temporary table sws_result_table (
	query_id	number,
	theme		varchar(2000),
	weight		number
) on commit preserve rows;


-- create intermedia index for site wide index
begin
  ctx_ddl.create_preference('sws_user_datastore', 'user_datastore');
  ctx_ddl.set_attribute('sws_user_datastore', 'procedure', 'sws_user_datastore_proc');
end;
/

create index sws_ctx_index on site_wide_index (datastore)
indextype is ctxsys.context parameters ('datastore sws_user_datastore memory 250M');


-- SQL to stuff the site wide index from scratch.
-- insert into site_wide_index (table_name, the_key, one_line_description, datastore)
-- select 'bboard', msg_id, nvl(one_line, '(no subject)'), 'a'
--   from bboard
--   WHERE refers_to IS NULL;
-- 
-- insert into site_wide_index (table_name, the_key, one_line_description, datastore)
-- select 'static_pages', page_id, nvl(page_title, '(no title)'), 'a'
-- from static_pages;

-- INSERT INTO site_wide_index (table_name, the_key, one_line_description, datastore)
--   SELECT 'comments', comment_id, subject_for_comment(page_id), 'a'
--     FROM comments
--     WHERE deleted_p = 'f'
--     AND comment_type = 'alternative_perspective';



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
