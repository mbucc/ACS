--
-- glassroom.sql 
--
-- Created January 4, 1999 by Philip Greenspun (philg@mit.edu)
--
-- Supports the ArsDigita Glass Room collaboration system for 
-- people involved in keeping a Web service up and running
-- (probably also useful for other IT-type activities)
--

create sequence glassroom_host_id_sequence;

create table glassroom_hosts (
	host_id		integer primary key,
	-- fully qualified hostname; the main name of the host
	hostname	varchar(100),
	-- e.g., 18.23.0.16 (or some reasonable human-readable IPv6 format)
	ip_address	varchar(50),	
	-- e.g., 'HP-UX 11.0'
	os_version	varchar(50),
	description	varchar(4000),
	model_and_serial	varchar(4000),
	street_address		varchar(4000),
	-- how to get to the console port
	remote_console_instructions	varchar(4000),
	service_phone_number	varchar(100),
	service_contract	varchar(4000),
	-- e.g., the above.net NOC
	facility_phone		varchar(100),
	facility_contact	varchar(4000),
	backup_strategy		varchar(4000),
	rdbms_backup_strategy	varchar(4000),
	further_docs_url	varchar(200)
);

create sequence glassroom_cert_id_sequence;

create table glassroom_certificates (
	cert_id		integer primary key,
	hostname	varchar(100),
	-- typically this will be "Versign"
	issuer		varchar(100),
	-- a cert usually contains an encoded email request
	encoded_email	varchar(2000),
	-- when does this expire (this is important!)
	expires		date
);

create sequence glassroom_module_id_sequence;
create sequence glassroom_release_id_sequence;

-- we keep track of the significant software modules that make up
-- this service, including some of the people who own it.  However,
-- we also expect that there will be a user_group of people associated
-- with many modules

create table glassroom_modules (
	module_id	integer primary key,
	module_name	varchar(100),
	-- URL, vendor phone number, whatever is necessary to get a new copy
	source		varchar(4000),	
	-- what we're running in production
	current_version		varchar(50),
	who_installed_it	references users(user_id),
	who_owns_it		references users(user_id)
);

create table glassroom_releases (
	release_id	integer primary key,
	module_id	not null references glassroom_modules,
	release_date			date,
	anticipated_release_date	date,
	release_name	varchar(50),	-- e.g., '3.2'
	manager		references users(user_id)
);

create table glassroom_procedures (
	procedure_name		varchar(50) primary key,
	procedure_description	varchar(4000),
	responsible_user	references users(user_id),
	responsible_user_group	references user_groups(group_id),
	max_time_interval	number,
	importance		integer check(importance >= 1 and importance <= 10)
);

create sequence glassroom_logbook_entry_id_seq;

create table glassroom_logbook (
	entry_id	integer primary key,
	entry_time	date not null,
	entry_author	not null references users(user_id),
	procedure_name	varchar(100) not null, 
	notes		varchar(4000)
);

create table glassroom_domains (
	domain_name	varchar(50),	-- e.g., 'photo.net'
	last_paid	date,
	by_whom_paid	varchar(100),
	expires		date
);

-- this is kind of lame in that this table will probably
-- only have one row

create table glassroom_services (
	service_name		varchar(50) primary key,
	web_service_host	references glassroom_hosts,
	rdbms_host		references glassroom_hosts,
	dns_primary_host	references glassroom_hosts,
	dns_secondary_host	references glassroom_hosts,
	disaster_host		references glassroom_hosts
);
