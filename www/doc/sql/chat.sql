--
-- chat.sql 
--
-- by philg@mit.edu on April 25, 1999
--

create sequence chat_room_id_sequence;

create table chat_rooms (
	chat_room_id		integer primary key,
	pretty_name		varchar(100),
	-- if set, this is a private chat room, associated with
	-- a particular user group; otherwise public
	private_group_id	references user_groups,
	moderated_p		char(1) default 'f' 
              check (moderated_p in ('t','f')),
	-- if NULL, this room gets archived permanently; can be fractional
	expiration_days		number,
	creation_date		date default sysdate not null,
	active_p		char(1) default 't' check (active_p in ('t','f')),
	-- permissions can be expanded to be more complex later
        scope			varchar(20) not null,
	group_id		integer references user_groups,
	 -- insure consistant state 
       	constraint chat_scope_not_null_check check ((scope='group' and group_id is not null) 
                                                 or (scope='public' and group_id is null))
);

create index chat_rooms_group_idx on chat_rooms ( group_id );

create sequence chat_msg_id_sequence;

-- if the ACS the content tagging system, e.g., for naughty words, is
-- enabled, we store a content_tag (bit mask) for the original MSG
-- and also store a bowdlerized version of the MSG (if necessary) 
-- for quick serving to people who've enabled filtering.

-- so the query for a filtered user would be 
--     nvl(msg_bowdlerized, msg) as filtered_msg 

create table chat_msgs (
	chat_msg_id	integer primary key,
	msg		varchar(4000) not null,
	msg_bowdlerized	varchar(4000),
	content_tag	integer,
	html_p		char(1) default 'f' check (html_p in ('t','f')),
	approved_p	char(1) default 't' check(approved_p in ('t','f')),
	-- things like "joe has entered the room" 
	system_note_p	char(1) default 'f' check(system_note_p in ('t','f')),
	creation_date	date not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null,
	-- if set, this is a 1:1 message
	recipient_user		references users(user_id),
	-- if set, this is a broadcast message of some sort
	chat_room_id		references chat_rooms
);

-- to support a garden variety chat room display

-- tablespace photonet_index;
create index chat_msgs_by_room_date on chat_msgs ( chat_room_id, creation_date );

-- to support an admin looking into a user's history or a customer service 
-- rep's history

-- tablespace photonet_index;
create index chat_msgs_by_user on chat_msgs ( creation_user );

-- to support a query by a user for "any new messages for me?"

-- tablespace photonet_index;
create index chat_msgs_by_recipient on chat_msgs ( recipient_user, creation_date );

-- create the following chained index to entirely avoid hitting the chat_msgs table 
-- when running the proc (chat_last_post) that is hit quite often.
-- Note that this index is unique because chat_msg_id is unique
create unique index chat_msgs_room_approved_id_idx on chat_msgs(chat_room_id, approved_p, chat_msg_id);
