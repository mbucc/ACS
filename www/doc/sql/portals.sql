--
-- portals.sql
--
-- by aure@arsdigita.com
-- 

-- portal_tables are sections of information that will appear as tables
-- on the portals pages

create sequence portal_table_id_sequence;

create table portal_tables (
	table_id		integer primary key,
	-- table_name is varchar(4000) because it may contain ADP 
	table_name     		varchar(4000),
	-- adp is where the content of the table is installed
	adp			clob not null,
	-- if you don't want administrators to have direct access to 
	-- the adp, admin_url should be not null
	admin_url		varchar(1000),
	creation_user		integer references users(user_id),
	modified_date		date
);

create sequence portal_page_id_sequence;

create table portal_pages (
	page_id			integer primary key,
	-- define ownership of the page - either as a group page, or individual's page
	-- one of (group_id, user_id) should not be null
	group_id		integer references user_groups,
	user_id			integer references users,
	-- page_name may be null, in which case we use "Page #x" instead
        page_name		varchar(300),
        page_number             integer
);
   
create table portal_table_page_map (
	-- page_id and table_id are mapped to one another her
	page_id			integer references portal_pages,
	table_id	   	integer references portal_tables,
	-- sort_key and page_side define location of the table on the page     	 
	-- this defines an order within this side of this page
	sort_key  	    	integer,
	-- side of the page the table will displayed on
	page_side       	char(1) check (page_side in ('l','r'))
);


-- the audit table and trigger

create sequence portal_audit_id_sequence;

create table portal_tables_audit  (
	audit_id		integer primary key,
	table_id		integer, 
	-- table_name is varchar(4000) because it may contain ADP 
	table_name     		varchar(4000),
	-- adp is where the content of the table is installed
	adp			clob not null,
	-- if you don't want administrators to have direct access to 
	-- the adp, admin_url should be not null
	admin_url		varchar(1000),
	modified_date           date,
	creation_user		integer references users(user_id),
	audit_time		date
);

create or replace trigger portal_tables_audit_trigger
before update or delete  on portal_tables
  for each row
    when ( (old.table_name is not null and (new.table_name is null or old.table_name <> new.table_name))
        or (old.admin_url is not null and (new.admin_url is null or old.admin_url <> new.admin_url))
	or (old.modified_date is not null and (new.modified_date is null or old.modified_date <> new.modified_date))
 )
     begin
       insert into portal_tables_audit 
	(audit_id, table_id, table_name, adp, admin_url, modified_date, creation_user, audit_time)
       values
       	(portal_audit_id_sequence.nextval, :old.table_id, :old.table_name, :old.adp, :old.admin_url, :old.modified_date, :old.creation_user,  sysdate);
     end;
/
show errors

-- Some nice samples by aileen@arsdigita.com

insert into portal_tables (table_id, table_name, adp, admin_url, creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval, 'Stock Quotes', '<% set html [DisplayStockQuotes $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp, admin_url,
creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Current Weather', '<% set html [DisplayWeather $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp,
admin_url,creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Classes', '<% set html [GetClassHomepages $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp,
admin_url,creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Announcements', '<% set html [GetNewsItems $db]%><%=$html%>', '', 1, sysdate);

insert into portal_tables (table_id, table_name, adp,
admin_url,creation_user, modified_date) 
values 
(portal_table_id_sequence.nextval,'Calendar', '<% set html [edu_calendar_for_portal $db]%><%= $html%>', '', 1, sysdate);


