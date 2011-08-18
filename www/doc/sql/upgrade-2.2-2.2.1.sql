-- upgrade from ACS 2.2 to 2.2.1

alter table user_group_type_fields add (sort_key integer);
create sequence sort_key_sequence;
update user_group_type_fields set sort_key = sort_key_sequence.nextval;
drop sequence sort_key_sequence;

-- This table records additional fields to be recorded per user who belongs
-- to a group of a particular type.
create table user_group_type_member_fields (
	group_type	varchar(20) references user_group_types,
	field_name	varchar(200) not null,
	field_type	varchar(20) not null, -- short_text, long_text, boolean, date, etc.
	-- Sort key for display of columns.
	sort_key		integer not null,
	primary key (group_type, field_name)
);

-- Contains information about fields to gather per user for a user group.
-- Cannot contain a field_name that appears in the
-- user_group_type_member_fields table for the group type this group belongs to.

create table user_group_member_fields (
	group_id	integer references user_groups,
	field_name	varchar(200) not null,
	field_type	varchar(20) not null, -- short_text, long_text, boolean, date, etc.
	sort_key	integer not null,
	primary key (group_id, field_name)
);

-- View that brings together all field information for a user group, from
-- user_group_type_member_fields and user_group_member_fields.
-- We throw in the sort keys prepended by 'a' or 'b' so we can display
-- them in the correct order, with the group type fields first.
create or replace view all_member_fields_for_group as
select group_id, field_name, field_type, 'a' || sort_key as sort_key
from user_group_type_member_fields ugtmf, user_groups ug
where ugtmf.group_type = ug.group_type
union
select group_id, field_name, field_type, 'b' || sort_key as sort_key
from user_group_member_fields;


-- Contains extra field information for a particular user. These fields
-- were defined either in user_group_type_member_fields or 
-- user_group_member_fields
create table user_group_member_field_map (
	group_id	integer references user_groups,
	user_id		integer references users,
	field_name	varchar(200) not null,
	field_value	varchar(4000),
	primary key (group_id, user_id, field_name)
);

