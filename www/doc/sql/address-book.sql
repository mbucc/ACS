--
-- address-book.sql 
--
-- by eveander@arsdigita.com
--
-- supports a personal address book system
--
-- modified 12/17/99 by Tarik Alatovic (tarik@arsdigita.com):
-- added support for scoping (user, group, public, table) to the address book table
--
-- modified 7/5/00 by Xian Ke, ake@arsdigita.com
-- some additions to support a new user interface.
--
-- address-book.sql,v 3.1.2.3 2000/08/17 20:10:36 gjin Exp

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

-- Added by Xian Ke xke@arsdigita.com 7/5/00 for new user interface.
-- Added to upgrade-3.4-3.4.1.sql 8/14/00 by ron@arsdigita.com

create table address_book_viewable_columns (
       column_name  varchar(100) primary key,
       -- for when the column name results from an "as" command
       -- for ex., you can customize viewing columns
       extra_select varchar(4000),
       pretty_name  varchar(4000) not null,
       sort_order   integer not null
);

-- default columns already in other tables

insert into address_book_viewable_columns values ('first_names', '', 'First Name', 1);
insert into address_book_viewable_columns values ('last_name', '', 'Last Name',2);

-- linked email addresses
insert into address_book_viewable_columns values ('email', '''<a href="mailto:''||email||''">''||email||''</a>''', 'Email', 3);
insert into address_book_viewable_columns values ('email2', '''<a href="mailto:''||email2||''">''||email2||''</a>''', 'Email(2)', 4);
insert into address_book_viewable_columns values ('address', 'line1||''<br>''||line2', 'Address', 5);
insert into address_book_viewable_columns values ('city', '', 'City', 6);
insert into address_book_viewable_columns values ('usps_abbrev', '', 'State', 7);

-- using "decode" so that if usps_abbreb is null, then do not display the comma
insert into address_book_viewable_columns values ('city_state', 'city||decode(usps_abbrev, NULL,'''', '', '' || usps_abbrev)', 'City, State', 8);
insert into address_book_viewable_columns values ('zip_code', '', 'Zip Code', 9);
insert into address_book_viewable_columns values ('phone_home', '', 'Home Phone', 10);
insert into address_book_viewable_columns values ('phone_work', '', 'Work Phone', 11);
insert into address_book_viewable_columns values ('phone_cell', '', 'Cell Phone', 12);
insert into address_book_viewable_columns values ('phone_other', '', 'Other Phone', 13);
insert into address_book_viewable_columns values ('country', '', 'Country', 14);
-- again, use decode to not display anything if no values entered
insert into address_book_viewable_columns values ('birthdate', 'birthmonth||decode(birthday, null, '''',''/''||birthday)||decode(birthyear, null, '''',''/''||birthyear)', 'Birth Date', 15);

insert into address_book_viewable_columns values ('birthmonth', '', 'Birth Month', 16);
insert into address_book_viewable_columns values ('birthyear', '', 'Birth Year', 17);
insert into address_book_viewable_columns values ('birthday', '', 'Birth Day', 18);
insert into address_book_viewable_columns values ('notes', '', 'Notes', 19);








