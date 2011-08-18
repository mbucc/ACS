--
-- photodb.sql 
-- 
-- jkoontz@arsdigita.com
--

--
-- data model for photo management service
-- written by Group 4, 6.916, 3/4/99
-- edited Oct, 1999

-- create an administration group for photo database administration

begin
   administration_group_add ('Photo Database Staff', 'photodb', NULL, 'f', '/photodb/admin/');
end;
/

create sequence ph_folder_type_id_sequence start with 1 increment by 1;

create table ph_folder_types (
	folder_type_id	integer not null primary key,
	folder_type	varchar(50)
);

insert into ph_folder_types (folder_type_id, folder_type) values (
	ph_folder_type_id_sequence.nextval,'Roll');
insert into ph_folder_types (folder_type_id, folder_type) values (
	ph_folder_type_id_sequence.nextval,'PhotoCD');
insert into ph_folder_types (folder_type_id, folder_type) values (
	ph_folder_type_id_sequence.nextval,'Folder');

create sequence ph_folder_id_sequence start with 1 increment by 1;

create table ph_folders (
	folder_id	integer not null primary key,
	user_id		integer not null references users,
	title		varchar(50),
	photo_cd_id	integer,
	folder_type_id	integer not null references ph_folder_types
);

create index ph_folders_by_user_id_idx on ph_folders(user_id);

-- The following table is for user preferences

create table ph_user_preferences (
	user_id			integer not null references users(user_id),
	images_public_p		char(1) check (images_public_p in ('t','f')),
	photos_sort_by		varchar(100),
	default_image_size	char(1) check (default_image_size in ('s','m','l')),
	prefer_text_p		char(1) check (prefer_text_p in ('t','f'))
);

create index ph_user_prefs_by_user_idx on ph_user_preferences(user_id);

create sequence ph_camera_model_id_sequence start with 1 increment by 1;

create table ph_camera_models (
	camera_model_id		integer not null primary key,
	manufacturer		varchar(50),	-- e.g., 'Nikon'
	model			varchar(50),	-- e.g., '8008/F801'
	variation		varchar(50),	-- e.g., 'titanium'
	last_modified_date 	date,
	last_modifying_user	references users,
	modified_ip_address	varchar2(20)
);

-- to facilitate captioning photos with tech info, we keep track of which
-- cameras each photographer owns (if they want to give us this info)

create sequence ph_camera_id_sequence start with 1 increment by 1;

create table ph_cameras (
	camera_id		integer not null primary key,
	user_id			integer not null references users,
	camera_model_id		integer references ph_camera_models,
	pretty_name		varchar(50),	-- e.g., "EOS-5 with date back"
	serial_number		varchar(50),
	date_purchased		date,
	creation_date		date,	
	-- the numbers below are just up until
	-- date_surveyed; they are not kept up to date automagically
	-- as users enter rolls
	n_failures		integer,
	n_rolls_exposed		integer,	-- "n sheets" for a view camera
	purchased_new_p		char(1) check (purchased_new_p in ('t', 'f'))
);

create index ph_cameras_by_user_idx on ph_cameras(user_id);
create index ph_cameras_by_model_idx on ph_cameras(camera_model_id);

-- we go to all this trouble because we want to be able to ask "Show
-- me all the Tri-X photos"

create sequence ph_film_type_id_sequence start with 1 increment by 1;

create table ph_film_types (
	film_type_id 	integer not null primary key,
	film_type	varchar(20)	-- e.g., e6, k14, c41-bw, bw
);

insert into ph_film_types (film_type_id, film_type) values (ph_film_type_id_sequence.nextval, 'Digital');

insert into ph_film_types (film_type_id, film_type) values (ph_film_type_id_sequence.nextval, 'Black/White');

insert into ph_film_types (film_type_id, film_type) values (ph_film_type_id_sequence.nextval, 'C41 (Color Negative)');

insert into ph_film_types (film_type_id, film_type) values (ph_film_type_id_sequence.nextval, 'E6 (Color Slide)');

insert into ph_film_types (film_type_id, film_type) values (ph_film_type_id_sequence.nextval, 'K14 (Kodachrome)');

insert into ph_film_types (film_type_id, film_type) values (ph_film_type_id_sequence.nextval, 'Infrared');

create sequence ph_film_id_sequence start with 1 increment by 1;

create table ph_films (
	film_id		integer not null primary key,
	film_type_id	integer not null references ph_film_types,
	manufacturer	varchar(50),	-- e.g., Kodak, Fuji, Ilford
	full_name	varchar(50),	-- e.g., Ektachrome Professional Plus
	abbrev		varchar(10),	-- e.g., EPP, RDP, VPS
	last_modified_date 	date,
	last_modifying_user	references users,
	modified_ip_address	varchar2(20)
);

insert into ph_films (film_id, film_type_id, manufacturer, full_name, abbrev) 
	values
	(ph_film_id_sequence.nextval, 1, '(none)', 'Digital', 'Digital');

create index ph_films_by_type_idx on ph_films(film_type_id);

