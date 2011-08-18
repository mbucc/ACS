-- /www/doc/sql/intranet.sql
--
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- mbryzek@arsdigita.com, January 2000
--
-- $Id: intranet.sql,v 3.4.2.6 2000/03/17 21:58:51 ron Exp $


-- What states can our customers be in?
create sequence im_customer_status_seq start with 1;
create table im_customer_status (
	customer_status_id	integer primary key,
	customer_status		varchar(100) not null unique,
	display_order		integer default 1
);


-- we store simple information about a customer
-- all contact information goes in the address book
create table im_customers (
	group_id 	 	primary key references user_groups,
	deleted_p        	char(1) default('f') constraint im_customers_deleted_p check(deleted_p in ('t','f')),
	customer_status_id      references im_customer_status,
	primary_contact_id	references address_book,
	note			varchar(4000),
	-- keep track of when status is changed
        status_modification_date date,
	-- and what the old status was
        old_customer_status_id  references im_customer_status
);

-- What are the different project types that we support
create sequence im_project_types_id_seq start with 1;
create table im_project_types (
	project_type_id		integer primary key,
	project_type		varchar(200) not null unique,
	display_order		integer default 1
);

-- In what states can our projects be?
create sequence im_project_status_id_seq start with 1;
create table im_project_status (
	project_status_id	integer primary key,
	project_status		varchar(100) not null unique,
	display_order		integer default 1
);


-- What types of urls do we ask for when creating a new project
-- and in what order?
create sequence im_url_types_type_id_seq start with 1;
create table im_url_types (
	url_type_id		integer not null primary key,
	url_type		varchar(200) not null unique,
	-- we need a little bit of meta data to know how to ask 
	-- the user to populate this field
	to_ask			varchar(1000) not null,
	-- if we put this information into a table, what is the 
	-- header for this type of url?
	to_display		varchar(100) not null,
	display_order		integer default 1
);
	

-----------------------------------------------------------
-- Projects
--
-- 1) Each project can have any number of sub-projects
--
-- 2) Each (sub)project can be billed either hourly or
-- monthly, but not both. If part of a contract is being
-- billed hourly, create a top-level project specifying
-- the monthly fee and a subproject for the work being done 
-- hourly.

create table im_projects (
    -- each project is a subgroup of the group Projects of group_type intranet
    -- the name of the project is the group_name
    group_id                primary key references user_groups,
    parent_id               integer references im_projects,
    customer_id             integer references im_customers,
    project_type_id	    not null references im_project_types,
    project_status_id	    not null references im_project_status,
    description             varchar(4000),
    -- fees
    fee_setup               number(12,2),
    fee_hosting_monthly     number(12,2),	
    fee_monthly             number(12,2),
    bill_hourly_p           char(1) check (bill_hourly_p in ('t','f')),
    start_date              date,
    end_date		    date,
    -- make sure the end date is after the start date
    constraint im_projects_date_const check( end_date - start_date >= 0 ),	
    note                    varchar(4000),
    project_lead_id	    integer references users,
    -- supervisor (team leader)
    supervisor_id	    integer references users,
    ticket_project_id 	    references ticket_projects
);
create index im_project_parent_id_idx on im_projects(parent_id);


-- we store all urls and their types
create table im_project_url_map (
	group_id		not null references im_projects,
	url_type_id		not null references im_url_types,
	url			varchar(250),
	-- each project can have exactly one type of url
	primary key (group_id, url_type_id)
);
-- We need to create an index on url_type_id if we ever want to ask
-- "What are all the staff servers?"
create index im_proj_url_url_proj_idx on im_project_url_map(url_type_id, group_id);


-- What states can our customers be in?

