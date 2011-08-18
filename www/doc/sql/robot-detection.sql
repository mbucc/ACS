--
-- robot-detection.sql
--
-- created by michael@yoon.org on 05/27/1999
--
-- defines a table in which to store info from the Web Robots Database
-- (http://info.webcrawler.com/mak/projects/robots/active.html), which
-- is virtually a one-to-one mapping of the schema at:
--
-- http://info.webcrawler.com/mak/projects/robots/active/schema.txt
--
-- descriptions of each field can be found there.
--
create table robots (
	--
	-- robot_id is *not* a generated key.
	--
	robot_id			varchar(100) primary key,
	robot_name			varchar(100) not null,
	robot_details_url		varchar(200),
	robot_cover_url			varchar(200),
	robot_status			char(12),
	-- check (robot_status in ('development', 'active', 'retired'))
	robot_purpose			varchar(50),
	robot_type			char(12),
	-- check (robot_type in ('standalone', 'browser', 'plugin'))
	robot_platform			varchar(50),
	robot_availability		char(10),
	-- check (robot_availability in ('source', 'binary', 'data', 'none')),
	robot_exclusion_p		char(1),
	-- check (robot_exclusion_p in ('t', 'f')),
	robot_exclusion_useragent	varchar(100),
	robot_noindex_p			char(1),
	-- check (robot_exclusion_p in ('t', 'f')),
	robot_host			varchar(100),
	robot_from_p			char(1),
	-- check (robot_exclusion_p in ('t', 'f')),
	robot_useragent			varchar(100) not null,
	robot_language			varchar(100),
	robot_description		varchar(1000),
	robot_history			varchar(1000),
	robot_environment		varchar(1000),
	--
	-- note: modified_date and modified_by are *not* ACS audit trail
	-- columns; rather, they are part of the schema defined by the
	-- Web Robots DB.
	modified_date			date,
	modified_by			varchar(50),
	--
	-- insertion_date records when this row was actually inserted
	-- used to determine if we need to re-populate the table from
	-- the Web Robots DB.
	insertion_date			date default sysdate not null
);

create or replace trigger robots_modified_date
before insert or update on robots
for each row
when (new.modified_date is null)
begin
 :new.modified_date := SYSDATE;
end;
/
show errors


--
-- A robot can have multiple owners, so we normalize out the owner info.
--
create table robot_owners (
	robot_id		varchar(100) references robots(robot_id),
	robot_owner_name	varchar(50),
	robot_owner_url		varchar(200),
	robot_owner_email	varchar(100),
	primary key (robot_id, robot_owner_name)
);
