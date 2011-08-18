--
-- email-handler.sql
--
-- by hqm@arsdigita.com June 1999
--
-- for queueing up email that arrives to robots 
-- 

create sequence incoming_email_queue_sequence start with 1;

-- CONTENT contains the entire raw message content
-- including all headers

create table incoming_email_queue (
	id 		integer primary key,
	destaddr	varchar(256),
	content		clob,
	arrival_time	date
    );


