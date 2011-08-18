--
-- contact-manager.sql
--
-- defined by philg@mit.edu on March 31, 1999
--
-- a generic, albeit somewhat wimpy, contact manager 
--

-- we use "contact_" as a table prefix so as not to get confused
-- with any content management systems whose tables would be prefixed
-- "cm_"

-- create the user_group for the contact manager 

create sequence contact_event_id_sequence;

-- this table points into some other table in the system but we 
-- can't say which one in advance

create table contact_events (
	contact_event_id	integer primary key,
	other_table_key		varchar(700) not null,
	event_date		date not null,
	user_id			not null references users,
	contactee_name		varchar(200),
	contactee_email		varchar(100),
	note			varchar(4000)
);

-- we need a table for more structured info (acquired if the user 
-- presses particular buttons in the /contact-manager/ directory)

-- event_type could be 'not_worth_contacting' or 'success'

create table contact_structured_events (
	contact_event_id	integer primary key,
	other_table_key		varchar(700) not null,
	user_id			not null references users,
	event_date		date not null,
	event_type		varchar(100) not null
);

-- build an Intermedia index on this table using a USER_DATASTORE (PL/SQL proc
-- that will combine the contactee_name and _email with the note); this works
-- in Oracle 8.1.5 or newer -- **** it does not work in regular Oracle 8.0 ****

-- note that we don't put this into the site-wide index because it is so separate; 
-- if you were a sales person searching for a contact name, you wouldn't want to
-- wade through public content.  Nor would people searching public content ever
-- be sent here; this contact information simply isn't part of the site content!

-- **** this procedure must be owned by CTXSYS! *****

conn ctxsys/ctxsyspassword
create or replace procedure contact_events_index_proc 
( nextrow IN ROWID, nextclob IN OUT CLOB )
IS
  event_record    contact_events%ROWTYPE;
BEGIN
  select * into event_record from contact_events where rowid = nextrow;
  dbms_lob.writeappend(v_nextclob, length(event_record.contactee_name), event_record.contactee_name);
END contact_events_index_proc;
/
show errors 

-- **** then you have to make it excecutable by the regular Web server user! *****

conn realuser/realuserpassword
grant execute on contact_events_index_proc to realuser;