create table im_employee_info (
	user_id             integer primary key references users,
	job_title           varchar(200),
	job_description     varchar(4000),
	-- is this person an official team leader?
	team_leader_p	    char(1) 
		constraint im_employee_team_lead_con check (team_leader_p in ('t','f')),
	-- can this person lead projects?
	project_lead_p      char(1) 
		constraint im_employee_project_lead_con check (project_lead_p in ('t','f')),
	-- percent of a full time person this person works
	percentage	    integer,
	supervisor_id       integer references users,
	group_manages       varchar(100),
	current_information   varchar(4000),
	--- send email if their information is too old
	last_modified       date default sysdate not null,
	ss_number           varchar(20),
	salary              number(9,2),
	salary_period       varchar(12) default 'month' 
	      constraint im_employee_salary_period_con check (salary_period in ('hour','day','week','month','year')),
	--- W2 information
	dependant_p         char(1) 
		constraint im_employee_dependant_p_con check (dependant_p in ('t','f')),
	only_job_p          char(1) 
		constraint im_employee_only_job_p_con check (only_job_p in ('t','f')),
	married_p           char(1) 
		constraint im_employee_married_p_con check (married_p in ('t','f')),
	dependants          integer default 0,
	head_of_household_p char(1) 
		constraint im_employee_head_of_house_con check (head_of_household_p in ('t','f')),
	birthdate           date,
	skills              varchar(2000),
	first_experience    date,	
	years_experience    number(5,2),
	educational_history varchar(4000),
	last_degree_completed    varchar(100),
	resume			 clob,
	resume_html_p		 char(1) 
		constraint im_employee_resume_html_p_con check (resume_html_p in ('t','f')),
	start_date          date,
	received_offer_letter_p	char(1) 
		constraint im_employee_recv_offer_con check(received_offer_letter_p in ('t','f')),
	returned_offer_letter_p char(1) 
		constraint im_employee_return_offer_con check(returned_offer_letter_p in ('t','f')),
	-- did s/he sign the confidentiality agreement?
	signed_confidentiality_p char(1) 
		constraint im_employee_conf_p_con check(signed_confidentiality_p  in ('t','f')),   
	most_recent_review  date,
	most_recent_review_in_folder_p char(1) 
		constraint im_employee_recent_review_con check(most_recent_review_in_folder_p in ('t','f')),
        featured_employee_approved_p char(1) 
              constraint featured_employee_p_con check(featured_employee_approved_p in ('t','f')),
        featured_employee_approved_by integer references users,
        featured_employee_blurb clob,
        featured_employee_blurb_html_p char(1) default 'f'
              constraint featured_emp_blurb_html_p_con check (featured_employee_blurb_html_p in ('t','f')),
	referred_by 		references users
);

create index im_employee_info_referred_idx on im_employee_info(referred_by);



--- We record logged hours in the im_hours table.

create table im_hours (
    user_id          integer not null references users,
    on_what_id       integer not null,
    on_which_table   varchar(50),
    note             varchar(4000),
    day              date,
    hours            number(5,2),
    billing_rate     number(5,2),
    primary key(user_id, on_which_table, on_what_id, day)
);
create index im_hours_table_id_idx on im_hours(on_which_table, on_what_id);


-- Offices - linked to user groups
create table im_offices (
	group_id               	integer primary key references user_groups,
	phone                   varchar(50),
	fax                     varchar(50),
	address_line1           varchar(80),
	address_line2           varchar(80),
	address_city            varchar(80),
	address_state           varchar(80),
	address_postal_code     varchar(80),
	address_country_code    char(2) references country_codes(iso),
	contact_person_id       integer references users,
	landlord                varchar(4000),
	--- who supplies the security service, the code for
	--- the door, etc.
	security                varchar(4000),
	note                    varchar(4000)
);


-- configure projects to have general comments
insert into table_acs_properties (table_name, section_name, user_url_stub, admin_url_stub) values ('im_projects','intranet','/admin/intranet/projects/view.tcl?group_id=','/admin/intranet/projects/view.tcl?group_id=');


create or replace view im_monthly_salaries
as
select user_id, salary/12 as salary
from im_employee_info
where salary_period = 'year'
union
select user_id, salary from im_employee_info
where salary_period = 'month';

create or replace view im_yearly_salaries
as
select user_id, round(salary * 12) as salary
from im_employee_info
where salary_period = 'month'
union
select user_id, salary from im_employee_info
where salary_period = 'year';

show errors




-- We base our allocations, employee count, etc. around
-- a fundamental unit or block.
-- im_start_blocks record the dates these blocks
-- will start for this system.

create table im_start_blocks (
	start_block   date not null primary key,
	note          varchar(4000)
);

create table im_employee_percentage_time ( 
	start_block 	date references im_start_blocks, 
	user_id 	integer references users, 
	percentage_time integer, 
	note 		varchar(4000), 
	primary key (start_block, user_id) 
); 


-- tracks the money coming into a contract over time

