--
-- /www/doc/sql/db-logging.sql
--
-- Contains a PL/SQL procedure (ad_db_log) that provides a simple
-- way to write out logging info from within PL/SQL, without
-- having to use the DBMS_OUTPUT package (which is only useful
-- in SQL*Plus anyway). It is based on AOLserver's ns_log API
--
-- Author: michael@arsdigita.com, 2000-02-17
--
-- db-logging.sql,v 3.1 2000/03/11 09:26:37 michael Exp
--

create table ad_db_log_messages (
	severity	varchar(7) not null check (severity in 
			 ('notice', 'warning', 'error', 'fatal',
			  'bug', 'debug')),
	message		varchar(4000) not null,
	creation_date	date default sysdate not null
);

create or replace procedure ad_db_log (
 v_severity in ad_db_log_messages.severity%TYPE,
 v_message in ad_db_log_messages.message%TYPE
)
as
pragma autonomous_transaction;
begin
 insert into ad_db_log_messages(severity, message)
 values(v_severity, v_message);

 commit;
end ad_db_log;
/
show errors
