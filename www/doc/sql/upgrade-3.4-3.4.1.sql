-- /www/doc/sql/upgrade-3.4-3.4.1.sql
--
-- Script to upgrade an ACS 3.4.0 database to ACS 3.4.1
-- 
-- upgrade-3.4-3.4.1.sql,v 1.1.2.11 2000/09/05 18:20:56 cnk Exp
--

-- BEGIN INTRANET --
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


-- ron 8/18/2000
--
-- I'm commenting this out because it was part of 3.4.0 the datamodel, so
-- inserting for the upgrade generates an error.
--
-- mbryzek 6/21/2000
-- alter table im_employee_info add constraint iei_user_supervise_self_ck 
--	check (supervisor_id is null or user_id <> supervisor_id);

-- mbryzek/mdettinger - im_customers modifications
alter table im_customers add (
	billable_p	char(1) default('f')
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

update im_customers set billable_p = 't' where customer_type_id in (select category_id from categories where trim(upper(category)) like 'FULL SERVICE%');

create or replace view im_employees_active as
select u.*, 
       info.CURRENT_JOB_ID,
       info.JOB_DESCRIPTION,
       info.TEAM_LEADER_P,
       info.PROJECT_LEAD_P,
       info.PERCENTAGE,
       info.SUPERVISOR_ID,
       info.GROUP_MANAGES,
       info.CURRENT_INFORMATION,
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
     (select info.* 
        from im_employee_info info 
       where sysdate>info.start_date
         and sysdate > info.start_date
         and sysdate <= nvl(info.termination_date, sysdate)
         and ad_group_member_p(info.user_id, (select group_id from user_groups where short_name='employee')) = 't'
     ) info
where info.user_id=u.user_id;



-- the total number of normalized hours possible for this user, taking
-- into account the user's start and end dates of employment
create or replace function im_max_normalized_per_user( p_start_block date, 
                                                       p_end_block date, 
                                                       p_user_id integer )
return real
IS 
        v_max_normalized_hours real;
        v_emp_nearest_start_block date;
        v_emp_nearest_end_block date;
        v_emp_start_date date;
        v_emp_termination_date date;

BEGIN
        select info.start_date into v_emp_start_date 
             from im_employee_info info 
           where user_id = p_user_id;

        select info.termination_date into v_emp_termination_date 
             from im_employee_info info 
           where user_id = p_user_id;
     
  	IF v_emp_start_date IS NOT NULL THEN
	 	-- pull out the start block immediately before the employee's start date
		select max(start_block) into v_emp_nearest_start_block
                  from im_start_blocks 
                 where start_block <= v_emp_start_date;
	END IF;
		
  	IF v_emp_termination_date IS NOT NULL THEN
		select min(start_block) into v_emp_nearest_end_block
                  from im_start_blocks 
                 where start_block >= v_emp_termination_date;
	END IF;
		
	-- Notice that we still use nvl here - if the employee start or termination date does
	-- not have a corresponding start_block, we want to default to the range provided to
	-- this function. Think about it - it makes sense... If the employee started before we 
	-- started using start_blocks, we should never use their employment start date as a way
	-- of limiting the number of hours they could work.
	

	-- we need the total number of normalized hours over the specified period.
	-- this is equivalent to 40 hours of work per start block (each start block represents 1 week)
        -- note that we multiply by 40 for 40 hours per week full time
        -- we divide by 100 because we are dealing with percentages
        -- NOTE we must join with start_blocks .. it is tempting just to
	-- sum the percentages for a user, but if they are missing rows
	-- then we get back null. therefore we join im_employee_percentage_time
        -- with start_blocks and use nvl for missing rows.
 	 select sum(40/100*nvl(percentage_time,100))
            into v_max_normalized_hours
          from im_start_blocks blocks, im_employee_percentage_time ept
         where blocks.start_block >= p_start_block
           and blocks.start_block >= nvl(v_emp_nearest_start_block,p_start_block)
           and blocks.start_block < p_end_block
           and blocks.start_block < nvl(v_emp_nearest_end_block,p_end_block)
           and ept.user_id(+) = p_user_id
           and ept.start_block(+) = blocks.start_block;
        return v_max_normalized_hours;
END;
/
show errors

-- returns the total number of hours specified user has logged over
-- the specified time period
create or replace function im_actual_hours
	 ( p_user_id integer, 
           p_start_block date, 
           p_end_block date )
return real
IS
        v_total_hours real; 
BEGIN
    	SELECT nvl(sum(hours),0) INTO  v_total_hours 
	from im_hours 
	where im_hours.user_id = p_user_id 
	and im_hours.day >= p_start_block
	and im_hours.day < p_end_block;

	return v_total_hours;
END;
/
show errors;


-- returns the total number of hours specified user has logged over
-- the specified time period on the specified project
create or replace function im_actual_hours_on_project
	 ( p_user_id integer, 
           p_start_block date,
           p_end_block date,
           p_on_which_table varchar, 
           p_on_what_id integer )
return real
IS
        v_total_hours real; 
BEGIN
    	SELECT nvl(sum(im_hours.hours),0) INTO  v_total_hours 
	from im_hours 
	where im_hours.user_id = p_user_id 
	and im_hours.day >= p_start_block
	and im_hours.day < p_end_block
	and im_hours.on_what_id = p_on_what_id
	and im_hours.on_which_table = p_on_which_table;

	return v_total_hours;
END;
/
show errors;

-- returns the total number of hours specified user has logged over
-- the specified time period on the specified project
create or replace function im_actual_hours_in_period
	 ( p_user_id integer, 
           p_start_block date,
           p_end_block date )
return real
IS
        v_total_hours real; 
BEGIN
    	SELECT nvl(sum(im_hours.hours),0) INTO  v_total_hours 
	from im_hours 
	where im_hours.user_id = p_user_id 
	and im_hours.day >= p_start_block
	and im_hours.day < p_end_block;

	return v_total_hours;
END;
/
show errors;

create or replace function im_max_normalized_hours (p_start_block date, p_end_block date)
return real
IS 
        v_max_normalized_hours real;
BEGIN

	-- we need the total number of normalized hours over the specified period.
	-- this is equivalent to 40 hours of work per start block (each start block represents 1 week)
	select 40 * count(blocks.start_block) into v_max_normalized_hours
          from im_start_blocks blocks
         where blocks.start_block >= p_start_block
           and blocks.start_block < p_end_block;

        return v_max_normalized_hours;
END;
/
show errors



-- returns the number of normalized hours for a given project on a given time period
create or replace function im_normalize_hours 	
 	( p_user_id integer, 
          p_start_block date, 
          p_end_block date,
          p_on_which_table varchar, 
          p_on_what_id integer )
return real
IS
	v_total_hours real;
	v_total_hours_on_project real;
	v_max_normalized_hours real;
	v_running_normalized_hours real;
	v_this_block date;

	cursor c_start_blocks ( p_cursor_start_block IN date,  p_cursor_end_block IN date ) IS
		select block.start_block
		  from im_start_blocks block
		 where block.start_block >= p_cursor_start_block 
		   and block.start_block < p_cursor_end_block;

BEGIN
	v_running_normalized_hours := 0;

	open c_start_blocks(to_date(p_start_block), to_date(p_end_block) );

	LOOP
	    fetch c_start_blocks into v_this_block;
	    exit when c_start_blocks%NOTFOUND;

	     -- total hours we've logged this week
     	     v_total_hours := im_actual_hours_in_period (p_user_id, v_this_block, to_date(v_this_block+7));

   	     v_total_hours_on_project := im_actual_hours_on_project (p_user_id, v_this_block, to_date(v_this_block+7), p_on_which_table, p_on_what_id);
     	     v_max_normalized_hours := im_max_normalized_per_user (v_this_block, v_this_block+7, p_user_id);

   	     IF v_total_hours > v_max_normalized_hours THEN
		v_running_normalized_hours := v_running_normalized_hours + ( v_total_hours_on_project * v_max_normalized_hours / v_total_hours );
             ELSE 
		v_running_normalized_hours := v_running_normalized_hours + v_total_hours_on_project;
	     END IF;

	END LOOP;
	
	RETURN v_running_normalized_hours;
END;
/
show errors;

-- this function uses the normalized hours in a time period
-- to calculate the fte on a given project
create or replace function im_fte_in_period (p_user_id integer, 
                                             p_start_date date, 
                                             p_end_date date,
					     p_on_which_table varchar, 
                                             p_on_what_id integer)
return real
IS  
	v_total_normalized_hours real;
	v_normalized_hours_on_project real;
BEGIN
	select im_normalize_hours(p_user_id, p_start_date, p_end_date, p_on_which_table, p_on_what_id) into v_normalized_hours_on_project from dual;
	select im_max_normalized_per_user(p_start_date, p_end_date, p_user_id) into v_total_normalized_hours from dual;
	IF v_total_normalized_hours <= 0 THEN
		RETURN 0;
	ELSE 
		RETURN v_normalized_hours_on_project/v_total_normalized_hours;
	END IF;
END;
/
show errors;
	
-- Add column billable_type_id to im_projects for Utilization report

alter table im_projects add (billable_type_id integer references categories);


-- mbryzek - 8/4/2000
-- Need this to do a quick connect by for all projects/subprojects belonging
-- to one customer
create index im_project_customer_id_idx on im_projects(customer_id);		

-- prevent full table scans of bboard_topics when all we care about is one group
create index bboard_topics_group_id_idx on bboard_topics(group_id);

-- Create a chained index on parent_id, group_id because all we often need is
-- just the group_id
drop index im_project_parent_id_idx;
create unique index im_project_parent_group_id_idx on im_projects(parent_id, group_id);

-- need this index for hours computation
create index im_hours_id_table_hours_idx on im_hours(on_what_id, on_which_table, hours);

-- for quick project status lookups
create unique index im_project_status_group_id_idx on im_projects(project_status_id, group_id);

-- need this one to find out, for example, all active customers
create unique index im_customers_status_group_idx on im_customers(customer_status_id, group_id);


-- END INTRANET --


-- BEGIN INTRANET STATUS REPORTS

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



-- BEGIN MONITORING  -- 

-- Begin Estimation module datamodel.
-- the following table lists tables which are to be estimated.  
-- A scheduled proc runs 
-- analyze table <table_name> estimate statistics sample <percent_estimating>
-- where table-name is pulled from the table as is percent_estimating

create table ad_monitoring_tables_estimated (
	table_entry_id		integer constraint amte_table_entry_id_pk primary key,
	-- This is a table name, but we don't want it to 
	-- reference user_tables since then deleting a table
	-- would be problematic, since this would reference it
	-- Instead, in the proc we use to run this (a scheduled
	-- proc, we check to make sure the table exists.
	table_name 		varchar(40) constraint amte_table_name_nn not null,
	-- The percent of the table we estimate, defaults to 20%
	percent_estimating 	integer default 20,
	last_percent_estimated  integer,
	--Do we actually want to run this?
	enabled_p		char(1) default 't' constraint amte_enabled_p_ck check (enabled_p in ('t', 'f')),
	last_estimated 		date
); 

--Sequence for above table
create sequence ad_monitoring_tab_est_seq start with 1000;


-- END MONITORING --


-- BEGIN WIMPYPOINT BACKUP UPGRADES --


-- This procedure converts a table to use integer primary keys if it 
-- does not already.. its really nasty and involves dropping constraints
-- which reference the table in name, dropping the table's primary key
-- adding a unique constraint, creating a new, integer column
-- populating it with the sequence, then adding the correct constraints to
-- reference the unique columns, and then adding a primary key constraint.
-- Kevin Schmidt (kschmidt@arsdigita.com)

create or replace procedure change_to_integer_key (in_table_name IN VARCHAR2, in_sequence_name IN VARCHAR2) 
AS
  --Two cursors we will use to check existence of the table and sequence 
  CURSOR exist_check1 IS
	select 1 from user_sequences where sequence_name=upper(in_sequence_name);
  CURSOR exist_check2 IS	
	select 1 from user_tables where table_name=upper(in_table_name);

  --A cursor for dropping the old referential constraints
  CURSOR c1 IS
	select 'alter table ' || uc.table_name || ' drop constraint ' || uc.constraint_name as dropconsstat,
       	uc.constraint_name as constraint_name, 
       	uc.table_name as table_name, 
       	ucc.column_name as column_name, 
       	refs.refCol as refCol from 
       	       (select column_name as refCol
    		from user_cons_columns ucc, user_constraints uc1, user_constraints uc2
    		where ucc.constraint_name = uc1.constraint_name 
    		and uc1.constraint_type='R'
    		and uc1.r_constraint_name = uc2.constraint_name
    		and uc2.table_name=upper(in_table_name)) refs,  
        user_constraints uc, user_cons_columns ucc 
        where constraint_type='R' and r_constraint_name is not null 
              and r_constraint_name=ucc.constraint_name 
              and ucc.table_name=upper(in_table_name) order by dropconsstat;

   --A cursor dropping the primary keys
   CURSOR c2 IS
	select 'alter table ' || in_table_name || ' drop constraint ' || uc.constraint_name as drop_pk_cons, column_name as column_name from user_constraints uc, user_cons_columns ucc where constraint_type='P' and uc.table_name=upper(in_table_name) and ucc.constraint_name=uc.constraint_name order by drop_pk_cons;  

   --Storage for the table names so we can create new constraints later
   TYPE CharList IS TABLE of CHAR(32) index by binary_integer;
   --Store the tables we need to change
   v_table_list CharList;
   --Store the columns of those tables
   v_col_list CharList;
   --Store the columns that each reference constraint references
   v_references_cols_list CharList;
   -- Store the constraint names
   v_cons_names CharList;

   --2 indexes
   i integer;
   j integer;

   --A flag variable
   v_test_var integer;
   --A variable to hold the last constraint statement
   v_last_cons_stmnt varchar(4000);
   --Placehold vars
   v_rows_processed INTEGER;	
   v_cursor_name INTEGER;
   --A string to build up the new unique statement to replace the old P.K.
   v_unique_cons varchar(4000);
   v_ref_local_cols varchar(4000);
   v_ref_other_cols varchar(4000);

begin 
  
  --So some checking
  v_test_var:=0;
  FOR testrec in exist_check1 LOOP
	v_test_var:= v_test_var + 1;
  END LOOP;
  FOR testrec2 in exist_check2 LOOP
 	v_test_var:=v_test_var + 1;
  END LOOP;
  --Set the last constraint we saw.. ie none
  v_last_cons_stmnt:='this is not it';
  IF v_test_var > 0 THEN
  	i:=1;
	--Loop over all the referential constraint we will drop
  	FOR c1_rec in c1 LOOP
		--Only drop it if this is a new constraint (since multiple columns)
		--can share the same constraint
		if v_last_cons_stmnt <> c1_rec.dropconsstat THEN 
			--Delete old referential constraints
			dbms_output.put_line(substr(c1_rec.dropconsstat, 1, 255)); 
			--Replace the execute immediate
			v_cursor_name := dbms_sql.open_cursor;
			DBMS_SQL.PARSE(v_cursor_name, c1_rec.dropconsstat, dbms_sql.native);
			v_rows_processed := dbms_sql.execute(v_cursor_name);
			DBMS_SQL.close_cursor(v_cursor_name);
		END IF;
		--Update the last constraint statement
		v_last_cons_stmnt := c1_rec.dropconsstat;
		--Save info
		v_test_var:=0;
		for j in 1..i-1 LOOP

			IF trim(v_table_list(j)) = trim(c1_rec.table_name) and (trim(v_col_list(j))=trim(c1_rec.column_name) or trim(v_references_cols_list(j))=trim(c1_rec.refCol)) and trim(v_cons_names(j))=trim(c1_rec.constraint_name) THEN
				v_test_var:=1;

			END IF;
		END LOOP;
		if v_test_var=0 THEN
			v_table_list(i):=c1_rec.table_name;
			v_col_list(i):=c1_rec.column_name;
			v_cons_names(i):=c1_rec.constraint_name;
			v_references_cols_list(i):=c1_rec.refCol;
			--increment counter
			i:= i + 1;
		end if;
	  END LOOP;
	  --The beginning of the unique constraint
	  v_unique_cons := 'alter table ' || in_table_name || ' add constraint ' || trim(substr(in_table_name, 1, 20)) || '_old_pkey UNIQUE(';
	  j:=1;
	 
	  v_last_cons_stmnt:='not valid';
	  FOR c2_rec in c2 LOOP
		--We now begin adding the columns to the above statement
	        if j > 1 THEN
		   v_unique_cons := v_unique_cons || ', ';
		END IF;
		--Drop constraints we haven't seen before
		if c2_rec.drop_pk_cons <> v_last_cons_stmnt THEN
			--Drop old primary key constraints
			dbms_output.put_line(substr(c2_rec.drop_pk_cons,1,255)); 
		
			v_cursor_name := dbms_sql.open_cursor;
			DBMS_SQL.PARSE(v_cursor_name, c2_rec.drop_pk_cons, dbms_sql.native);
			v_rows_processed := dbms_sql.execute(v_cursor_name);
			DBMS_SQL.close_cursor(v_cursor_name);
			--execute immediate c2_rec.drop_pk_cons;
		END IF;
		--Save the info
		v_last_cons_stmnt := c2_rec.drop_pk_cons;
		--All the primary key columns were jointly unique, and 
	   	--so we build one unique constraint.
		v_unique_cons:= v_unique_cons || c2_rec.column_name;
		--Increment counter
	        j:= j + 1;
	  END LOOP;
          --Add a closing paren
	  v_unique_cons := v_unique_cons || ')';
	  --Did we do anything?
	  IF j > 1 THEN
	  	--Add the unique Constraint.
	  	dbms_output.put_line(substr(v_unique_cons,1,255)); 
	  	commit;
	  	v_cursor_name := dbms_sql.open_cursor;
	  	DBMS_SQL.PARSE(v_cursor_name, v_unique_cons, dbms_sql.native);
	  	v_rows_processed := dbms_sql.execute(v_cursor_name);
	  	DBMS_SQL.close_cursor(v_cursor_name);
	  END IF;
  
	  --Add the new column 
	  dbms_output.put_line(substr('alter table ' || in_table_name || ' add (' || trim(substr(in_table_name, 1, 27)) || '_id integer)', 1, 255));
	  v_cursor_name := dbms_sql.open_cursor; 
	  DBMS_SQL.PARSE(v_cursor_name,'alter table ' || in_table_name || ' add (' || trim(substr(in_table_name, 1, 27)) || '_id integer)' , dbms_sql.native); 
	  v_rows_processed := dbms_sql.execute(v_cursor_name);
	  DBMS_SQL.close_cursor(v_cursor_name);

	  --Update all the rows.. 
	  v_cursor_name := dbms_sql.open_cursor; 
	  DBMS_SQL.PARSE(v_cursor_name,'update ' || in_table_name || ' set ' || trim(substr(in_table_name, 1, 27)) || '_id=' || in_sequence_name || '.nextval', dbms_sql.native); 
	  v_rows_processed := dbms_sql.execute(v_cursor_name);
	  DBMS_SQL.close_cursor(v_cursor_name);


	  --Make it a primary key
	  v_cursor_name := dbms_sql.open_cursor; 
	  DBMS_SQL.PARSE(v_cursor_name, 'alter table ' || in_table_name || ' add constraint ' ||trim( substr(in_table_name, 1,27)) || '_pk PRIMARY KEY(' || trim(substr(in_table_name, 1, 27)) || '_id)', dbms_sql.native); 
	  v_rows_processed := dbms_sql.execute(v_cursor_name);
	  DBMS_SQL.close_cursor(v_cursor_name);


	  --Restore all references to the old columns
	  --These will be strings containing the proper list of columns for constraints.
	  --We want to make sure that if it is a dual uniqueness, we still reference 
	  --it as such
          
	  IF i-1 > 0 THEN 
	  	v_ref_other_cols := '(' || v_references_cols_list(1);
	  	v_ref_local_cols := '(' || v_col_list(1);	
	  	v_test_var := 0;	  
          	--Loop through them all
	  	FOR j in 2..i-1 LOOP 
			--Is this a new constraint?
			if v_cons_names(j) != v_cons_names(j-1) THEN
				--The we are done with the last one.  Close it off and add it.
			
				v_ref_other_cols := v_ref_other_cols || ')';
				v_ref_local_cols := v_ref_local_cols || ')';
			
				dbms_output.put_line(substr('alter table ' || v_table_list(j-1) || ' add constraint ' || trim(substr(v_table_list(j-1), 1, 27)) || '_fk FOREIGN KEY' || v_ref_local_cols || ' references ' || in_table_name || v_ref_other_cols,1,255));
	  			v_cursor_name := dbms_sql.open_cursor; 
	  			DBMS_SQL.PARSE(v_cursor_name, 'alter table ' || v_table_list(j-1) || ' add constraint ' || trim(substr(v_table_list(j-1), 1, 27)) || '_fk FOREIGN KEY' || v_ref_local_cols || ' references ' || in_table_name || v_ref_other_cols, dbms_sql.native); 
	  			v_rows_processed := dbms_sql.execute(v_cursor_name);
	  			DBMS_SQL.close_cursor(v_cursor_name);
		
				IF j != i-1 THEN 
				 	v_ref_other_cols := '(' || v_references_cols_list(j);
				  	v_ref_local_cols := '(' || v_col_list(j);	
				ELSE
					v_ref_local_cols:= '';
					v_ref_other_cols:= '';
				END IF;
			ELSE
				v_ref_other_cols := v_ref_other_cols || ', ' ||  v_col_list(j);
				v_ref_local_cols := v_ref_local_cols || ', ' || v_references_cols_list(j);
	  		END IF;
			v_test_var :=1;
	   	END LOOP;
	   	-- We should end up with an unfinished constraint... 
	   	-- So lets add it
	   	-- Close off the lists


	   	--Make sure we actually have constraints..
	   	IF v_ref_other_cols != '' THEN
		   v_ref_other_cols := v_ref_other_cols || ')';
		   v_ref_local_cols := v_ref_local_cols || ')';
		   dbms_output.put_line(substr('alter table ' || v_table_list(i-1) || ' add constraint ' || trim(substr(v_table_list(i-1), 1, 27)) || '_fk FOREIGN KEY' || v_ref_local_cols || ') references ' || in_table_name || v_ref_other_cols, 1, 255));
		  v_cursor_name := dbms_sql.open_cursor; 
		  DBMS_SQL.PARSE(v_cursor_name, 'alter table ' || v_table_list(i-1) || ' add constraint ' || trim(substr(v_table_list(i-1), 1, 27)) || '_fk FOREIGN KEY' || v_ref_local_cols || ' references ' || in_table_name ||v_ref_other_cols , dbms_sql.native); 
		  v_rows_processed := dbms_sql.execute(v_cursor_name);
		  DBMS_SQL.close_cursor(v_cursor_name);
	    	END IF;
	     END IF;
	ELSE
		--Error!
		dbms_output.put_line('EITHER YOUR TABLE OR SEQUENCE DOES NOT EXIST!');
	END IF;	
END;
/
show errors;


--Begin upgrading of tables...
--We only change the ones relevant to WP backup..

create sequence user_group_types_seq;
begin
change_to_integer_key('USER_GROUP_TYPES', 'USER_GROUP_TYPES_SEQ');
end;
/

create sequence wp_style_images_seq;
begin 
change_to_integer_key('WP_STYLE_IMAGES', 'WP_STYLE_IMAGES_SEQ');
end;
/

create sequence wp_checkpoints_seq;
begin 
change_to_integer_key('WP_CHECKPOINTS', 'WP_CHECKPOINTS_SEQ');
end;
/


create sequence wp_historical_sort_seq;
begin 
change_to_integer_key('WP_HISTORICAL_SORT', 'WP_HISTORICAL_SORT_SEQ');
end;
/

-- We don't need this procedure anymore... it was just for the upgrade.
drop procedure change_to_integer_key;


--We also need to fix a single PL/SQL function (from /doc/sql/wp.sql):
create or replace procedure wp_set_checkpoint
  (v_presentation_id IN wp_presentations.presentation_id%TYPE,
   v_description IN wp_checkpoints.description%TYPE)
is
  latest_checkpoint wp_checkpoints.checkpoint%TYPE;
begin
  select max(checkpoint) into latest_checkpoint
    from  wp_checkpoints
    where presentation_id = v_presentation_id;
  update wp_checkpoints
    set   description = v_description, checkpoint_date = sysdate
    where presentation_id = v_presentation_id
    and   checkpoint = latest_checkpoint;
  insert into wp_checkpoints(presentation_id, checkpoint,wp_checkpoints_id)
    values(v_presentation_id, latest_checkpoint + 1, wp_checkpoints_seq.nextval);
  -- Save sort order.
  insert into wp_historical_sort(slide_id, presentation_id, checkpoint, sort_key, wp_historical_sort_id)
    select slide_id, v_presentation_id, latest_checkpoint, sort_key, wp_historical_sort_seq.nextval
    from   wp_slides
    where  presentation_id = v_presentation_id
    and    max_checkpoint is null;
end;
/
show errors

-- Now was that nasty, or what?  But its pretty cool
-- and useful
-- Kevin Schmidt
-- END WIMPYPOINT BACKUP UPGRADES --



-- BEGIN ADDRESS-BOOK --

-- It looks xke@arsdigita.com slipped a datamodel change into
-- address-book but did not record it in any upgrade script.  If you
-- loaded the ACS 3.4.0 datamodel into a clean database this will all
-- be defined.  Otherwise you can un-comment the following to have it
-- installed as part of the upgrade.

-- create table address_book_viewable_columns (
--       column_name  varchar(100) primary key,
--       -- for when the column name results from an "as" command
--       -- for ex., you can customize viewing columns
--       extra_select varchar(4000),
--       pretty_name  varchar(4000) not null,
--       sort_order   integer not null
--);

-- default columns already in other tables

-- insert into address_book_viewable_columns values ('first_names', '', 'First Name', 1);
-- insert into address_book_viewable_columns values ('last_name', '', 'Last Name',2);

-- linked email addresses
-- insert into address_book_viewable_columns values ('email', '''<a href="mailto:''||email||''">''||email||''</a>''', 'Email', 3);
-- insert into address_book_viewable_columns values ('email2', '''<a href="mailto:''||email2||''">''||email2||''</a>''', 'Email(2)', 4);
-- insert into address_book_viewable_columns values ('address', 'line1||''<br>''||line2', 'Address', 5);
-- insert into address_book_viewable_columns values ('city', '', 'City', 6);
-- insert into address_book_viewable_columns values ('usps_abbrev', '', 'State', 7);

-- using "decode" so that if usps_abbreb is null, then do not display the comma
-- insert into address_book_viewable_columns values ('city_state', 'city||decode(usps_abbrev, NULL,'''', '', '' || usps_abbrev)', 'City, State', 8);
-- insert into address_book_viewable_columns values ('zip_code', '', 'Zip Code', 9);
-- insert into address_book_viewable_columns values ('phone_home', '', 'Home Phone', 10);
-- insert into address_book_viewable_columns values ('phone_work', '', 'Work Phone', 11);
-- insert into address_book_viewable_columns values ('phone_cell', '', 'Cell Phone', 12);
-- insert into address_book_viewable_columns values ('phone_other', '', 'Other Phone', 13);
-- insert into address_book_viewable_columns values ('country', '', 'Country', 14);
-- again, use decode to not display anything if no values entered
-- insert into address_book_viewable_columns values ('birthdate', 'birthmonth||decode(birthday, null, '''',''/''||birthday)||decode(birthyear, null, '''',''/''||birthyear)', 'Birth Date', 15);

-- insert into address_book_viewable_columns values ('birthmonth', '', 'Birth Month', 16);
-- insert into address_book_viewable_columns values ('birthyear', '', 'Birth Year', 17);
-- insert into address_book_viewable_columns values ('birthday', '', 'Birth Day', 18);
-- insert into address_book_viewable_columns values ('notes', '', 'Notes', 19);

-- END ADDRESS-BOOK --