create sequence im_project_payment_id_seq start with 10000;

create table im_project_payments (
	payment_id   integer not null primary key,
	group_id	integer references im_projects,
	start_block	date references im_start_blocks,
	fee             number(12,2),
	-- setup, monthly, monthly_hosting, hourly, stock, other
        fee_type        varchar(50),
	paid_p  	char(1) default 'f' check (paid_p in ('t','f')),
	due_date	      date,
	received_date	      date,
	note		      varchar(4000),
	last_modified           date not null,
 	last_modifying_user     not null references users,
	modified_ip_address     varchar(20) not null
);


create table im_project_payments_audit (
	payment_id   integer,
	group_id	integer references im_projects,
	start_block	date references im_start_blocks,
	fee             number(12,2),
	-- setup, monthly, monthly_hosting, hourly, stock, other
        fee_type        varchar(50),
	paid_p  	char(1) default 'f' check (paid_p in ('t','f')),
	due_date	      date,
	received_date	      date,
	note		      varchar(4000),
	last_modified           date not null,
 	last_modifying_user     not null references users,
	modified_ip_address     varchar(20) not null,
	delete_p                char(1) default 'f' check (delete_p in ('t','f'))
);

create index im_proj_payments_aud_id_idx on im_project_payments_audit(payment_id);

create or replace trigger im_project_payments_audit_tr
          before update or delete on im_project_payments
          for each row
          begin
                  insert into im_project_payments_audit (
                  payment_id,group_id, start_block, fee,
	          fee_type, paid_p, due_date, received_date, note, 
                  last_modified,
                  last_modifying_user, modified_ip_address
                  ) values (
                  :old.payment_id, :old.group_id, :old.start_block, :old.fee,
        	  :old.fee_type, :old.paid_p, :old.due_date, 
                  :old.received_date, 
		  :old.note, :old.last_modified,
                  :old.last_modifying_user, :old.modified_ip_address
                  );
end im_project_payments_audit_tr;
/
show errors

--- im_allocations is used to do predictions and tracking based on
--- percentage of time/project. 

-- im_allocations does not have a separate audit
-- table because we want to take a snapshot of allocation 
-- at a chosed times.


create sequence im_allocations_id_seq;

create table im_allocations (
	--- allocation_id is not the primary key becase
	--- an allocation may be over several blocks of
	---  time.  We store a row per block.
	---  To answer the question "what is the allocation for
	--- this time block, query the most recent allocation
	--- for either that allocation_id or user_id.
	allocation_id    integer not null,
	group_id       integer not null references im_projects,
	-- this may be null because we will rows we need to store
	-- rows that are currently not allocated (future hire or
	-- decision is not made)
	user_id		 integer  references users,
	-- Allocations are divided up into blocks of time.
	-- Valid dates for start_block must be separated
	-- by the block unit.  For example, if your block unit
	-- was a week, valid start_block dates may be "Sundays"
	-- If the start_blocks don't align, reports get very difficult.
	start_block      date references im_start_blocks,
	percentage_time	 integer not null,
	note		 varchar(1000),
	last_modified           date not null,
        last_modifying_user     not null references users,
        modified_ip_address     varchar(20) not null
);
create index im_all_alloc_id_group_id_idx on im_allocations(allocation_id);
create index im_all_group_id_group_id_idx on im_allocations(group_id);
create index im_all_group_id_user_id_idx on im_allocations(user_id);
create index im_all_group_id_last_mod_idx on im_allocations(last_modified);


create table im_allocations_audit (
	allocation_id    integer not null,
	group_id       integer not null references im_projects,
	user_id		 integer  references users,
	-- Allocations are divided up into blocks of time.
	-- Valid dates for start_block must be separated
	-- by the block unit.  For example, if your block unit
	-- was a week, valid start_block dates may be "Sundays"
	-- If the start_blocks don't align, reports get very difficult.
	start_block      date references im_start_blocks,
	percentage_time	 integer not null,
	note		 varchar(1000),
	last_modified           date not null,
        last_modifying_user     not null references users,
        modified_ip_address     varchar(20) not null
);


--- we will put a row into the im_allocations_audit table if
--- a) another row is added with the same allocation_id and start_block
--- b) another row is added with the same user_id, group_id and start_block

