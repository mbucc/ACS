--
-- spam.sql
--
-- created January 9, 1999 by Philip Greenspun (philg@mit.edu)
-- modified by Tracy Adams on Sept 22, 1999 (teadams@mit.edu)
-- modified by Henry Minsky (hqm@ai.mit.edu)
--
--
-- a system for spamming classes of users and keeping track of 
-- what the publisher said

-- use this to prevent double spamming if user hits submit twice 

create sequence spam_id_sequence;

create table spam_history (
	spam_id			integer primary key,
	from_address		varchar(100),
	pathname		varchar(700),
	title			varchar(200),
	template_p		char(1) default 'f' check (template_p in ('t','f')),
	-- message body text in multiple formats
	-- text/plain, text/aol-html, text/html
 	body_plain		clob,
 	body_aol		clob,
 	body_html		clob,
	-- query which over users_spammable.* to enumerate the recipients of this spam
	user_class_query	varchar(4000),
	creation_date		date not null,
	-- to which users did we send this?
	user_class_description	varchar(4000),
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
	send_date		date,
	-- we'll increment this after every successful email
	n_sent			integer default 0,
	-- values: unsent, sending, sent, cancelled
	status			varchar(16),
	-- keep track of the last user_id we sent a copy of this spam to
	-- so we can resume after a server restart
	last_user_id_sent	integer references users,
	begin_send_time		date,
	finish_send_time	date
);

-- table for administrator to set up daily spam file locations
create table daily_spam_files (
	file_prefix 		varchar(400),
	subject			varchar(2000),
	target_user_class_id	integer,
	user_class_description	varchar(4000),
	from_address		varchar(200),
	template_p		char(1) default 'f' check (template_p in ('t','f')),
	period			varchar(64) default 'daily' check (period in ('daily','weekly', 'monthly', 'yearly'))
);


-- pl/sql proc to guess email type

create table default_email_types  (
 pattern 	varchar(200),
 mail_type 	varchar(64)
);

-- Here are some default values. Overriden by server startup routine in /tcl/spam-daemon.tcl
insert into default_email_types (pattern, mail_type) values ('%hotmail.com',  'text/html');
insert into default_email_types (pattern, mail_type) values ('%aol.com',      'text/aol-html');
insert into default_email_types (pattern, mail_type) values ('%netscape.net', 'text/html');

-- function to guess an email type, using the default_email_types patterns table
CREATE OR REPLACE FUNCTION guess_user_email_type (v_email varchar)
RETURN varchar
IS
cursor mail_cursor is select * from default_email_types;
BEGIN
  FOR mail_val IN mail_cursor LOOP
    IF upper(v_email) LIKE upper(mail_val.pattern)  THEN
	    RETURN mail_val.mail_type;
    END IF;
  END LOOP;
-- default 
  RETURN 'text/html';
END guess_user_email_type;
/
show errors

-- Trigger on INSERT into users which guesses users preferred email type
-- based on their email address
CREATE OR REPLACE TRIGGER guess_email_pref_tr 
AFTER INSERT ON users
FOR each row
BEGIN
  UPDATE users_preferences set email_type = guess_user_email_type(:new.email) where user_id = :new.user_id;
  IF SQL%NOTFOUND THEN
   INSERT INTO users_preferences (user_id, email_type) VALUES (:new.user_id, guess_user_email_type(:new.email));
  END IF;
END;
/
show errors


-- loop over all users, lookup users_prefs.email_type.
-- if email_type is null, set it to default guess based on email addr.
CREATE OR REPLACE PROCEDURE init_email_types 
IS
   CURSOR c1 IS
      SELECT up.user_id as prefs_user_id, users.email, users.user_id from users, users_preferences up
	WHERE users.user_id = up.user_id(+);
   prefs_user_id users_preferences.user_id%TYPE;

BEGIN
   FOR c1_val IN c1 LOOP
	-- since we did an outer join, if the user_prefs user_id field is null, then
	-- no record exists, so do an insert. Else do an update
	IF c1_val.prefs_user_id IS NULL THEN
	 INSERT INTO users_preferences (user_id, email_type) 
		values (c1_val.user_id, guess_user_email_type(c1_val.email));
	ELSE UPDATE users_preferences set email_type = guess_user_email_type(c1_val.email)
	 	WHERE user_id = c1_val.user_id;
	END IF;
   END LOOP;
   COMMIT;
END init_email_types;
/
show errors