-- The following table is for custom fields tracking
-- It allows us to do smart searching on fields, figure out
-- which fields are active, and which are "deleted" (since
-- we can't REALLY delete fields from Oracle).
-- (Now that we are use 8i we can. 8/11/1999)

create sequence ph_custom_field_id_sequence start with 1 increment by 1;

create table ph_custom_photo_fields (
        custom_field_id         integer not null primary key,
        user_id                 integer not null references users(user_id),
        field_name              varchar(200),
        field_pretty_name       varchar(200),
        field_type              varchar(200),
        date_added              date,
        field_active_p          char(1) check (field_active_p in ('t','f')),
	field_comment		varchar2(4000)
);

create index ph_custom_fields_by_user_idx on ph_custom_photo_fields(user_id);
create index ph_custom_fields_by_active_idx on ph_custom_photo_fields(field_active_p);

-- A table ph_user_(user_id)_custom_info will be created to store custom photo
-- info.
-- It's columns include photo_id, data field's (being add on)

create sequence ph_photo_id_sequence start with 1 increment by 1;

create table ph_photos (
	photo_id	integer not null primary key,
	user_id		integer not null references users,
	folder_id	integer not null references ph_folders,
	-- Can this photo be seen in the community
	photo_public_p	char(1) check (photo_public_p in ('t','f')),
	camera_id	integer not null references ph_cameras,
	film_id		integer references ph_films,
	file_extension	varchar(10), -- eg .jpg .gif
	size_available_sm 	char(1) check (size_available_sm in ('t','f')),
	size_available_md	char(1) check (size_available_md in ('t','f')),
	size_available_lg	char(1) check (size_available_lg in ('t','f')),
	-- These are the sizes of the thumbnails. It allows the client
	-- to display the whole page even if the thumbnails are not yet loaded
	sm_width	integer,
	sm_height	integer,
	md_width	integer,
	md_height	integer,
	lg_width	integer,
	lg_height	integer,
	photo_cd_id	integer,
	orphan_key	varchar(50),
	exposure_date	date,
	caption		varchar(4000),
	tech_details	varchar(4000),	-- f-stop, shutter speed, film used
	-- If a recognizable person is in the photo, is the
	-- model_release info available
	model_release_p char(1) check (model_release_p in ('t','f')),
	-- rights grants -- we do this in six separate columns so that we can 
	-- use an Oracle bitmap index to make queries faster
	rights_personal_web_p	char(1) check (rights_personal_web_p in ('t','f')),
	rights_personal_print_p	char(1) check (rights_personal_print_p in ('t','f')),
	rights_nonprofit_web_p	char(1) check (rights_nonprofit_web_p in ('t','f')),
	rights_nonprofit_print_p	char(1) check (rights_nonprofit_print_p in ('t','f')),
	rights_comm_web_p	char(1) check (rights_comm_web_p in ('t','f')),
	rights_comm_print_p	char(1) check (rights_comm_print_p in ('t','f')),
 	-- copyright_statement is an HTML fragment,  if they want to 
	-- fundamentally refer people to their Web server, they can have
	-- a simple sentence with a hyperlink
	copyright_statement	varchar(4000),
	file_size		number,
	creation_date		date,
	publisher_favorite_p char(1) default 'f' check (publisher_favorite_p in ('t','f'))
);

create index ph_photos_by_user_idx on ph_photos(user_id);
create index ph_photos_by_folder_idx on ph_photos(folder_id);
create index ph_photos_by_public_p_idx on ph_photos(photo_public_p);
create index ph_photos_by_m_release_idx on ph_photos(model_release_p);
create index ph_photos_by_r_pers_web_idx on ph_photos(rights_personal_web_p);
create index ph_photos_by_r_pers_print_idx on ph_photos(rights_personal_print_p);
create index ph_photos_by_r_nonp_web_idx on ph_photos(rights_nonprofit_web_p);
create index ph_photos_by_r_nonp_print_idx on ph_photos(rights_nonprofit_print_p);
create index ph_photos_by_r_comm_web_idx on ph_photos(rights_comm_web_p);
create index ph_photos_by_r_comm_print_idx on ph_photos(rights_comm_print_p);


create sequence ph_presentation_id_sequence start with 1 increment by 1;

create table ph_presentations (
	presentation_id integer not null primary key,
	user_id		integer not null references users,
	title		varchar(200),
	public_p	char(1) check (public_p in ('t','f')),
        beginning_note  varchar(4000),
        ending_note     varchar(4000),
        use_html_code_p char(1) check (use_html_code_p in ('t','f')),
        html_code       clob,
	creation_date	date
);

create index ph_presentation_by_user_idx on ph_presentations(user_id);

create table ph_presentation_photo_map (
	presentation_id integer not null references ph_presentations,
	photo_id 	integer not null references ph_photos,
        annotation	varchar(4000),
        photo_order     integer
);

create index ph_prest_photo_by_present_idx on ph_presentation_photo_map(presentation_id);
create index ph_prest_photo_by_photo_idx on ph_presentation_photo_map(photo_id);

create table ph_presentation_user_map (
	presentation_id integer not null references ph_presentations,
	user_id		integer not null references users
);

create index ph_prest_user_by_present_idx on ph_presentation_user_map(presentation_id);
create index ph_prest_user_by_user_idx on ph_presentation_user_map(user_id);

-- Links to the General Comments module

insert into table_acs_properties
(table_name, section_name, user_url_stub, admin_url_stub)
select 'ph_photos', 'photodb photos', '/photodb/photo.tcl?photo_id=','/photodb/admin/photo.tcl?photo_id='
from dual 
where 0 = (select count(*) from table_acs_properties where table_name = 'ph_photos');

insert into table_acs_properties
(table_name, section_name, user_url_stub, admin_url_stub)
select 'ph_presentations', 'photodb presentations', '/photodb/presentation.tcl?presentation_id=','/photodb/admin/presentation.tcl?presentation_id='
from dual
where 0 = (select count(*) from table_acs_properties where table_name = 'ph_presentations');