create or replace trigger im_allocations_audit_tr
before update or delete on im_allocations
for each row
begin
        insert into im_allocations_audit (
        allocation_id, group_id, user_id,  start_block, percentage_time,note, last_modified, last_modifying_user, modified_ip_address
 	) values (
        :old.allocation_id, :old.group_id, :old.user_id,  :old.start_block, :old.percentage_time,:old.note, :old.last_modified, :old.last_modifying_user, :old.modified_ip_address);
end;
/
show errors


create or replace function get_start_week (v_start_date IN date)
return date
IS
 v_date_round date;
 v_date_next_sun date;
 v_date_check date;
BEGIN
 select round(v_start_date, 'day') into v_date_round from dual;
 select trunc(next_day(v_start_date, 'sunday'),'day') into v_date_next_sun from dual;
 
 IF v_date_round < v_date_next_sun THEN
    -- we have the beginning of the week
    return v_date_round;
 END IF;

 v_date_check := v_start_date - 3;
 select round(v_date_check, 'day') into v_date_round from dual;
 IF v_date_round = v_date_next_sun THEN
    --the day is saturday, so we need to subtract one more day
    v_date_check := v_date_check - 1;
    select round(v_date_check, 'day') into v_date_round from dual;
 END IF;
 
 return v_date_round;
END get_start_week;
/
show errors


-- calculate the monthly fee for a given start_block and end_block


create or replace function im_projects_monthly_fee(v_group_id IN integer, v_start_block IN date, v_end_block in date)
return number
is
   monthly_fee      	number(10,2);
BEGIN

select sum(fee) into monthly_fee from
im_project_payments
where im_project_payments.group_id = v_group_id
and start_block >= v_start_block
and start_block < v_end_block
and fee_type <> 'setup'
and fee_type <> 'stock'
group by group_id;

return monthly_fee;

END im_projects_monthly_fee;
/
show errors


-- calulate the setup fee for a given start_block and end_block

create or replace function im_projects_setup_fee(v_group_id IN integer, v_start_block IN date, v_end_block in date)
return number
is
   monthly_fee      	number(10,2);
BEGIN

select sum(fee) into monthly_fee from
im_project_payments
where im_project_payments.group_id = v_group_id
and start_block >= v_start_block
and start_block < v_end_block
and fee_type= 'setup'
group by group_id;

return monthly_fee;

END im_projects_setup_fee;
/
show errors


-- calulate the stock for a given start_block and end_block

create or replace function im_projects_stock_fee(v_group_id IN integer, v_start_block IN date, v_end_block in date)
return number
is
   stock_fee      	number(10,2);
BEGIN

select sum(fee) into stock_fee from
im_project_payments
where im_project_payments.group_id = v_group_id
and start_block >= v_start_block
and start_block < v_end_block
and fee_type= 'stock'
group by group_id;

return stock_fee;

END im_projects_stock_fee;
/
show errors



create sequence im_partner_types_seq start with 1;
create table im_partner_types (
	partner_type_id	        integer primary key,
	partner_type		varchar(100) not null unique,
	display_order		integer default 1
);

-- In what states can our projects be?
create sequence im_partner_status_id_seq start with 1;
create table im_partner_status (
	partner_status_id	integer primary key,
	partner_status		varchar(100) not null unique,
	display_order		integer default 1
);


-- we store simple information about a customer
-- all contact information goes in the address book
create table im_partners (
	group_id 	 	primary key references user_groups,
	deleted_p        	char(1) default('f') constraint im_partners_deleted_p check(deleted_p in ('t','f')),
	partner_type_id         references im_partner_types,
	partner_status_id       references im_partner_status,
	primary_contact_id	references users,
	url			varchar(200),
	note			varchar(4000)
);


-- The various procedures. Note that user-groups don't really
-- work here because of the meta data we 
-- store (supervisor/certifier/long note)

create sequence im_procedures_procedure_id_seq start with 1;

create table im_procedures (
    procedure_id            integer not null primary key,
    name                    varchar(200) not null,
    note                    varchar(4000),
    creation_date           date not null,
    creation_user           integer not null references users,
    last_modified           date,
    last_modifying_user     integer references users
);


-- Users certified to do a certain procedure

create table im_procedure_users (
    procedure_id        integer not null references im_procedures,
    user_id             integer not null references users,
    note                varchar(400),
    certifying_user     integer not null references users,
    certifying_date     date not null,
    primary key(procedure_id, user_id)
);

