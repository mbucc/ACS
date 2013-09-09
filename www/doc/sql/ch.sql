-- /www/doc/sql/ch.sql
--
-- A module to keep track of "company houses" and allow
-- employees to reserve beds in them.
--
-- created by mburke@arsdigita.com on 2000-04-12
-- ch.sql,v 3.3 2000/05/17 17:35:19 luke Exp



-- Company Houses
create sequence ch_houses_seq start with 1;
create table ch_houses (
	house_id						integer 
									constraint ch_house_id_pk
									primary key,
	-- which office is the house associated with
	office_id					integer 
									constraint ch_group_id_nn
									not null
									constraint ch_group_id_fk 
									references im_offices(group_id),
	name							varchar(200) 
									constraint ch_name_nn
									not null,
	phone							varchar(50),
	fax							varchar(50),
	address_line1				varchar(80),
	address_line2				varchar(80),
	address_city				varchar(80),
	address_state				varchar(80),
	address_postal_code		varchar(80),
	address_country_code		char(2) 
									constraint ch_address_country_code_fk
									references country_codes(iso),
	contact_person_id			integer 
									constraint ch_contact_person_fk 
									references users,
	landlord						varchar(4000),
	-- who supplies the security service, code for the door, etc.
	security						varchar(4000),
	note							varchar(4000),
	-- must reservations for this house be approved by the contact person?
	approval_needed_p			char(1) default 'f'
									constraint ch_approval_needed_p_ck
									check(approval_needed_p in ('t', 'f')),
	-- Note: we may not necessarily own a house forever, e.g. this summer
	-- we've got 19 beds in a house from mid-May to mid-August.
	-- what's the earliest we can start booking the house?
	available_from				date,
	-- when do we kick everyone out and turn over the keys?
	available_to				date,
	-- is the info about this house public?
	public_p						char(1) default 'f'
									constraint ch_public_p_ck 
									check(public_p in ('f', 't'))
);



-- Rooms in Company Houses
create sequence ch_rooms_seq start with 1;
create table ch_rooms (
	room_id						integer 
									constraint cr_room_id_pk
									primary key,
	name							varchar(200) 
									constraint cr_name_nn
									not null,
	-- which house is this room in
	house_id						integer
									constraint cr_house_id_nn
									not null
									constraint cr_house_id_fk
									references ch_houses,
	phone							varchar(50),
	-- do reservations in this room need the approval of the house's poc?
	-- note we can require approval on a per room basis (for the presidential 
	-- suite) or for an entire company house (like the Chatham house)
	approval_needed_p			char(1) default 'f'
									constraint cr_apprvl_needed_p_ck
									check(approval_needed_p in ('t', 'f')),
	-- is this room available?
	--available_pchar(1) default 't'
	--constraint ch_rooms_available_p_ck
	--check(available_p in ('f', 't'))
	note							varchar(4000),
	constraint cr_rm_name_house_id_uq
	unique(name, house_id)
);





-- Amenities
-- This includes items such as tv, washer/dryer, kitchen, microwave, toaster,
--	parking, stereo, private bath, etc. that may be associated with 
-- a room or with the house as a whole.
create sequence ch_amenities_seq start with 1;
create table ch_amenities (
	amenity_id				integer 
								constraint ca_amenity_id_pk
								primary key,
	name						varchar(100)
								constraint ca_name_nn
								not null
								constraint ca_name_un
								unique,
	description				varchar(4000),
	amenity_type			varchar(20)
								constraint ca_amenity_type_ck
								check(amenity_type in ('room', 'house'))
);



-- Match up Houses/Rooms with amenities
create table ch_house_amenity_map (
	house_id						integer
									constraint cham_house_id_fk
									references ch_houses,
	amenity_id					integer
									constraint cham_amenity_id_fk
									references ch_amenities,
	constraint cham_house_amenity_pk 
	primary key(house_id, amenity_id)
);


create table ch_room_amenity_map (
	room_id						integer
									constraint cram_room_id_fk
									references ch_rooms,
	amenity_id					integer
									constraint cram_amenity_id_fk
									references ch_amenities,
	constraint cham_room_amenity_pk 
	primary key(room_id, amenity_id)
);






-- Beds
create sequence ch_beds_seq start with 1;
create table ch_beds (
	bed_id				integer
							constraint ch_beds_id_pk
							primary key,
	-- which room is this bed in
	room_id				integer
							constraint ch_beds_room_id_nn
							not null
							constraint ch_beds_room_id_fk
							references ch_rooms,
	bed_size				varchar(20)
							constraint ch_beds_bed_size_ck
							check(bed_size in ('twin', 'double', 'queen', 'king')),
	bed_style			varchar(20),
							constraint ch_beds_bed_style_ck
							check(bed_style in ('futon', 'western')),
   deleted_p         char(1) default 'f'
                     constraint ch_beds_deleted_p_ck
                     check(deleted_p in ('f','t'))
);







