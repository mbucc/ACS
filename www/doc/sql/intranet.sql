-- /www/doc/sql/intranet.sql
--
-- A complete revision of June 1999 by dvr@arsdigita.com
--
-- mbryzek@arsdigita.com, January 2000
--
-- intranet.sql,v 3.58.2.1 2000/07/26 17:24:03 mbryzek Exp


-- we store simple information about a customer
-- all contact information goes in the address book
create table im_customers (
	group_id 	 	primary key references user_groups,
	deleted_p        	char(1) default('f') constraint im_customers_deleted_p check(deleted_p in ('t','f')),
	customer_status_id      references categories,
	customer_type_id	references categories,
	primary_contact_id	references address_book,
	note			varchar(4000),
	referral_source		varchar(1000),
	annual_revenue		references categories,
	-- keep track of when status is changed
        status_modification_date date,
	-- and what the old status was
        old_customer_status_id  references categories,
	-- is this a customer we can bill?
	billable_p		char(1) default('f')
                                constraint im_customers_billable_p_ck check(billable_p in ('t','f')),
	-- What kind of site does the customer want?
	site_concept   		varchar(100),
	-- Who in Client Services is the manager?
	manager   		integer references users,
  	-- How much do they pay us?
	contract_value   	integer,
  	-- When does the project start?
	start_date   		date
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
    project_type_id	    not null references categories,
    project_status_id	    not null references categories,
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
    ticket_project_id 	    references ticket_projects,
    requires_report_p       char(1) default('t')
		            constraint im_project_requires_report_p check (requires_report_p in ('t','f'))
);
create index im_project_parent_id_idx on im_projects(parent_id);

-- we store all urls and their types
create table im_project_url_map (
	group_id		not null references im_projects,
	url_type_id		not null references im_url_types,
	url			varchar(250),
	-- each project can have exactly one type of each type
	-- of url
	primary key (group_id, url_type_id)
);
-- We need to create an index on url_type_id if we ever want to ask
-- "What are all the staff servers?"
create index im_proj_url_url_proj_idx on im_project_url_map(url_type_id, group_id);

-- What states can our customers be in?

