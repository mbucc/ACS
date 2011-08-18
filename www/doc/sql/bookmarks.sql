-- bookmarks.sql
--
-- created June 1999 and modified July 1999
-- by aure@arsdigita.com and dh@arsdigita.com 

create sequence bm_url_id_seq;
-- since many people will be bookmarking the same sites, we keep urls in a separate table

create table bm_urls (
	url_id			integer primary key,
	-- url title may be null in the case of bookmarks that are merely icons ie. AIM
	url_title		varchar(500),
	-- host url is separated from complete_url for counting purposes
	host_url		varchar(100) not null,
	complete_url 		varchar(500) not null,
	-- meta tags that could be looked up regularly	
	meta_keywords 		varchar(4000),
	meta_description 	varchar(4000),
	last_checked_date 	date,
	-- the last time the site returned a "live" status
	last_live_date		date
);

create sequence bm_bookmark_id_seq;
-- this table contains both bookmarks and folders

create table bm_list (
	bookmark_id		integer primary key,
	-- sort keys contains 3 characters per level of depth, from
	-- 0-9, then A-Z, a-z. You can get the depth as length(parent_sort_key) / 3.
	-- the full sort key for any bookmark is parent_sort_key || local_sort_key
  	parent_sort_key		varchar(99), -- parent's sort key
	local_sort_key		char(3) not null,
	owner_id		integer not null references users(user_id),
	creation_date		date not null,
	modification_date	date,
	-- url_id may be null if the bookmark is a folder
	url_id			integer references bm_urls,
	-- a person may rename any of his bookmarks so we keep a local title
	local_title 			varchar(500),
	private_p 		char(1) default 'f' check (private_p in ('t','f')),
	-- needed in addition to private_p for the case where a public bookmark
	-- is under a hidden folder
	hidden_p		char(1) default 'f' check (hidden_p in ('t','f')),
	-- this is 't' if the bookmark is a folder
	folder_p 		char(1) default 'f' check (folder_p in ('t','f')),
	-- null parent_id indicates this is a top level folder/bookmark
	parent_id 		integer references bm_list(bookmark_id),
	-- refers to whether a folder is open or closed
	closed_p		char(1) default 't' check (closed_p in ('t','f')),
	-- whether the bookmark is within a closed folder and therefore not shown
	in_closed_p		char(1) default 'f' check (in_closed_p in ('t','f')) 
);


-- Procedures for keeping sort keys updated.

-- The big idea:

-- The current implementation borrows from Philip's idea for the bboard
-- of calculating sort keys at insertion time which encode hierarchy
-- information. A sort key has three characters per level of depth in the
-- hierarchy, with values from 0-9, A-Z, and a-z. All children of a given
-- folder have sort keys which begin with the folder's sort key. This
-- allows you to simply sort by the sort key and calculate the hierarchy
-- on the fly by looking at the length of the sort key.

-- For bookmarks, I've split up the sort key into parent_sort_key, which
-- is the full sort key of the parent, and the local sort key, which is
-- always exactly three characters. This reduces some parsing and makes
-- it a little easier to write code. A "full" sort key is the parent sort
-- key concatenated with the local sort key.


-- Increments old_char from 0-9, A-Z, a-z. Sets carry_p to 1 if incrementing
-- from z to 0.
CREATE OR REPLACE procedure inc_char_for_sort_key (old_char IN OUT CHAR, carry_p OUT INTEGER)
IS
   old_code INTEGER;
   new_code INTEGER;
BEGIN
   old_code := ascii(old_char);
   IF old_code = 57 THEN
      -- skip from 9 to A
      new_code := 65;
      carry_p := 0;
   ELSIF old_code = 90 THEN
      -- skip from Z to a
      new_code := 97;
      carry_p := 0;
   ELSIF old_code = 122 THEN
      -- wrap around
      new_code := 48;
      carry_p := 1;
   ELSE
      new_code := old_code + 1;
      carry_p := 0;
   END IF;
   old_char := chr(new_code);
END inc_char_for_sort_key;
/
show errors

-- Takes a local sort key and increments it by one.
CREATE OR replace FUNCTION new_sort_key (v_old_sort_key IN bm_list.local_sort_key%TYPE) RETURN bm_list.local_sort_key%TYPE
IS
   v_chr_1 char;
   v_chr_2 char;
   v_chr_3 char;
   v_carry INTEGER;
BEGIN
   IF v_old_sort_key IS null THEN
      RETURN '000';
   END IF;
   
   v_chr_1 := substr(v_old_sort_key, 1, 1);
   v_chr_2 := substr(v_old_sort_key, 2, 1);
   v_chr_3 := substr(v_old_sort_key, 3, 1);
   
   inc_char_for_sort_key(v_chr_3, v_carry);
   IF v_carry = 1 THEN
      inc_char_for_sort_key(v_chr_2, v_carry);
      IF v_carry = 1 THEN
	 inc_char_for_sort_key(v_chr_1, v_carry);
      END IF;
   END IF;
   
   RETURN v_chr_1 || v_chr_2 || v_chr_3;