-- Reservations
create sequence ch_reservations_seq start with 1;
create table ch_reservations (
	reservation_id					integer
										constraint creserv_reservation_id_pk
										primary key,
	-- who made the reservation
	reservers_id					integer
										constraint creserv_reservers_id_fk
										references users(user_id)
										constraint creserv_reservers_id_nn
										not null,
	-- who is sleeping in the bed
	-- if null, guest does not have an ACS account
	guest_id							integer
										constraint creserver_guest_id_fk
										references users(user_id),
	-- may need to know their sex so that we don't
	-- end up having a male and female (unwillingly) share the room
	guest_sex						char(1)
										constraint creserv_guest_sex_ck
										check(guest_sex in ('m', 'f'))
										constraint creserv_guest_sex_nn
										not null,
	bed_id							integer
										constraint creserv_bed_id_fk
										references ch_beds
										constraint creserv_bed_id_nn
										not null,
	-- allow one-click approval, but guard against URL surgery
	-- to approve one's own request
	secret_key						integer,
	-- the day of arrival (that evening is first night in bed)
	start_date						date
										constraint creserv_start_date_nn
										not null,
	-- the last day bed is needed (i.e. previous night was last night in bed)
	end_date							date
										constraint creserv_end_date_nn
										not null,
	needs_approval_p				char(1) default 'f'
										constraint creserv_needs_approval_p_ck
										check(needs_approval_p in ('f', 't')),
	approval_user					integer
										constraint creserv_approved_by_fk
										references users(user_id),
	approval_date					date,
	one_line							varchar(80),
	constraint creserv_start_end_ck check(end_date > start_date)
);










create or replace function ch_n_beds_in_room (v_room_id in integer)
return integer
as
	n_beds	integer;
begin
	select count(*) into n_beds
	from ch_beds
	where room_id = v_room_id;

	return n_beds;
end ch_n_beds_in_room;
/
show errors;


create or replace function ch_time_conflict_p (v_bed_id in integer,
	v_start_date in date, v_end_date in date)
return char
as
	the_count	integer;
	the_result	char(1);
begin
	select count(*) into the_count from ch_reservations
	where bed_id = v_bed_id and
	( (v_start_date >= start_date and v_start_date < end_date)
	or
	  (start_date >= v_start_date and start_date < v_end_date) );
	if (the_count > 0) then
		the_result := 't';
	else
		the_result := 'f';
	end if;
	return the_result;
end ch_time_conflict_p;
/
show errors;


create or replace function ch_opposite_sex (v_sex in char)
return char
as
begin
	if (lower(v_sex) = 'm') then
		return 'f';
	else
		return 'm';
	end if;
end ch_opposite_sex;
/
show errors;



create or replace function garbage_ch_sex_conflict_p (v_bed_id in integer,
	v_sex char, v_start_date date, v_end_date date)
return char
as
	the_count	integer;
	the_room_id	integer;
	the_result	char(1);
begin
	select room_id into the_room_id from ch_beds
		where bed_id = v_bed_id;
	select ch_n_beds_in_room(the_room_id) into the_count from dual;
	if (the_count = 1) then
		the_result := 'f';
	else
		select count(*) into the_count
		from ch_reservations fres, ch_beds fb, ch_rooms fr
		where fres.bed_id <> v_bed_id
			and fres.bed_id = fb.bed_id and fb.room_id = fr.room_id
			and fr.room_id = the_room_id
			and ch_n_beds_in_room(fr.room_id) > 1
			and ch_time_conflict_p(fres.bed_id, v_start_date, v_end_date) = 't'
			and lower(fres.guest_sex) = ch_opposite_sex(v_sex);
		if (the_count > 0) then
			the_result := 't';
		else
			the_result := 'f';
		end if;
	end if;
	return the_result;
end garbage_ch_sex_conflict_p;
/
show errors;



create or replace function ch_sex_conflict_p (v_bed_id in integer,
	v_sex char, v_start_date date, v_end_date date)
return char
as
	the_count	integer;
	the_room_id	integer;
	the_result	char(1);
begin
	select room_id into the_room_id from ch_beds
		where bed_id = v_bed_id;
	select ch_n_beds_in_room(the_room_id) into the_count from dual;
	if (the_count = 1) then
		the_result := 'f';
	else
		select count(*) into the_count
		from ch_reservations
		where ch_time_conflict_p(bed_id, v_start_date, v_end_date) = 't'
			and lower(guest_sex) = ch_opposite_sex(v_sex)
         and bed_id in (select bed_id from ch_beds
                         where room_id = the_room_id
                           and bed_id <> v_bed_id);
		if (the_count > 0) then
			the_result := 't';
		else
			the_result := 'f';
		end if;
	end if;
	return the_result;
end ch_sex_conflict_p;
/
show errors;




-- configure houses/rooms to have general comments?

-- Local Variables: --
-- tab-width: 3 --
-- End: --