create table im_employee_info (
	user_id             integer primary key references users,
	-- this column in out of date; now current_job_id is typically used (eveander)
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
	-- add a constraint to prevent a user from being her own supervisor
	constraint iei_user_supervise_self_ck check (supervisor_id is null or user_id <> supervisor_id),
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
	-- when did the employee leave the company
	termination_date          date,
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
	referred_by 		references users,
	referred_by_recording_user  	integer references users,
	experience_id			integer references categories,
	source_id			integer references categories,		
	original_job_id			integer references categories,
	current_job_id			integer references categories,
	qualification_id		integer references categories,
	department_id			integer references categories,
	termination_reason		varchar(4000),
	voluntary_termination_p		char(1) default 'f'
              constraint iei_voluntary_termination_p_ck check (voluntary_termination_p in ('t','f')),
        recruiting_blurb clob,
        recruiting_blurb_html_p char(1) default 'f'
              constraint recruiting_blurb_html_p_con check (recruiting_blurb_html_p in ('t','f'))
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

create sequence im_facilities_seq start with 1;

create table im_facilities (
        facility_id             integer primary key,
        facility_name           varchar(80) not null,
	phone                   varchar(50),
	fax                     varchar(50),
	address_line1           varchar(80),
	address_line2           varchar(80),
	address_city            varchar(80),
	address_state           varchar(80),
	address_postal_code     varchar(80),
	address_country_code    char(2) 
                                constraint if_address_country_code_fk references country_codes(iso),
	contact_person_id       integer references users,
	landlord                varchar(4000),
	--- who supplies the security service, the code for
	--- the door, etc.
	security                varchar(4000),
	note                    varchar(4000)
);


-- Offices - linked to user groups
create table im_offices (
	group_id	integer 
                        constraint im_offices_group_id_pk primary key
                        constraint im_offices_group_id_fk references user_groups,
        facility_id 	integer
                    	constraint im_offices_facility_id references im_facilities
                    	constraint im_offices_facility_id_nn not null,
	--- is this office and contact information public?
	public_p		char(1) default 'f'
	                        constraint im_offices_public_p_ck check(public_p in ('t','f'))
);


-- a very simple way to add links to a particular office.
-- e.g. Here are the documents for the Boston office
create sequence im_office_links_seq start with 1;
create table im_office_links (
	link_id			integer
 				constraint iol_group_id_pk primary key,
	-- which office
	group_id		integer 
 				constraint iol_group_id_nn not null 
 				constraint iol_group_id_fk references im_offices,
	-- which user posted this link
	user_id			integer 
 				constraint iol_users_id_nn not null 
 				constraint iol_users_id_fk references users,
	url			varchar(300) 
 				constraint iol_url_nn not null,
	link_title		varchar(100) 
 				constraint iol_link_title_nn not null,
	active_p		char(1) default('t') 
 				constraint iol_active_p_ck check (active_p in ('t','f'))
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
	-- We might want to tag a larger unit
	-- For example, if start_block is the first
	-- Sunday of a week, those tagged with
	-- start_of_larger_unit_p might tag
	-- the first Sunday of a month
	start_of_larger_unit_p	char(1) default 'f'  check (start_of_larger_unit_p in ('t','f')),
	note          varchar(4000)
);

-- use im_emploee_percentage_time to find out when and how
-- much an employee worked or will work.

-- to figure out "how many people worked in the block
-- starting with start_block, take the sum the percentage_time/100
-- of the rows with that start_block


create table im_employee_percentage_time ( 
	start_block 	date references im_start_blocks, 
	user_id 	integer references users, 
	percentage_time integer, 
	note 		varchar(4000), 
	primary key (start_block, user_id) 
); 

-- need to quickly find percentage_time for a given start_block/user_id
create unique index im_employee_perc_time_idx on im_employee_percentage_time (start_block, user_id, percentage_time);

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
	--- is this allocation too small to track?
	--- in that case, we will set percentage_time to 0
	-- and mark too_small_to_give_percentage_p = "t"
	too_small_to_give_percentage_p   char(1) default 'f' check (too_small_to_give_percentage_p in ('t','f')), 
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


-- we store simple information about a customer
-- all contact information goes in the address book
create table im_partners (
	group_id 	 	primary key references user_groups,
	deleted_p        	char(1) default('f') constraint im_partners_deleted_p check(deleted_p in ('t','f')),
	partner_type_id         references categories,
	partner_status_id       references categories,
	primary_contact_id	references address_book,
	url			varchar(200),
	note			varchar(4000),
	referral_source		varchar(1000),
	annual_revenue		references categories
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

create or replace function im_category_from_id ( v_category_id IN integer )
return varchar
IS 
  v_category    categories.category%TYPE;
BEGIN
  select category into v_category from categories where category_id = v_category_id;
  return v_category;
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
     (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration, user_group_types_id)
   values
     ('intranet', 'Intranet', 'Intranet Groups', 'closed', 'closed', 'none', user_group_types_seq.nextval);

 end if;
end;
/


-- stuff we need for the Org Chart
-- Oracle will pop a cap in our bitch ass if do CONNECT BY queries 
-- on im_us<ers without these indices

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
show errors

-- returns 1 if the employee has logged his hours within the last 7 work days
create or replace function im_delinquent_employee_p ( v_employee_id IN integer, v_report_date IN date, v_interval IN integer)
RETURN integer
IS
  v_vacation_days integer;
  v_total_days integer;
  v_work_days integer;
  v_employee_start_date date;
  v_delinquent_employee_p integer;
BEGIN

  v_delinquent_employee_p := 0;

  -- fetch the number of vacation days between (trunc(v_report_date) - v_interval) 
  --   and (trunc(v_report_date)) 
  SELECT nvl(sum(least(end_date,trunc(v_report_date)) - greatest(start_date,trunc(v_report_date)-v_interval) + 1),0)
    INTO v_vacation_days
    FROM user_vacations
    where (start_date between trunc(v_report_date)-v_interval and trunc(v_report_date)
           or end_date between trunc(v_report_date)-v_interval and trunc(v_report_date))
    and user_id = v_employee_id;
  v_work_days := v_interval - v_vacation_days;
  v_total_days := v_interval + v_vacation_days;

  -- while there are < v_interval valid work days, look for more valid work days
  WHILE v_work_days < v_interval LOOP
     -- fetch the number of vacation days between (trunc(v_report_date) - v_total_days) 
     --   and (trunc(v_report_date)) 
    SELECT nvl(sum(least(end_date,trunc(v_report_date)) - greatest(start_date,trunc(v_report_date)-v_total_days) + 1),0)
      INTO v_vacation_days
      FROM user_vacations
      where (start_date between trunc(v_report_date)-v_total_days and trunc(v_report_date)
             or end_date between trunc(v_report_date)-v_total_days and trunc(v_report_date))
      and user_id = v_employee_id;
    v_work_days := v_total_days - v_vacation_days;
    v_total_days := v_interval + v_vacation_days;
  END LOOP;

  SELECT start_date 
    INTO v_employee_start_date
    from im_employee_info
    where user_id = v_employee_id;

  v_total_days := greatest(least(v_total_days,trunc(v_report_date)-v_employee_start_date+1),0);


  select nvl(count(1),0)
  into v_delinquent_employee_p
  from users u
  where user_id = v_employee_id
  and exists (select 1 
      from im_employee_percentage_time pt
      where user_id = u.user_id
      and start_block between trunc(sysdate)-7 and trunc(sysdate)
      and percentage_time > 0)
  and not exists (select 1 
      from im_hours h
      where user_id = u.user_id
      and day between trunc(v_report_date)-v_total_days and trunc(v_report_date)
      and day > v_employee_start_date)
  and trunc(v_report_date) - v_total_days - 7  > v_employee_start_date;

  return v_delinquent_employee_p;

END;
/
show errors;


-- we need an easy way to get all information about
-- active employees
create or replace view im_employees_active as
select u.*, 
       info.JOB_TITLE,
       info.JOB_DESCRIPTION,
       info.TEAM_LEADER_P,
       info.PROJECT_LEAD_P,
       info.PERCENTAGE,
       info.SUPERVISOR_ID,
       info.GROUP_MANAGES,
       info.CURRENT_INFORMATION,
       info.LAST_MODIFIED,
       info.SS_NUMBER,
       info.SALARY,
       info.SALARY_PERIOD,
       info.DEPENDANT_P,
       info.ONLY_JOB_P,
       info.MARRIED_P,
       info.DEPENDANTS,
       info.HEAD_OF_HOUSEHOLD_P,
       info.BIRTHDATE,
       info.SKILLS,
       info.FIRST_EXPERIENCE,
       info.YEARS_EXPERIENCE,
       info.EDUCATIONAL_HISTORY,
       info.LAST_DEGREE_COMPLETED,
       info.RESUME,
       info.RESUME_HTML_P,
       info.START_DATE,
       info.RECEIVED_OFFER_LETTER_P,
       info.RETURNED_OFFER_LETTER_P,
       info.SIGNED_CONFIDENTIALITY_P,
       info.MOST_RECENT_REVIEW,
       info.MOST_RECENT_REVIEW_IN_FOLDER_P,
       info.FEATURED_EMPLOYEE_APPROVED_P,
       info.FEATURED_EMPLOYEE_BLURB_HTML_P,
       info.FEATURED_EMPLOYEE_BLURB,
       info.REFERRED_BY
from users_active u, 
     (select * 
        from im_employee_info info 
       where sysdate>info.start_date
         and sysdate > info.start_date
         and sysdate <= nvl(info.termination_date, sysdate)
         and ad_group_member_p(info.user_id, (select group_id from user_groups where short_name='employee')) = 't'
     ) info
where info.user_id=u.user_id;



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

create or replace function im_first_letter_default_to_a ( p_string IN varchar ) 
RETURN char
IS
   v_initial   char(1);
BEGIN

   v_initial := substr(upper(p_string),1,1);

   IF v_initial IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z') THEN
	RETURN v_initial;
   END IF;
  
   RETURN 'A';

END;
/
show errors;
	


-- at given stages in the employee cycle, certain checkpoints
-- must be competed. For example, the employee should receive
-- an offer letter and it should be put in the employee folder

create sequence im_employee_checkpoint_id_seq;

create table im_employee_checkpoints (
	checkpoint_id	integer primary key,
	stage		varchar(100) not null,
	checkpoint	varchar(500) not null
);

create table im_emp_checkpoint_checkoffs (
	checkpoint_id	integer references im_employee_checkpoints,
	checkee		integer not null references users,
	checker		integer not null references users,
	check_date	date,
	check_note	varchar(1000),
	primary key (checkee, checkpoint_id)
);


-- We need to keep track of in influx of employees.
-- For example, what employees have received offer letters?

create table im_employee_pipeline (
	user_id			integer primary key references users,
	state_id		integer not null references categories,
	office_id		integer references user_groups,
	team_id		 	integer references user_groups,
	prior_experience_id 	integer references categories,
	experience_id		integer references categories,
	source_id		integer references categories,		
	job_id			integer references categories,
	projected_start_date	date,
	-- the person at the company in charge of reeling them in.
	recruiter_user_id	integer references users,	
	referred_by		integer references users,
	note			varchar(4000),
	probability_to_start	integer
);


-- keep track of the last_modified on im_employee_info
create or replace trigger im_employee_info_last_modif_tr
before update on im_employee_info
for each row
DECLARE
BEGIN
     :new.last_modified := sysdate;
END;
/
show errors;


-- views on intranet categories to make queries cleaner
create or replace view im_project_status as 
select category_id as project_status_id, category as project_status
from categories 
where category_type = 'Intranet Project Status';

create or replace view im_project_types as
select category_id as project_type_id, category as project_type
from categories
where category_type = 'Intranet Project Type';

create or replace view im_customer_status as 
select category_id as customer_status_id, category as customer_status
from categories 
where category_type = 'Intranet Customer Status';

create or replace view im_customer_types as
select category_id as customer_type_id, category as customer_type
from categories
where category_type = 'Intranet Customer Type';

create or replace view im_partner_status as 
select category_id as partner_status_id, category as partner_status
from categories 
where category_type = 'Intranet Partner Status';

create or replace view im_partner_types as
select category_id as partner_type_id, category as partner_type
from categories
where category_type = 'Intranet Partner Type';

create or replace view im_prior_experiences as
select category_id as experience_id, category as experience
from categories
where category_type = 'Intranet Prior Experience';

create or replace view im_hiring_sources as
select category_id as source_id, category as source
from categories
where category_type = 'Intranet Hiring Source';

create or replace view im_job_titles as
select category_id as job_title_id, category as job_title
from categories
where category_type = 'Intranet Job Title';

create or replace view im_departments as
select category_id as department_id, category as department
from categories
where category_type = 'Intranet Department';

create or replace view im_qualification_processes as
select category_id as qualification_id, category as qualification
from categories
where category_type = 'Intranet Qualification Process';

create or replace view im_annual_revenue as
select category_id as revenue_id, category as revenue
from categories
where category_type = 'Intranet Annual Revenue';

create or replace view im_employee_pipeline_states as
select category_id as state_id, category as state
from categories
where category_type = 'Intranet Employee Pipeline State';




create or replace function im_cust_status_from_id ( v_status_id IN integer )
return varchar
IS 
  v_status    im_customer_status.customer_status%TYPE;
BEGIN
  select customer_status into v_status from im_customer_status where customer_status_id = v_status_id;
  return v_status;
END;
/
show errors;

-- teadams
create sequence intranet_task_board_id_seq;

create table intranet_task_board (
	task_id		integer primary key,	
	task_name	varchar(200) not null,
	body		clob not null,
	next_steps	varchar(1000),
	post_date	date,
	-- person who posted the job
	poster_id	integer references users(user_id),
	-- how long this task should take
	time_id		integer references categories(category_id),
	-- if this visible right now; when the task is filled
	-- removed the job
	active_p	char(1) check (active_p in ('t','f')),
	-- post this task until a given date
	expiration_date	date
);


-- INTRANET STATUS REPORT 

-- all employee status report preferences go in here
create table im_status_report_preferences (
       user_id			integer not null
       constraint isrp_user_id_fk references im_employee_info,
       -- a space separated list of sections not to be displayed
       --   in the customized status report
       killed_sections		varchar(4000),
       -- a space separated list of offices not to be displayed
       --   in the customized status report
       killed_offices		varchar(4000),
       -- whether to display just my projects or everyone's in 
       --   the customized status report
       my_projects_only_p	char(1) default ('f')
       constraint isrp_my_projects_only_p_ck check (my_projects_only_p in ('t','f')), 
       -- whether to display just my customer groups or everyone's in
       --   the customized status report      
       my_customers_only_p      char(1)	default ('f')
       constraint isrp_my_customers_only_p_ck check (my_customers_only_p in ('t','f'))
);


-- a mapping of status report sections and Tcl procedures
create table im_status_report_sections (
       sr_section_id	integer 
         constraint isrs_sr_section_id_pk primary key,
       -- the name of the status report section
       sr_section_name  varchar(50) not null
         constraint isrs_sr_section_name_un unique,
       -- the name of the Tcl procedure used to generate
       --   the status report section 
       sr_function_name varchar(50) not null
         constraint isrs_sr_function_name_un unique
);

create sequence sr_section_id_sequence start with 1;

-- insert sections into im_status_report_sections
insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Population Count', 'im_num_employees');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'New Employees', 'im_recent_employees');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Future Employees', 'im_future_employees');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Employees Out of the Office', 'im_absent_employees');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Future Office Excursions', 'im_future_absent_employees');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Delinquent Employees', 'im_delinquent_employees');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Downloads', 'im_downloads_status');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Customers: Bids Out', 'im_customers_bids_out');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'Customers: Status Changes', 'im_customers_status_change');

insert into im_status_report_sections 
(sr_section_id, sr_section_name, sr_function_name) 
values 
(sr_section_id_sequence.nextval, 'New Registrants', 'im_new_registrants');

insert into im_status_report_sections
(sr_section_id, sr_section_name, sr_function_name)
values
(sr_section_id_sequence.nextval, 'Progress Reports', 'im_project_reports');

commit;

-- END INTRANET STATUS REPORTS



@intranet-population.sql









