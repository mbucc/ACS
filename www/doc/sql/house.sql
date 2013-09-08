
create table im_house_info (
       facility_id	   integer 
			   constraint im_house_info_office_id_pk primary key 
			   constraint ihi_office_id_fk references im_facilities,
       serves_office_id	   integer 
			   constraint ihi_serves_office_id_fk references im_offices,
       approval_needed_p   char(1) default 'f'
			   constraint ihi_approval_needed_p_ch check(approval_needed_p in ('t', 'f')),
       available_from	   date,
       available_to	   date,
       public_p		   char(1) default 't' 
			   constraint ihi_public_p_ch check(public_p in ('t', 'f')),
       admin_group_id	   integer 
			   constraint ihi_admin_group_id_fk references user_groups
);

-- Rooms in Company Houses
create sequence im_house_rooms_seq start with 1;
create table im_house_rooms (
       room_id		    integer 
                            constraint ihr_room_id_pk primary key,
       name		    varchar(200) 
                             constraint ihr_name_nn not null,
        -- which house is this room in
        house_id            integer
                            constraint ihr_house_id_nn not null
                            constraint ihr_house_id_fk references im_house_info,
        phone               varchar(50),
        -- do reservations in this room need the approval of the house's poc?
        -- note we can require approval on a per room basis (for the presidential 
        -- suite) or for an entire company house (like the Chatham house)
        approval_needed_p   char(1) default 'f'
			    constraint ihr_apprvl_needed_p_ck check(approval_needed_p in ('t', 'f')),
        -- is this room deleted?
        deleted_p	    char(1) default 'f' 
			    constraint ihr_rooms_deleted_p_ck check(deleted_p in ('f', 't')),
        note                varchar(4000),
        constraint ihr_rm_name_house_id_uq
        unique(name, house_id)
);

-- Amenities
-- This includes items such as tv, washer/dryer, kitchen, microwave, toaster,
--      parking, stereo, private bath, etc. that may be associated with 
-- a room or with the house as a whole.
create sequence im_house_amenities_seq start with 1;
create table im_house_amenities (
        amenity_id          integer 
                            constraint iha_amenity_id_pk primary key,
        name                varchar(100)
                            constraint iha_name_nn not null
                            constraint iha_name_un unique,
        description         varchar(4000)
);



-- Match up Houses/Rooms with amenities
create table im_house_amenity_map (
        house_id            integer
                            constraint iham_house_id_fk references im_house_info,
        amenity_id          integer
                            constraint iham_amenity_id_fk references im_house_amenities,
        constraint im_house_amenity_pk 
        primary key(house_id, amenity_id)
);


create table im_house_room_amenity_map (
        room_id             integer
                            constraint iram_room_id_fk references im_house_rooms,
        amenity_id          integer
                            constraint iram_amenity_id_fk references im_house_amenities,
        constraint im_house_room_amenity_pk 
        primary key(room_id, amenity_id)
);


-- Beds
create sequence im_house_beds_seq start with 1;
create table im_house_beds (
        bed_id              integer
                            constraint im_house_beds_pk primary key,
   -- allow admin to specify a name by which bed can
        -- be referred.  If null, use bed_id.  We will not
        -- make this unique or anything....
       bed_name             varchar(20) not null,
        -- which room is this bed in
       room_id              integer
                            constraint im_house_beds_room_id_nn not null
                            constraint im_house_beds_room_id_fk references im_house_rooms,
       bed_size             varchar(20)
                            constraint ihb_bed_size_ck
                             check(bed_size in ('twin', 'double', 'queen', 'king')),
       bed_style            varchar(20),
                            constraint ihb_beds_bed_style_ck
                              check(bed_style in ('futon', 'western')),
       deleted_p            char(1) default 'f'
			    constraint ihb_deleted_p_ck check(deleted_p in ('f','t'))
);



-- Reservations
create sequence im_house_reservations_seq start with 1;
create table im_house_reservations (
        reservation_id     integer
                           constraint im_house_reservations_pk primary key,
        -- who made the reservation
        reservers_id       integer
                           constraint ihr_reservers_id_fk references users(user_id)
                           constraint ihr_reservers_id_nn  not null,
        -- who is sleeping in the bed
        -- if null, guest does not have an ACS account
        guest_id           integer
                           constraint ihr_guest_id_fk references users(user_id),
        -- may need to know their sex so that we don't
        -- end up having a male and female (unwillingly) share the room
        guest_sex          char(1)
                           constraint ihr_guest_sex_ck check(guest_sex in ('m', 'f'))
                           constraint ihr_guest_sex_nn not null,
	guest_email	   varchar(400),
        bed_id             integer
                           constraint ihr_bed_id_fk references im_house_beds
                           constraint ihr_bed_id_nn not null,
        -- allow one-click approval, but guard against URL surgery
        -- to approve one's own request
        secret_key         integer,
        -- the day of arrival (that evening is first night in bed)
        start_date         date
                           constraint ihr_start_date_nn not null,
        -- the last day bed is needed (i.e. previous night was last night in bed)
        end_date           date
                           constraint ihr_end_date_nn not null,
        approval_user      integer
                           constraint ihr_approved_by_fk references users(user_id),
        approval_date      date,
        one_line           varchar(80),
	reason		   varchar(100) 
			   constraint ihr_reason_ck
			     check(reason in ('boot-camp', 'office-visit', 'training', 'other')),
        constraint ihr_start_end_ck check(end_date > start_date)
);

create or replace function im_house_n_beds_in_room (v_room_id in integer)
return integer
as
        n_beds  integer;
begin
        select count(*) into n_beds
        from im_house_beds
        where room_id = v_room_id;

        return n_beds;
end im_house_n_beds_in_room;
/
show errors;


create or replace function im_house_time_conflict_p (v_bed_id in integer,
        v_start_date in date, v_end_date in date)
return char
as
        the_count       integer;
        the_result      char(1);
begin
        select count(*) into the_count from im_house_reservations
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
end im_house_time_conflict_p;
/
show errors;


create or replace function im_house_opposite_sex (v_sex in char)
return char
as
begin
        if (lower(v_sex) = 'm') then
                return 'f';
        else
                return 'm';
        end if;
end im_house_opposite_sex;
/
show errors;





create or replace function im_house_sex_conflict_p (v_bed_id in integer,
        v_sex char, v_start_date date, v_end_date date)
return char
as
        the_count       integer;
        the_room_id     integer;
        the_result      char(1);
begin
        select room_id into the_room_id from im_house_beds
                where bed_id = v_bed_id;
        select im_house_n_beds_in_room(the_room_id) into the_count from dual;
        if (the_count = 1) then
                the_result := 'f';
        else
                select count(*) into the_count
                from im_house_reservations
                where im_house_time_conflict_p(bed_id, v_start_date, v_end_date) = 't'
                        and lower(guest_sex) = im_house_opposite_sex(v_sex)
         and bed_id in (select bed_id from im_house_beds
                         where room_id = the_room_id
                           and bed_id <> v_bed_id);
                if (the_count > 0) then
                        the_result := 't';
                else
                        the_result := 'f';
                end if;
        end if;
        return the_result;
end im_house_sex_conflict_p;
/
show errors;


