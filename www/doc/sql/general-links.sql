--
-- /doc/sql/general-links.sql
--
-- by dh@arsdigita.com, <original creation date>
--
-- This is used in a similar way to general-comments to add links to a page.
-- In addition, users can view a "Hot Link" page of categorized links.

create sequence general_link_id_sequence start with 1;

create table general_links (
	link_id                 integer primary key,
	url                     varchar(300) not null,
	link_title              varchar(100) not null,
	link_description        varchar(4000),
	-- meta tags defined by HTML at the URL
	meta_description        varchar(4000),
	meta_keywords           varchar(4000),
	n_ratings               integer,
        avg_rating              number,
	-- when was this submitted?
	creation_time	    	    date default sysdate not null,
	creation_user		    not null references users(user_id),
	creation_ip_address	    varchar(20) not null,
	last_modified		    date,
	last_modifying_user	    references users(user_id),
	-- last time this got checked
	last_checked_date       date,
	last_live_date          date,
        last_approval_change               date,
	-- has the link been approved? ( note that this is different from
	-- the approved_p in the table wite_wide_link_map ) 
	approved_p              char(1) check(approved_p in ('t','f')),
	approval_change_by     references users
);

-- Index on searchable fields

create index general_links_title_idx on general_links (link_title);

create sequence general_link_map_id start with 1;

-- This table associates urls with any item in the database

create table site_wide_link_map (
	map_id          integer primary key,
	link_id                 not null references general_links,
	-- the table is this url associated with 
	on_which_table          varchar(30) not null,
	-- the row in *on_which_table* the url is associated with
	on_what_id              integer not null,
	-- a description of what the url is associated with
	one_line_item_desc      varchar(200) not null,
	-- who made the association
	creation_time	    	    date default sysdate not null,
	creation_user		    not null references users(user_id),
	creation_ip_address	    varchar(20) not null,
	last_modified		    date,
	last_modifying_user	    references users(user_id),
	-- has the link association  been approved ?
	approved_p              char(1) check(approved_p in ('t','f')),
	approval_change_by     references users
);

create index swlm_which_table_what_id_idx on site_wide_link_map (on_which_table, on_what_id);

-- We want users to be able to rate links
-- These ratings could be used in the display of the links
-- eg, ordering within category by rating, or displaying 
-- fav. links for people in a given group..

create table general_link_user_ratings (
	user_id         not null references users,
 	link_id         not null references general_links,
	-- a user may give a url a rating between 0 and 10
	rating          integer not null check(rating between 0 and 10 ),
	-- require that the user/url rating is unique
	primary key(link_id, user_id) 
);


insert into table_acs_properties (table_name, section_name, user_url_stub, admin_url_stub)
values ('general_links', 'General Links', '/general-links/view-one.tcl?link_id=', '/admin/general-links/edit-link.tcl?link_id=');

-- trigger for user ratings
create or replace trigger general_links_rating_update
after insert or update on general_link_user_ratings
declare
 cursor c1 is select gl.link_id, count(*) as n_ratings, avg(rating) as avg_rating from general_links gl, general_link_user_ratings glr where gl.link_id = glr.link_id group by gl.link_id;
begin
  for c_ref in c1 loop
   
   update general_links
   set n_ratings = c_ref.n_ratings,
   avg_rating = c_ref.avg_rating
   where link_id = c_ref.link_id;

  end loop;
end;
/
show errors
