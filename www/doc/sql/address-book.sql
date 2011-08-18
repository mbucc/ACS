--
-- address-book.sql 
--
-- by eveander@arsdigita.com
--
-- supports a personal address book system
--
-- modified 12/17/99 by Tarik Alatovic (tarik@arsdigita.com):
-- added support for scoping (user, group, public, table) to the address book table

create sequence address_book_id_sequence;
create table address_book (
	address_book_id	integer primary key,
	-- if scope=public, this is the address book the whole system
        -- if scope=group, this is the address book for a particular group
        -- is scope=user, this is the address book for for particular user
	-- if scope=table, this address book is associated with a table
        scope           varchar(20) not null,
	user_id		references users,
	group_id	references user_groups,
	on_which_table  varchar(50),
	on_what_id      integer,
	first_names	varchar(30),
	last_name	varchar(30),
	email		varchar(100),
	email2		varchar(100),
	line1		varchar(100),
	line2		varchar(100),
	city		varchar(100),
	-- state
	usps_abbrev	char(2),
	-- big enough to hold zip+4 with dash
	zip_code	varchar(10),
	phone_home	varchar(30),
	phone_work	varchar(30),
	phone_cell	varchar(30),
	phone_other	varchar(30),
	country		varchar(30),
	birthmonth	char(2),
	birthday	char(2),
	birthyear	char(4),
	days_in_advance_to_remind	integer,
	date_last_reminded	date,
	days_in_advance_to_remind_2	integer,
	date_last_reminded_2	date,
	notes		varchar(4000)
);

alter table address_book add constraint address_book_scope_check 
check ((scope='group' and group_id is not null) or
       (scope='user' and user_id is not null) or
       (scope='table' and on_which_table is not null and on_what_id is not null) or
       (scope='public'));

create index address_book_idx on address_book ( user_id );
create index address_book_group_idx on address_book ( group_id );