-- Occasions the procedure was done by a junior person,
-- under the supervision of a certified person

create sequence im_proc_event_id_seq;

create table im_procedure_events (
    event_id            integer not null primary key,
    procedure_id        integer not null references im_procedures,
    -- the person who did the procedure
    user_id             integer not null references users,
    -- the certified user who supervised
    supervising_user    integer not null references users,
    event_date          date not null,
    note                varchar(1000)
);



-- Now the pls definitions

-- Some helper functions to make our queries easier to read
create or replace function im_proj_type_from_id ( v_project_type_id IN integer )
return varchar
IS 
  v_project_type    im_project_types.project_type%TYPE;
BEGIN
  select project_type into v_project_type from im_project_types where project_type_id=v_project_type_id;
  return v_project_type;
END;
/
show errors;

create or replace function im_proj_status_from_id ( v_project_status_id IN integer )
return varchar
IS 
  v_project_status    im_project_status.project_status%TYPE;
BEGIN
  select project_status into v_project_status from im_project_status where project_status_id=v_project_status_id;
  return v_project_status;
END;
/
show errors;

create or replace function im_proj_url_from_type ( v_group_id IN integer, v_url_type IN varchar )
return varchar
IS 
  v_url 		im_project_url_map.url%TYPE;
BEGIN
  begin
    select url into v_url 
      from im_url_types, im_project_url_map
     where group_id=v_group_id
       and im_url_types.url_type_id=im_project_url_map.url_type_id
       and url_type=v_url_type;
  exception when others then null;
  end;
  return v_url;
END;
/
show errors;


create or replace function im_cust_status_from_id ( v_customer_status_id IN integer )
return varchar
IS 
  v_customer_status    im_customer_status.customer_status%TYPE;
BEGIN
  select customer_status into v_customer_status from im_customer_status where customer_status_id=v_customer_status_id;
  return v_customer_status;
END;
/
show errors;



--- Define an administration group for the Intranet

begin
   administration_group_add ('Intranet Administration', 'intranet', 'intranet', '', 'f', '/admin/intranet/'); 
end;
/


-- Create a group type of intranet. Does nothing if the group type is already defined

declare
 n_system_group_types	integer;
begin
 select count(*) into n_system_group_types from user_group_types where group_type = 'intranet';
 if n_system_group_types = 0 then 
   -- create the group type
   insert into user_group_types
     (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration)
   values
     ('intranet', 'Intranet', 'Intranet Groups', 'closed', 'closed', 'full');

 end if;
end;
/


-- stuff we need for the Org Chart
-- Oracle will pop a cap in our bitch ass if do CONNECT BY queries 
-- on im_users without these indices

create index im_employee_info_idx1 on im_employee_info(user_id, supervisor_id);
create index im_employee_info_idx2 on im_employee_info(supervisor_id, user_id);

-- you can't do a JOIN with a CONNECT BY so we need a PL/SQL proc to
-- pull out user's name from user_id

create or replace function im_name_from_user_id(v_user_id IN integer)
return varchar
is
  v_full_name varchar(8000);
BEGIN
  select first_names || ' ' || last_name into v_full_name 
   from users 
   where user_id = v_user_id;
  return v_full_name;
END im_name_from_user_id;
/
show errors

create or replace function im_supervises_p(v_supervisor_id IN integer, v_user_id IN integer)
return varchar
is
  v_exists_p char;
BEGIN
  select decode(count(1),0,'f','t') into v_exists_p
   from im_employee_info
   where user_id = v_user_id
   and level > 1
   start with user_id = v_supervisor_id
   connect by supervisor_id = PRIOR user_id;
   return v_exists_p;
END im_supervises_p;
/
show errors;


create or replace function im_project_ticket_project_id ( v_group_id IN integer )
RETURN integer
IS
  v_project_id    ticket_projects.project_id%TYPE;
BEGIN
  v_project_id := 0;
  BEGIN
    select project_id into v_project_id from ticket_projects where group_id=v_group_id;
    EXCEPTION WHEN OTHERS THEN NULL;
  END;
  return v_project_id;
END;
/
show errors;

-- Populate all the status/type/url with the different types of 
-- data we are collecting
@intranet-population.sql