END new_sort_key;
/
show errors;
  
-- Insert trigger which calculates local and parent sort keys.
CREATE OR replace trigger bm_list_sort_key_i_tr before INSERT ON bm_list
FOR each row
DECLARE
  v_last_sort_key bm_list.local_sort_key%TYPE;
  v_parent_sort_key bm_list.parent_sort_key%TYPE;
BEGIN
   IF :NEW.parent_id IS NULL THEN
      SELECT max(local_sort_key) INTO v_last_sort_key
	FROM bm_list
	WHERE parent_id IS NULL;
      v_parent_sort_key := null;
   ELSE
      SELECT max(local_sort_key) INTO v_last_sort_key
	FROM bm_list
	WHERE parent_id = :NEW.parent_id;
      SELECT parent_sort_key || local_sort_key INTO v_parent_sort_key
	FROM bm_list WHERE bookmark_id = :NEW.parent_id;
   END IF;
   
   :NEW.local_sort_key := new_sort_key(v_last_sort_key);
   :NEW.parent_sort_key := v_parent_sort_key;
END;
/
show errors


-- Standard hack for triggers which require selects on the mutating table.

-- Package to store IDs that have been changed.
create or replace package bm_list_pkg as
  type t_bookmark_ids is table of bm_list.bookmark_id%TYPE
    index BY binary_integer;
  v_updated_ids	t_bookmark_ids;
  v_num_entries binary_integer := 0;
END bm_list_pkg;
/
show errors

-- Row level update trigger to store updated IDs.
CREATE OR replace trigger bm_list_sort_key_row_u_tr 
  before UPDATE OF parent_id ON bm_list
  FOR each row
BEGIN
  bm_list_pkg.v_num_entries := bm_list_pkg.v_num_entries + 1;
  bm_list_pkg.v_updated_ids(bm_list_pkg.v_num_entries) := :NEW.bookmark_id;
END bm_list_sort_key_u_tr;
/
show errors


-- Fixes up parent_sort_key and local_sort_key for a bookmark.
-- If the bookmark was a folder, recursively updates its children.
CREATE OR replace PROCEDURE bm_fixup_sort_key(v_bookmark_id IN INTEGER)
IS
   v_row 		bm_list%ROWTYPE;
   v_last_sort_key 	bm_list.local_sort_key%TYPE;
   v_parent_sort_key 	bm_list.parent_sort_key%TYPE;
   cursor child_cursor(v_parent_id integer) IS
     SELECT bookmark_id FROM bm_list WHERE parent_id = v_parent_id;   
BEGIN
   SELECT * INTO v_row FROM bm_list WHERE bookmark_id = v_bookmark_id;
   IF v_row.parent_id IS NULL THEN
      -- Handle top-level changes
      SELECT max(local_sort_key) INTO v_last_sort_key
	FROM bm_list
	WHERE parent_id IS NULL;
      UPDATE bm_list SET parent_sort_key = NULL, local_sort_key = new_sort_key(v_last_sort_key) WHERE bookmark_id = v_bookmark_id;	 
   ELSE
      -- we're in a subfolder
      SELECT max(local_sort_key) INTO v_last_sort_key
	FROM bm_list
	WHERE parent_id = v_row.parent_id;
      SELECT parent_sort_key || local_sort_key INTO v_parent_sort_key FROM bm_list WHERE bookmark_id = v_row.parent_id;
      UPDATE bm_list SET parent_sort_key = v_parent_sort_key, local_sort_key = new_sort_key(v_last_sort_key) WHERE bookmark_id = v_bookmark_id;
   END IF;
   
   -- Recursively run on children if this is a folder.
   IF v_row.folder_p = 't' THEN
      FOR child_row IN child_cursor(v_bookmark_id) LOOP
	 bm_fixup_sort_key(child_row.bookmark_id);
      END LOOP;
   END IF;
END bm_fixup_sort_key;
/
show errors

-- Statement level after update trigger to fixup sort keys.
CREATE OR replace trigger bm_list_after_u_tr
  after UPDATE OF parent_id ON bm_list
DECLARE
  v_bookmark_id		bm_list.bookmark_id%TYPE;
  v_row 		bm_list%ROWTYPE;
  v_last_sort_key 	bm_list.local_sort_key%TYPE;
  v_parent_sort_key 	bm_list.parent_sort_key%TYPE;
  v_count               INTEGER;
BEGIN
   FOR v_loop_index IN 1 .. bm_list_pkg.v_num_entries LOOP
      -- Fix up local_sort_key and parent_sort_key.
      v_bookmark_id := bm_list_pkg.v_updated_ids(v_loop_index);
      bm_fixup_sort_key(v_bookmark_id);
   END LOOP;
   bm_list_pkg.v_num_entries := 0;
END bm_list_after_u_tr;
/
show errors 
  

-- need two indices to support CONNECT BY 

create index bm_list_idx1 on bm_list(bookmark_id, parent_id);
create index bm_list_idx2 on bm_list(parent_id, bookmark_id);
