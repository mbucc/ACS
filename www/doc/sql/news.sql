--
-- /www/doc/sql/news.sql
--
-- Supports a system for showing announcements to users
--
-- Author: Jesse Koontz, jkoontz@arsdigita.com March 8, 2000
--         Philip Greenspun, philg@mit.edu
--
-- news.sql,v 3.4 2000/03/16 22:04:52 jkoontz Exp

create sequence newsgroup_id_sequence start with 4;

create table newsgroups (
	newsgroup_id	integer primary key,
        -- if scope=all_users, this is the news for all newsgroups
        -- is scope=registered_users, this is the news for all registered users
	-- if scope=public, this is the news for the main newsgroup
	-- if scope=group, this is news associated with a group
        scope           varchar(20) not null,
	group_id	references user_groups,
	check ((scope='group' and group_id is not null) or
	(scope='public') or
	(scope='all_users') or
	(scope='registered_users'))
);

create sequence news_item_id_sequence start with 100000;

create table news_items (
	news_item_id		integer primary key,
	newsgroup_id		references newsgroups not null,
	title			varchar(200) not null,
	body			clob not null,
	-- is the body in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	approval_state		varchar(15) default 'unexamined' check(approval_state in ('unexamined','approved', 'disapproved')),
	approval_date		date,
	approval_user		references users(user_id),
	approval_ip_address	varchar(50),
	release_date		date not null,
	expiration_date		date not null,
	creation_date		date not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null
);

create index newsgroup_group_idx on newsgroups ( group_id );
create index news_items_idx on news_items ( newsgroup_id );

-- Create the default newsgroups

insert into newsgroups (newsgroup_id, scope) values (1, 'all_users');
insert into newsgroups (newsgroup_id, scope) values (2, 'registered_users');
insert into newsgroups (newsgroup_id, scope) values (3, 'public');

-- Create permissions for default newsgroups
