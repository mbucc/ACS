--
-- Table definitions for stolen equipment registry
--

--
-- Copyright 1996 Philip Greenspun (philg@mit.edu)
--

-- updated December 7, 1997 for Oracle

create sequence stolen_registry_sequence start with 300;

create table stolen_registry (
	stolen_id		integer not null primary key,
	name			varchar(100),
	email			varchar(100),
	password		varchar(30),	-- in case user wants to edit
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

create view stolen_registry_upper as
select upper(manufacturer) as manufacturer from stolen_registry;

create view stolen_registry_for_context (stolen_id, deleted_p, recovered_p, manufacturer, model, serial_number, indexedtext)
as 
select stolen_id, deleted_p, recovered_p, manufacturer, model, serial_number, serial_number || ' ' || name || ' ' || email || ' ' || manufacturer || ' ' || model || ' ' || story from stolen_registry;

begin
   ctx_ddl.create_policy (
   policy_name => 'p_stolen_registry',
   colspec => 'stolen_registry_for_context.indexedtext' ,
   textkey => 'stolen_registry_for_context.stolen_id' );
end;
/

execute ctx_ddl.create_index('p_stolen_registry');


-- in the good old Illustra days
--create index stolen_registry_pls_index on stolen_registry using pls
--( serial_number, name, email, manufacturer, model, story );

