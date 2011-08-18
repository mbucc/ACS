--
-- Table definitions for stolen equipment registry
--

--
-- Copyright 1996 Philip Greenspun (philg@mit.edu)
--

-- updated December 7, 1997 for Oracle

create sequence stolen_registry_sequence start with 5000;

create table stolen_registry (
	stolen_id		integer not null primary key,
	user_id			integer references users,
	additional_contact_info	varchar(400),
	manufacturer		varchar(50),	-- e.g., 'Nikon'
	model			varchar(100),	-- e.g., 'N90s'
	serial_number		varchar(100),
	value			numeric(9,2),
	recovered_p		char(1) default 'f' check(recovered_p in ('f','t')),
	recovered_by_this_service_p	char(1) default 'f' check(recovered_by_this_service_p in ('f','t')),
	posted			date,
	story			varchar(3000),	-- optional, free text
	deleted_p		char(1) default 'f' check(deleted_p in ('f','t'))
);

CREATE VIEW stolen_registry_for_context (stolen_id, deleted_p, recovered_p, manufacturer, model, serial_number, indexedtext)
AS 
SELECT stolen_id, s.deleted_p, recovered_p, manufacturer, model, serial_number, serial_number || ' ' || u.first_names || ' ' || u.last_name || ' ' || u.email || ' ' || manufacturer || ' ' || model || ' ' || story 
FROM stolen_registry s, users u
WHERE u.user_id = s.user_id;
