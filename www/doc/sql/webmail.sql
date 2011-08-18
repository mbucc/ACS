-- webmail.sql
-- by Jin Choi <jsc@arsdigita.com>
-- Feb 28, 2000

-- Data model to support web based email system.

-- Database user must have javasyspriv permission granted to it:
-- connect system
-- grant javasyspriv to <username>;

-- ctxsys must grant EXECUTE on ctx_ddl to this Oracle user:
-- connect ctxsys
-- grant execute on ctx_ddl to <username>;

-- $Id: webmail.sql,v 1.5 2000/03/10 05:02:25 jsc Exp $


-- Domains we receive email for.
create table wm_domains (
	-- short text key
	short_name		varchar(100) not null primary key,
	-- fully qualified domain name
	full_domain_name	varchar(100) not null
);


-- Maps email accounts to ACS users.
create table wm_email_user_map (
	email_user_name	varchar(100) not null,
	domain		references wm_domains,
	user_id		not null references users,
	primary key (email_user_name, domain, user_id)
);

-- Main mail message table. Stores body of the email, along
-- with a parsed text version with markers for attachments for MIME
-- messages.
create sequence wm_msg_id_sequence;
create table wm_messages (
        msg_id          integer primary key,
        body            clob,
	-- plain text portions of MIME message; empty if 
	-- entire message is of type text/*.
	mime_text	clob,
        message_id      varchar(200), -- RFC822 Message-ID field
	unique_id	integer -- for both POP3 UIDL and IMAP UID
);

create index wm_messages_by_message_id on wm_messages(message_id);


-- Stores attachments for MIME messages.
create table wm_attachments (
	msg_id		not null references wm_messages,
	-- File name associated with attachment.
	filename	varchar(600) not null,
	-- MIME type of attachment.
	content_type	varchar(100),
	data		blob,
	format		varchar(10) check (format in ('binary', 'text')), -- for interMedia INSO filter
	primary key (msg_id, filename)
);


-- Maps mailboxes (folders, in more common terminology) to ACS users.
create sequence wm_mailbox_id_sequence;

create table wm_mailboxes (
	mailbox_id	integer primary key,
	name		varchar(100) not null,
	creation_user	references users(user_id),
	creation_date	date,
	uid_validity	integer, -- Needed for IMAP
	unique(creation_user, name)
);

-- Maps messages to mailboxes (and thus to users).
create table wm_message_user_map (
	mailbox_id	integer references wm_mailboxes,
	msg_id		integer references wm_messages,
	seen_p		char(1) default 'f' check(seen_p in ('t','f')),
	answered_p	char(1) default 'f' check(answered_p in ('t','f')),
	flagged_p	char(1) default 'f' check(flagged_p in ('t','f')),
	deleted_p	char(1) default 'f' check(deleted_p in ('t','f')),
	draft_p		char(1) default 'f' check(draft_p in ('t','f')),
	recent_p	char(1) default 't' check(recent_p in ('t','f')),
	primary key (msg_id, mailbox_id)
);


-- Parsed recipients for a message; enables search by recipient.
create table wm_recipients (
        msg_id          integer not null references wm_messages,
        header          varchar(100) not null, -- to, cc, etc.
        email           varchar(300) not null,
        name            varchar(200)
);

create index wm_recipients_by_msg_id on wm_recipients(msg_id);


-- Headers for a message.
create table wm_headers (
        msg_id          integer not null references wm_messages,
	-- field name as specified in the email
        name            varchar(100) not null,
	-- lowercase version for case insensitive searches
        lower_name      varchar(100) not null,
        value           varchar(4000),
        -- various parsed versions of the value
        time_value      date, -- date/time fields
        -- email and name, for singleton address fields like From
        email_value     varchar(300),
        name_value      varchar(200),
        -- original order of headers
        sort_order      integer not null
);

create index wm_headers_by_msg_id_name on wm_headers (msg_id, lower_name);


-- Table for recording messages that we failed to parse for whatever reason.
create table wm_parse_errors (
	filename		varchar(255) primary key not null, -- message queue file
	error_message		varchar(4000),
	first_parse_attempt	date default sysdate not null
);

-- Used for storing attachments for outgoing messages.
-- Should be cleaned out periodically.

create sequence wm_outgoing_msg_id_sequence;

create table wm_outgoing_messages (
	outgoing_msg_id		integer not null primary key,
	body			clob,
	composed_message	clob,
	creation_date		date default sysdate not null,
	creation_user		not null references users
);

create table wm_outgoing_headers (
	outgoing_msg_id		integer not null references wm_outgoing_messages on delete cascade,
	name			varchar(100) not null,
	value			varchar(4000),
	sort_order		integer not null
);

create unique index wm_outgoing_headers_idx on wm_outgoing_headers (outgoing_msg_id, name);


create sequence wm_outgoing_parts_sequence;
create table wm_outgoing_message_parts (
	outgoing_msg_id		integer not null references wm_outgoing_messages on delete cascade,
	data			blob,
	filename		varchar(600) not null,
	content_type		varchar(100), -- mime type of data
	sort_order		integer not null,
	primary key (outgoing_msg_id, sort_order)
);


-- Create a job to clean up orphaned outgoing messages every day.
create or replace procedure wm_cleanup_outgoing_msgs as
begin
  delete from wm_outgoing_messages
    where creation_date < sysdate - 1;
end;
/

declare
  job number;
begin
  dbms_job.submit(job, 'wm_cleanup_outgoing_msgs;',
		  interval => 'sysdate + 1');
end;
/

variable jobno number;
exec dbms_job.submit(:jobno, 'wm_cleanup_outgoing_msgs;', sysdate, 'sysdate + 1');

-- Sean's POP3 server stuff (currently unused).
create sequence wm_pop3_servers_seq;
create table wm_pop3_servers (
	server_id	integer primary key,
	user_id		references users,
	server_name	varchar(100) not null,
	port_number	integer default 110,
	user_name	varchar(200) not null,
	password	varchar(200) not null,
	last_uidl	varchar(200) default 'None',
	mailbox_size 	integer default 0,
	n_messages	integer default 0,
	delete_on_download_p	char(1) default 'f' check (delete_on_download_p in ('t', 'f')),
	delete_on_local_del_p	char(1) default 'f' check (delete_on_local_del_p in ('t', 'f'))
);


-- PL/SQL bindings for Java procedures
create or replace procedure wm_process_queue (queuedir IN VARCHAR)
as language java
name 'com.arsdigita.mail.MessageParser.processQueue(java.lang.String)';
/

-- useful for debugging
create or replace procedure wm_parse_message_from_file (filename IN VARCHAR)
as language java
name 'com.arsdigita.mail.MessageParser.parseMessageFromFile(java.lang.String)';
/

create or replace function wm_parse_date (datestr IN VARCHAR) return date
as language java
name 'com.arsdigita.mail.MessageParser.parseDate(java.lang.String)
return java.sql.Timestamp';
/

create or replace procedure wm_compose_message (outgoing_msg_id IN NUMBER)
as language java
name 'com.arsdigita.mail.MessageComposer.composeMimeMessage(int)';
/


-- Trigger to delete subsidiary rows when a message is deleted.
create or replace trigger wm_messages_delete_trigger
before delete on wm_messages
for each row
begin
  delete from wm_headers where msg_id = :old.msg_id;
  delete from wm_recipients where msg_id = :old.msg_id;
  delete from wm_message_user_map where msg_id = :old.msg_id;
  delete from wm_attachments where msg_id = :old.msg_id;
end;
/


-- Parse the queue every minute. Queue directory is hardcoded.
declare
  job number;
begin
  dbms_job.submit(job, 'wm_process_queue(''/home/nsadmin/qmail/queue/new'');',
		  interval => 'sysdate + 1/24/60');
end;
/


-- Utility function to determine email address for a response.
create or replace function wm_response_address (v_msg_id IN integer) return VARCHAR
as
  from_address varchar(4000);
  reply_to_address varchar(4000);
begin
  begin
    select value into reply_to_address
      from wm_headers
      where msg_id = v_msg_id
        and lower_name = 'reply-to';
    return reply_to_address;
  exception
    when no_data_found then 
      select value into from_address
        from wm_headers
        where msg_id = v_msg_id
          and lower_name = 'from';
      return from_address;
  end;
end;
/

-- interMedia index on body of message
create index wm_ctx_index on wm_messages (body)
indextype is ctxsys.context parameters ('memory 250M');

-- INSO filtered interMedia index for attachments.
create index wm_att_ctx_index on wm_attachments (data)
indextype is ctxsys.context parameters ('memory 250M filter ctxsys.inso_filter format column format');

-- Trigger to update format column for INSO index.
create or replace trigger wm_att_format_tr before insert on wm_attachments
for each row
declare
  content_type	varchar(100);
begin
  content_type := lower(:new.content_type);
  if content_type like 'text/%' or content_type like 'application/msword%' then
    :new.format := 'text';
  else
    :new.format := 'binary';
  end if;
end;
/

	

  


-- Resync the interMedia index every hour.

declare
  job number;
begin
  dbms_job.submit(job, 'ctx_ddl.sync_index(''wm_ctx_index'');',
		  interval => 'sysdate + 1/24');
  dbms_job.submit(job, 'ctx_ddl.sync_index(''wm_att_ctx_index'');',
		  interval => 'sysdate + 1/24');
end;
/
