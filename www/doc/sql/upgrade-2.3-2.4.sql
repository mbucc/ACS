--
-- upgrade-2.3-2.4.sql
--
-- by philg@mit.edu on October 29, 1999
--

alter table users_contact add (
	fax		varchar(100),
	priv_fax	integer
);

alter table categories add (
	category_description    varchar(4000)
);

create table category_hierarchy (
   parent_category_id     integer references categories,
   child_category_id      integer references categories,
   unique (parent_category_id, child_category_id)
);



-- migrate the parent-child relationships from the parent_category_id column of the
-- categories table to the category_hierarchy table
--
-- we want a record in category_hierarchy even for those categories whose
-- parent_category_id is null
--

declare
 cursor cats is
  select *
  from categories;
begin
 for cat in cats loop
  insert into category_hierarchy(child_category_id, parent_category_id)
  values(cat.category_id, cat.parent_category_id);
 end loop;
end;
/

alter table categories drop column parent_category_id;


-- this one will replace sws_table_to_section_map
-- and general_comments_table_map
create table table_acs_properties (
             table_name      varchar(30) primary key,
             section_name    varchar(100) not null,
             user_url_stub   varchar(200) not null,
             admin_url_stub  varchar(200) not null
);

-- copy 
insert into table_acs_properties
(table_name, section_name, user_url_stub, admin_url_stub)
select table_name, section_name, user_url_stub, admin_url_stub
from general_comments_table_map;

-- you'll want to do these manually when you're satifisfied
-- that everything is running
-- drop table static_categories;
-- drop table sws_table_to_section_map;
-- drop table general_comments_table_map;

create sequence site_wide_cat_map_id_seq;

-- this table can represent "item X is related to category Y" for any
-- item in the ACS; see /doc/user-profiling.html for examples

create table site_wide_category_map (
             map_id                  integer primary key,
	     category_id             not null references categories,
	     -- We are mapping a category in the categories table
	     -- to another row in the database.  Which table contains
	     -- the row?
             on_which_table          varchar(30) not null,
	     -- What is the primary key of the item we are mapping to?
	     -- With the bboard this is a varchar so we can't make this
	     -- and integer
             on_what_id              varchar(500) not null,
	     mapping_date	     date not null,
	     -- how strong is this relationship?
	     -- (we can even map anti-relationships with negative numbers)
	     mapping_weight          integer default 5 
				     check(mapping_weight between -10 and 10),
	     -- A short description of the item we are mapping
	     -- this enables us to avoid joining with every table
	     -- in the ACS when looking for the most relevant content 
	     -- to a users' interests
	     -- (maintain one_line_item_desc with triggers.)
             one_line_item_desc      varchar(200) not null,
	     mapping_comment         varchar(200),
	     -- only map a category to an item once
             unique(category_id, on_which_table, on_what_id)
);


--- stuff to fix up site-wide search 

alter table static_pages add (
	index_p		char(1) default 't' check (index_p in ('t','f')),
	index_decision_made_by	varchar(30) default 'robot' check(index_decision_made_by in ('human', 'robot'))
);

create sequence static_page_index_excl_seq;

create table static_page_index_exclusion (
	exclusion_pattern_id	integer primary key,
	match_field		varchar(30) default 'url_stub' not null check(match_field in ('url_stub', 'page_title', 'page_body')),
	like_or_regexp		varchar(30) default 'like' not null check(like_or_regexp in ('like', 'regexp')),
	pattern			varchar(4000) not null,
	pattern_comment		varchar(4000),
	creation_user		not null references users,
	creation_date		date default sysdate not null 
);
