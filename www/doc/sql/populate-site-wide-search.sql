--
-- populate-site-wide-search.sql
--
-- by phong@arsdigit.com
--
-- SQL to stuff the site wide index from scratch.
--


---------- bboard ----------
insert into site_wide_index (table_name, the_key, one_line_description, datastore, group_id, scope)
  select 'bboard', bb.msg_id, nvl(bb.one_line, '(no subject)'), 'a', bt.group_id, decode(bt.read_access,'group','group','public')
  from bboard bb, bboard_topics bt
  WHERE bb.refers_to IS NULL and bb.topic_id=bt.topic_id;

---------- static_pages ---------- 
insert into site_wide_index (table_name, the_key, one_line_description, datastore, scope, group_id, user_id)
  select 'static_pages', page_id, nvl(page_title, '(no title)'), 'a', scope, group_id, original_author
  from static_pages;

---------- comments ----------
INSERT INTO site_wide_index (table_name, the_key, one_line_description, datastore)
  SELECT 'comments', comment_id, subject_for_comment(page_id), 'a'
  FROM comments
  WHERE deleted_p = 'f' AND comment_type = 'alternative_perspective';

---------- wp_slides ----------
INSERT INTO site_wide_index (table_name, the_key, one_line_description, datastore,scope,group_id,user_id)
  select 'wp_slides', ws.slide_id, wp.title, 'a', wp_slides_sws_scope_fn(wp.public_p, wp.group_id), wp.group_id, wp.creation_user
  from wp_slides ws, wp_presentations wp
  where ws.presentation_id=wp.presentation_id;

---------- im_facilities ----------
insert into site_wide_index (table_name, the_key, one_line_description, datastore)
  select 'im_facilities', facility_id, facility_name, 'a'
  from im_facilities;

---------- im_customers ----------
declare
  cursor v_cursor is
    select *
    from im_customers; 
  v_cursor_val v_cursor%ROWTYPE;
BEGIN
  open v_cursor;
  LOOP
    fetch v_cursor into v_cursor_val;
    exit when v_cursor%NOTFOUND;
    IF v_cursor_val.DELETED_P = 'f' THEN
      insert into site_wide_index
      (table_name, the_key, one_line_description, datastore)
       values
      ('im_customers', v_cursor_val.group_id, im_customers_sws_desc(v_cursor_val.group_id), 'a');
    END IF;
  END LOOP;
END;
/

---------- im_offices ----------
declare
  cursor v_cursor is
    select *
    from im_offices;
  v_cursor_val v_cursor%ROWTYPE;
BEGIN
  open v_cursor;
  LOOP
   fetch v_cursor into v_cursor_val;
    exit when v_cursor%NOTFOUND;
  IF v_cursor_val.PUBLIC_P = 't' THEN
    insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
     values
    ('im_offices', v_cursor_val.group_id, im_offices_sws_desc(v_cursor_val.group_id), 'a');
  END IF;
  END LOOP;
END;
/

---------- im_projects ----------
declare
  cursor v_cursor is
    select *
    from im_projects;
  v_cursor_val v_cursor%ROWTYPE;
BEGIN
  open v_cursor;
  LOOP
    fetch v_cursor into v_cursor_val;
    exit when v_cursor%NOTFOUND;    
    insert into site_wide_index
    (table_name, the_key, one_line_description, datastore)
     values
    ('im_projects', v_cursor_val.group_id, im_projects_sws_desc(v_cursor_val.group_id), 'a');
  END LOOP;
END;
/

---------- im_partners ----------
declare
  cursor v_cursor is
    select *
    from im_partners;
  v_cursor_val v_cursor%ROWTYPE;
BEGIN
  open v_cursor;
  LOOP
    fetch v_cursor into v_cursor_val;
    exit when v_cursor%NOTFOUND;
    IF v_cursor_val.DELETED_P = 'f' THEN
      insert into site_wide_index
      (table_name, the_key, one_line_description, datastore)
       values
      ('im_partners', v_cursor_val.group_id, im_partners_sws_desc(v_cursor_val.group_id), 'a');
    END IF;
  END LOOP;
END;
/

