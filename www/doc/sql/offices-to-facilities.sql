#
# offices-to-facilities.tcl
#
# moves columns that have been denormalized out of the im_offices table
# into the im_facilities table.
#


alter table im_facilities add temporary_group_id integer;

insert into im_facilities (
    facility_id,
    facility_name,
    phone,
    fax,
    address_line1,
    address_line2,
    address_city,
    address_state,
    address_postal_code,
    address_country_code,
    contact_person_id,
    landlord,
    security,
    note,
    temporary_group_id
) select
    im_facilities_seq.nextval,
    group_name,
    phone,
    fax,
    address_line1,
    address_line2,
    address_city,
    address_state,
    address_postal_code,
    address_country_code,
    contact_person_id,
    landlord,
    security,
    note,
    im_offices.group_id
from
    im_offices,
    user_groups
where
    user_groups.group_id = im_offices.group_id
;

alter table im_offices add facility_id integer constraint im_offices_facility_id_fk references im_facilities;

update im_offices set facility_id = (select facility_id from im_facilities where temporary_group_id = im_offices.group_id);

alter table im_facilities drop column temporary_group_id;

alter table im_offices modify facility_id constraint im_offices_facility_id_nn not null;


alter table im_offices drop column phone;
alter table im_offices drop column fax;
alter table im_offices drop column address_line1;
alter table im_offices drop column address_line2;
alter table im_offices drop column address_city;
alter table im_offices drop column address_state;
alter table im_offices drop column address_postal_code;
alter table im_offices drop column address_country_code;
alter table im_offices drop column landlord;
alter table im_offices drop column security;
alter table im_offices drop column note;








