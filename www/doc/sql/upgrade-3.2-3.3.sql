-- /www/doc/sql/upgrade-3.2-3.3.sql
--
-- Script to upgrade an ACS 3.2 database to ACS 3.3
--
-- upgrade-3.2-3.3.sql,v 3.45 2000/05/30 22:45:09 jsc Exp

-- begin download

-- add the availability column and set it to 'req_registration' for all rules.

alter table download_rules add
	-- who is allowed to download the files?
	availability	varchar(30) check (availability in 
			   ('all', 'registered_users', 'purchasers',
   			    'group_members', 'previous_purchasers'));

update download_rules set availability = 'registered_users';

-- PL/SQL proc
-- returns 'authorized' if a user can view a file, 'not authorized' otherwise.
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_viewable_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_visibility download_rules.visibility%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select visibility into v_visibility
	from   download_rules
	where  version_id = v_version_id;
	
	if v_visibility = 'all' 
	then	
		return 'authorized';
	elsif v_visibility = 'group_members' then	

		select group_id into v_group_id
		from   downloads d, download_versions dv
		where  dv.version_id  = v_version_id
		and    dv.download_id = d.download_id;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from   user_group_map 
                where  user_id  = v_user_id 
		and    group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from   users 
  	        where  user_id = v_user_id;

		return v_return_value;
	end if; 

     END download_viewable_p;
/
show errors

-- PL/SQL proc
-- returns 'authorized' if a user can download, 'not authorized' if not 
-- if supplied user_id is NULL, this is an unregistered user and we 
-- look for rules accordingly

create or replace function download_authorized_p (v_version_id IN integer, v_user_id IN integer)
     return varchar2
     IS 
	v_availability download_rules.availability%TYPE;
	v_group_id downloads.group_id%TYPE;
	v_return_value varchar(30);
     BEGIN
	select availability into v_availability
	from   download_rules
	where  version_id = v_version_id;
	
	if v_availability = 'all' 
	then	
		return 'authorized';
	elsif v_availability = 'group_members' then	

		select group_id into v_group_id
		from   downloads d, download_versions dv
		where  dv.version_id  = v_version_id
		and    dv.download_id = d.download_id;

		select decode(count(*),0,'not_authorized','authorized') into v_return_value
		from   user_group_map 
		where  user_id  = v_user_id 
		and    group_id = v_group_id;
	
		return v_return_value;		
	else
		select decode(count(*),0,'reg_required','authorized') into v_return_value
		from   users 
		where  user_id = v_user_id;
		
		return v_return_value;
	end if; 

     END download_authorized_p;
/
show errors
	
	
-- BEGIN SPAM --
alter table daily_spam_files add (	
	day_of_week		integer,
	day_of_month		integer,
	day_of_year		integer);

alter table spam_history add (
        cc_emails		varchar(4000)
);
-- END SPAM --


-- BEGIN INTRANET --

alter table im_projects add requires_report_p       char(1) default('t')
		            constraint im_project_requires_report_p check (requires_report_p in ('t','f'));
-- update it to take us back to the original state
update im_projects set requires_report_p='f' where parent_id is not null;

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

-- generalize table names used in general comments
update general_comments set on_which_table = 'user_groups' where on_which_table in ('im_customers','im_partners','im_projects');


alter table im_employee_info add (
    	referred_by_recording_user  	integer references users,
	experience_id			integer references categories,
	source_id			integer references categories,		
	original_job_id			integer references categories,
	current_job_id			integer references categories,
	qualification_id		integer references categories,
	department_id			integer references categories,
	termination_reason		varchar(4000),
        recruiting_blurb clob,
        recruiting_blurb_html_p char(1) default 'f'
              constraint recruiting_blurb_html_p_con check (recruiting_blurb_html_p in ('t','f'))

);

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


alter table im_offices add (
    office_type varchar(20) default 'office'
        constraint im_offices_office_type_ck check (office_type in ('office','facility','housing'))
);


-- returns a list of all the groups a user is in, separated by
-- commas
 
Create or replace function group_names_of_user (
	v_user_id IN Integer) Return varchar2 IS
	   counter integer;
	   return_string 	varchar(2000);
	CURSOR c_user_groups is
		select group_name
		from user_groups, user_group_map
		where user_groups.group_id = user_group_map.group_id
		and user_group_map.user_id = v_user_id;
BEGIN
	counter := 0;
	for v_group_data in c_user_groups LOOP
		counter := counter + 1;
		if counter = 1 then				
			return_string := v_group_data.group_name;
		else
			return_string := return_string || ', ' || v_group_data.group_name;
		end if;
	End Loop;
	Return return_string;
END;
/
show errors

-- returns a list of all the groups a user is in, separated by
-- commas 
create or replace function group_names_of_user_by_type ( p_user_id IN Integer, p_group_type IN varchar) 
Return varchar2 IS
	   v_counter integer;
	   v_return_string 	varchar(2000);
	CURSOR c_user_groups is
           select group_name
	     from user_groups, user_group_map
	    where user_groups.group_id = user_group_map.group_id
	      and user_groups.group_type = p_group_type
	      and user_group_map.user_id = p_user_id;
BEGIN
	v_counter := 0;
	for v_group_data in c_user_groups LOOP
		v_counter := v_counter + 1;
		if v_counter = 1 then				
			v_return_string := v_group_data.group_name;
		else
			v_return_string := v_return_string || ', ' || v_group_data.group_name;
		end if;
	End Loop;
	Return v_return_string;
END;
/
show errors


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

-- allows us to track allocation assignments that we don't expect to
-- take a lot of time

alter table im_allocations add (
	too_small_to_give_percentage_p   char(1) default 'f' check (too_small_to_give_percentage_p in ('t','f')));

alter table im_employee_info add (voluntary_termination_p		char(1) default 'f'
              constraint iei_voluntary_termination_p_ck check (voluntary_termination_p in ('t','f')));

-- we need to store answers to the question "how did you hear about us?"
alter table im_customers add (referral_source varchar(1000));
alter table im_partners  add (referral_source varchar(1000));


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


-- need to quickly find percentage_time for a given start_block/user_id
create unique index im_employee_perc_time_idx on im_employee_percentage_time (start_block, user_id, percentage_time);


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

-- END INTRANET --

-- BEGIN INTRANET: use categories

-- we don't want these categories showing up in the user interests list
alter table categories modify enabled_p default 'f';

alter table im_customers add new_customer_status_id integer;
alter table im_customers add new_old_customer_status_id integer;
alter table im_customers add new_customer_type_id integer;
alter table im_partners add new_partner_status_id integer;
alter table im_partners add new_partner_type_id integer;
alter table im_projects add new_project_status_id integer;
alter table im_projects add new_project_type_id integer;

-- migrate entries in im_customer_status to categories

declare
 cursor c1 is 
  select * from im_customer_status;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.customer_status, 'Intranet Customer Status', 'f');

  update im_customers set new_customer_status_id = catid
  where customer_status_id = rec.customer_status_id;

  update im_customers set new_old_customer_status_id = catid
  where old_customer_status_id = rec.customer_status_id;
 end loop;
end;
/

-- migrate entries in im_customer_types to categories
declare
 cursor c1 is 
  select * from im_customer_types;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.customer_type, 'Intranet Customer Type', 'f');

  update im_customers set new_customer_type_id = catid
  where customer_type_id = rec.customer_type_id;
 end loop;
end;
/

-- migrate entries in im_partner_status to categories
declare
 cursor c1 is 
  select * from im_partner_status;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.partner_status, 'Intranet Partner Status', 'f');

  update im_partners set new_partner_status_id = catid
  where partner_status_id = rec.partner_status_id;
 end loop;
end;
/

-- migrate entries in im_partner_types to categories
declare
 cursor c1 is 
  select * from im_partner_types;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.partner_type, 'Intranet Partner Type', 'f');

  update im_partners set new_partner_type_id = catid
  where partner_type_id = rec.partner_type_id;
 end loop;
end;
/

-- migrate entries in im_project_status to categories
declare
 cursor c1 is 
  select * from im_project_status;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.project_status, 'Intranet Project Status', 'f');

  update im_projects set new_project_status_id = catid
  where project_status_id = rec.project_status_id;
 end loop;
end;
/

-- migrate entries in im_project_types to categories
declare
 cursor c1 is 
  select * from im_project_types;
 catid integer;
begin
 for rec in c1 loop
  select category_id_sequence.nextval into catid from dual;
  insert into categories (category_id, category, category_type, enabled_p)
  values (catid, rec.project_type, 'Intranet Project Type', 'f');

  update im_projects set new_project_type_id = catid
  where project_type_id = rec.project_type_id;
 end loop;
end;
/

-- drop the foreign-key constraints 
-- this ought to teach us to name our constraints!

declare
 cursor customer_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'IM_CUSTOMERS' and 
  column_name in ('CUSTOMER_TYPE_ID', 'CUSTOMER_STATUS_ID', 'OLD_CUSTOMER_STATUS_ID');
 v_sql_stmt varchar(400);
begin
 for cc in customer_constraints loop
  v_sql_stmt := 'alter table im_customers drop constraint ' || cc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

declare
 cursor partner_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'IM_PARTNERS' and 
  column_name in ('PARTNER_TYPE_ID', 'PARTNER_STATUS_ID');
 v_sql_stmt varchar(400);
begin
 for pc in partner_constraints loop
  v_sql_stmt := 'alter table im_partners drop constraint ' || pc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

-- these columns have check constraints (for not null) in addition to fk reference constraints
declare
 cursor project_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'IM_PROJECTS' and 
  column_name in ('PROJECT_TYPE_ID', 'PROJECT_STATUS_ID');
 v_sql_stmt varchar(400);
begin
 for pc in project_constraints loop
  v_sql_stmt := 'alter table im_projects drop constraint ' || pc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

update im_customers set customer_type_id = new_customer_type_id;
update im_customers set customer_status_id = new_customer_status_id;
update im_customers set old_customer_status_id = new_old_customer_status_id;
update im_partners set partner_type_id = new_partner_type_id;
update im_partners set partner_status_id = new_partner_status_id;
update im_projects set project_type_id = new_project_type_id;
update im_projects set project_status_id = new_project_status_id;

alter table im_customers drop column new_customer_status_id;
alter table im_customers drop column new_old_customer_status_id;
alter table im_customers drop column new_customer_type_id;
alter table im_partners drop column new_partner_status_id;
alter table im_partners drop column new_partner_type_id;
alter table im_projects drop column new_project_status_id;
alter table im_projects drop column new_project_type_id;

alter table im_customers add constraint customers_type_fk 
 foreign key (customer_type_id) references categories;

alter table im_customers add constraint customers_status_fk 
 foreign key (customer_status_id) references categories;

alter table im_customers add constraint customers_old_status_fk 
 foreign key (old_customer_status_id) references categories;

alter table im_partners add constraint partners_type_fk
 foreign key (partner_type_id) references categories;

alter table im_partners add constraint partners_status_fk
 foreign key (partner_status_id) references categories;

alter table im_projects add constraint projects_type_fk
 foreign key (project_type_id) references categories;

alter table im_projects add constraint projects_status_fk
 foreign key (project_status_id) references categories;

alter table im_projects add constraint projects_type_nnull 
 check(project_type_id is not null);

alter table im_projects add constraint projects_status_nnull 
 check(project_status_id is not null);

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

drop table im_project_status;
drop table im_project_types;
drop table im_customer_status;
drop table im_customer_types;
drop table im_partner_status;
drop table im_partner_types;

-- views on intranet categories to make queries cleaner

create view im_project_status as 
select category_id as project_status_id, category as project_status
from categories 
where category_type = 'Intranet Project Status';

create view im_project_types as
select category_id as project_type_id, category as project_type
from categories
where category_type = 'Intranet Project Type';

create view im_customer_status as 
select category_id as customer_status_id, category as customer_status
from categories 
where category_type = 'Intranet Customer Status';

create view im_customer_types as
select category_id as customer_type_id, category as customer_type
from categories
where category_type = 'Intranet Customer Type';

create view im_partner_status as 
select category_id as partner_status_id, category as partner_status
from categories 
where category_type = 'Intranet Partner Status';

create view im_partner_types as
select category_id as partner_type_id, category as partner_type
from categories
where category_type = 'Intranet Partner Type';

create view im_prior_experiences as
select category_id as experience_id, category as experience
from categories
where category_type = 'Intranet Prior Experience';

create view im_hiring_sources as
select category_id as source_id, category as source
from categories
where category_type = 'Intranet Hiring Source';

create view im_job_titles as
select category_id as job_title_id, category as job_title
from categories
where category_type = 'Intranet Job Title';

create view im_departments as
select category_id as department_id, category as department
from categories
where category_type = 'Intranet Department';

create view im_qualification_processes as
select category_id as qualification_id, category as qualification
from categories
where category_type = 'Intranet Qualification Process';

create view im_annual_revenue as
select category_id as revenue_id, category as revenue
from categories
where category_type = 'Intranet Annual Revenue';

create view im_employee_pipeline_states as
select category_id as state_id, category as state
from categories
where category_type = 'Intranet Employee Pipeline State';


alter table im_customers add annual_revenue integer;
alter table im_customers add constraint cust_revenue_fk
  foreign key (annual_revenue) references categories;

alter table im_partners add annual_revenue integer;
alter table im_partners add constraint part_revenue_fk
  foreign key (annual_revenue) references categories;

-- END INTRANET: use categories


-- BEGIN EDUCATION --

-- fixes to triggers that did not quite work in the 
-- first release

drop table edu_role_change_state_info;
drop trigger edu_role_before_update_tr;

CREATE OR REPLACE TRIGGER edu_class_role_update_tr
AFTER UPDATE OF role ON user_group_roles
FOR EACH ROW
BEGIN
	-- we want to update the existing row
	update edu_role_pretty_role_map
        set role = :new.role
	where group_id = :new.group_id
        and role = :old.role;

END;
/
show errors



CREATE OR REPLACE TRIGGER edu_class_role_delete_tr
BEFORE DELETE ON user_group_roles
FOR EACH ROW
BEGIN
	delete from edu_role_pretty_role_map 
	where group_id = :old.group_id
        and role = :old.role;
END;
/
show errors


CREATE OR REPLACE TRIGGER edu_class_role_insert_tr
AFTER INSERT ON user_group_roles
FOR EACH ROW
DECLARE
	v_class_p	integer;
BEGIN
	select count(group_id) into v_class_p
	from user_groups
	where group_type = 'edu_class'
        and group_id = :new.group_id;

	IF v_class_p > 0 THEN

		insert into edu_role_pretty_role_map (
        	       group_id, 
	               role, 
        	       pretty_role,
                       pretty_role_plural, 
	               sort_key,
                       priority) 
        	    select
	               :new.group_id, 
  		       :new.role, 
		       :new.role, 
                       :new.role || 's',
    		       nvl(max(sort_key),0) + 1,
    		       nvl(max(priority),0) + 1
	             from edu_role_pretty_role_map
        	    where group_id = :new.group_id;
	END IF;
END;
/
show errors



-- update edu_subjects

alter table edu_student_answers add team_id references user_groups;

alter table edu_subjects add(description_html_p	char(1) default 'f' constraint edu_sub_desc_html_p_ck check(description_html_p in ('t','f')));

update edu_subjects set description_html_p = 'f';

alter table edu_subjects_audit add(description_html_p char(1));

insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
values
('edu_class', 'description_html_p', 'Description HTML?', 'boolean', 'char(1)', 'default ''f'' check(description_html_p in (''t'',''f''))', 17);


create or replace trigger edu_subjects_audit_trigger
before update or delete on edu_subjects
for each row
begin
   insert into edu_subjects_audit (
	subject_id,
	subject_name,
	description,
	description_html_p,
	credit_hours,
	prerequisites,
	professors_in_charge,
	last_modified,
        last_modifying_user,
        modified_ip_address)
   values (
	:old.subject_id,
	:old.subject_name,
	:old.description,
	:old.description_html_p,
	:old.credit_hours,
	:old.prerequisites,
	:old.professors_in_charge,
	:old.last_modified,
        :old.last_modifying_user,
        :old.modified_ip_address);
end;
/
show errors	




alter table edu_class_info add(description_html_p char(1) default 'f' constraint edu_class_desc_html_p_ck check(description_html_p in ('t','f')));

update edu_class_info set description_html_p = 'f';

alter table edu_class_info_audit add(description_html_p char(1));

create or replace view edu_current_classes
as
select
	user_groups.group_id as class_id,
	group_name as class_name,
	edu_class_info.term_id,
	subject_id,
	edu_class_info.start_date,
	edu_class_info.end_date,
	description,
	description_html_p,
	where_and_when,
	syllabus_id,
	lecture_notes_folder_id,
	handouts_folder_id,
	assignments_folder_id,
	projects_folder_id,
	exams_folder_id,
	public_p,
	grades_p,
	teams_p,
	exams_p,
	final_exam_p
from user_groups, edu_class_info
where user_groups.group_id = edu_class_info.group_id
and group_type = 'edu_class'
and active_p = 't'
and existence_public_p='t'
and approved_p = 't'
and sysdate<edu_class_info.end_date
and sysdate>=edu_class_info.start_date;

create or replace view edu_classes
as
select
	user_groups.group_id as class_id,
	group_name as class_name,
	edu_class_info.term_id,
	subject_id,
	edu_class_info.start_date,
	edu_class_info.end_date,
	description,
	description_html_p,
	where_and_when,
	syllabus_id,
	lecture_notes_folder_id,
	handouts_folder_id,
	assignments_folder_id,
	projects_folder_id,
	exams_folder_id,
	public_p,
	grades_p,
	teams_p,
	exams_p,
	final_exam_p
from user_groups, edu_class_info
where user_groups.group_id = edu_class_info.group_id
and group_type = 'edu_class'
and active_p = 't'
and existence_public_p='t'
and approved_p = 't';


create or replace trigger edu_class_info_audit_trigger
before update or delete on edu_class_info
for each row
begin
   insert into edu_class_info_audit (
	group_id,		
	term_id,			
	subject_id,		
	start_date,		
	end_date,		
	description, 		
	description_html_p, 		
	where_and_when,		
	syllabus_id,		
	assignments_folder_id,	
	projects_folder_id,	
	lecture_notes_folder_id, 
	handouts_folder_id,	
	exams_folder_id,		
	public_p,		
	grades_p,  		
	teams_p,			
	exams_p,                 
	final_exam_p,            
	last_modified,          	
        last_modifying_user,     
        modified_ip_address)
    values (
	:old.group_id,		
	:old.term_id,			
	:old.subject_id,		
	:old.start_date,		
	:old.end_date,		
	:old.description, 		
	:old.description_html_p, 		
	:old.where_and_when,		
	:old.syllabus_id,		
	:old.assignments_folder_id,	
	:old.projects_folder_id,	
	:old.lecture_notes_folder_id, 
	:old.handouts_folder_id,	
	:old.exams_folder_id,		
	:old.public_p,		
	:old.grades_p,  		
	:old.teams_p,			
	:old.exams_p,                 
	:old.final_exam_p,            
	:old.last_modified,          	
        :old.last_modifying_user,     
        :old.modified_ip_address);
end;
/
show errors


alter table edu_class_info modify (
	subject_id integer constraint edu_class_info_subject_nn not null,
	term_id integer constraint edu_class_info_term_id_nn not null
);


create or replace view edu_terms_current
as
select
  term_id,
  term_name,
  start_date,
  end_date
from edu_terms 
where start_date < sysdate
  and end_date > sysdate;



create table edu_task_instances  (
	task_instance_id 	integer not null primary key,
	task_instance_name	varchar(200),
	task_instance_url	varchar(500),
	-- which task is this an instance of?
	task_id		integer not null references edu_student_tasks,
	description		varchar(4000),
	approved_p		char(1) default 'f' check(approved_p in ('t','f')),
        approved_date           date,
        approving_user          references users(user_id),
	-- we want to be able to generate a consistent user interface so
	-- we record the type of task.
	-- (aileen 4/00) renamed this from task_type because task_type is
	-- a reserved column name in edu_student_tasks  
	team_or_user 		varchar(10) default 'team' check(team_or_user in ('user','team')),
	min_body_count		integer,
	max_body_count		integer,
	-- we want to be able to "delete" task instances so we have active_p
	active_p		char(1) default 't' check(active_p in ('t','f'))
);


-- we want to be able to assign students and teams to tasks
-- we use an index instead of a multi-column primary key because
-- team_id and student_id an both be null

create table edu_task_user_map (
	task_instance_id	integer not null references edu_task_instances,
	team_id			integer references user_groups,
	student_id		integer references users,
	constraint edu_task_user_map_check check ((team_id is null and student_id is not null) or (team_id is not null and student_id is null))
);


--- END EDUCATION ---




--------------------------------------------------
--- START EVENTS ---
alter table event_info add(contact_user_id integer references users);

insert into user_group_type_fields 
(group_type, column_name, pretty_name, column_type, 
column_actual_type, sort_key)
values
('event', 'contact_user_id', 'Event Contact Person', 'integer', 'integer', 1);

-- create default contact users for each existing event
create or replace procedure event_contact_create
IS
	i_group_count		integer;

	cursor c1 is
	select event_id, group_id, creator_id
	from events_events;
BEGIN
	FOR e in c1 LOOP
	    -- check if this group_id already has a user
	    select count(group_id) into i_group_count
	    from event_info
	    where group_id = e.group_id;

	    IF i_group_count = 0 THEN
	       -- insert if there isn't a row for this group
	       INSERT into event_info
	       (group_id, contact_user_id)
	       VALUES
	       (e.group_id, e.creator_id);
	    ELSE
	       --update if there is a row
	       UPDATE event_info
	       set contact_user_id = e.creator_id
	       where group_id = e.group_id
	       ;
	    END IF;
	END LOOP;
END event_contact_create;
/
show errors;

execute event_contact_create();

drop procedure event_contact_create;

-- edit events_activities to support default contact person
alter table events_activities add(default_contact_user_id integer references users);

-- add more info the the venues data model
alter table events_venues add(fax_number varchar(30));
alter table events_venues add(phone_number varchar(30));
alter table events_venues add(email varchar(100));

-- change the administration url for events to /events/admin/
update administration_info set url = '/events/admin/' where url =
'/admin/events/';


-- change max_people in events_venues to be an integer
create table tmp_events_venues (
       venue_id		 integer,
       max_people	 number
);

insert into tmp_events_venues (venue_id, max_people)
select venue_id, max_people from events_venues where max_people is not null;

alter table events_venues drop column max_people;
alter table events_venues add(max_people integer);

create or replace procedure event_venues_num_to_int
IS
	cursor c1 is
	select venue_id as venue_id, 
	round(max_people) as max_people
	from tmp_events_venues;
BEGIN
	FOR e in c1 LOOP
	    update events_venues set max_people = e.max_people
	    where venue_id = e.venue_id;
	END LOOP;
END event_venues_num_to_int;
/
show errors;

execute event_venues_num_to_int();
drop procedure event_venues_num_to_int;
drop table tmp_events_venues;


-- change max_people in events_events to be an integer
create table tmp_events_events (
       event_id		 integer,
       max_people	 number
);

insert into tmp_events_events (event_id, max_people)
select event_id, max_people from events_events where max_people is not null;

alter table events_events drop column max_people;
alter table events_events add(max_people integer);

create or replace procedure event_events_num_to_int
IS
	cursor c1 is
	select event_id as event_id, 
	round(max_people) as max_people
	from tmp_events_events;
BEGIN
	FOR e in c1 LOOP
	    update events_events set max_people = e.max_people
	    where event_id = e.event_id;
	END LOOP;
END event_events_num_to_int;
/
show errors;

execute event_events_num_to_int();
drop procedure event_events_num_to_int;
drop table tmp_events_events;

-- normalize event organizers and their roles
create table tmp_events_organizers_map (
       event_id		      integer not null references events_events,  
       user_id		      integer not null references users,
       role		      varchar(200) default 'organizer' not null,
       responsibilities	      clob
);
insert into tmp_events_organizers_map (event_id, user_id, role,
responsibilities)
select event_id, user_id, role, responsibilities from events_organizers_map;

drop table events_organizers_map;

-- create default organizer roles for an activity
create sequence events_activity_org_roles_seq start with 1;
create table events_activity_org_roles (
       role_id			integer 
				constraint evnt_act_org_roles_role_id_pk 
				primary key ,
       activity_id		integer 
				constraint evnt_act_role_activity_id_fk 
				references events_activities
				constraint evnt_act_role_activity_id_nn
				not null,  
       role			varchar(200) 
				constraint evnt_act_org_roles_role_nn
				not null,
       responsibilities		clob,
       -- is this a role that we want event registrants to see?
       public_role_p		char(1) default 'f' 
				constraint evnt_act_role_public_role_p
				check (public_role_p in ('t', 'f'))
);

-- create actual organizer roles for each event
create sequence events_event_org_roles_seq start with 1;
create table events_event_organizer_roles (
       role_id			integer 
				constraint evnt_ev_org_roles_role_id_pk 
				primary key,
       event_id			integer 
				constraint evnt_ev_org_roles_event_id_fk 
				references events_events
				constraint evnt_ev_org_roles_event_id_nn
				not null,  
       role			varchar(200) 
				constraint evnt_ev_org_roles_role_nn
				not null,
       responsibilities		clob,
       -- is this a role that we want event registrants to see?
       public_role_p		char(1) default 'f' 
				constraint evnt_ev_roles_public_role_p
				check (public_role_p in ('t', 'f'))
);

create table events_organizers_map (
       user_id			   constraint evnt_org_map_user_id_nn
				   not null
				   constraint evnt_org_map_user_id_fk
				   references users,
       role_id			   integer 
				   constraint evnt_org_map_role_id_nn
				   not null 
				   constraint evnt_org_map_role_id_fk
				   references events_event_organizer_roles,
       constraint events_org_map_pk primary key (user_id, role_id)
);

-- create a view to see event organizer roles and the people in those roles
create or replace view events_organizers 
as
select eor.*, eom.user_id
from events_event_organizer_roles eor, events_organizers_map eom
where eor.role_id=eom.role_id(+);

create or replace procedure event_copy_organizers
IS
	i_role_id	integer;
	i_group_id	integer;
	cursor c1 is
	select event_id, user_id, role, responsibilities
	from tmp_events_organizers_map;
BEGIN
	FOR e in c1 LOOP
	    select events_event_org_roles_seq.nextval into i_role_id from dual;

	    -- create the appropriate role
	    insert into events_event_organizer_roles
	    (role_id, event_id, role, responsibilities)
	    values
	    (i_role_id, e.event_id, e.role, e.responsibilities);

	    -- assign the user his role
	    insert into events_organizers_map
	    (user_id, role_id)
	    values
	    (e.user_id, i_role_id);

	    -- add this user and his role into the event's user group
	    select group_id into i_group_id 
	    from events_events 
	    where event_id = e.event_id;

	    insert into user_group_map
	    (group_id, user_id, role, registration_date,
	    mapping_user, mapping_ip_address)
	    values
	    (i_group_id, e.user_id, e.role, sysdate, 1, 
	    'EVENTS 3.2->3.3 UPGRADE SCRIPT');
	END LOOP;
END event_copy_organizers;
/
show errors;


execute event_copy_organizers;
drop procedure event_copy_organizers;
drop table tmp_events_organizers_map;

--- END EVENTS ---
--------------------------------------------------

--- BEGIN MONITORING ---
@monitoring.sql
--- END MONITORING ---


--- BEGIN BBOARD ---

-- add an explicit not null constraint on bboard(one_line)
update bboard set one_line = 'BBoard Posting - ' || posting_time where one_line is null;
alter table bboard modify one_line constraint bboard_one_line_nn not null;

-- Default forums, color, and icon_id for the web service
ALTER TABLE bboard_topics add (
       -- default_topic_p is 't' if the web service admin wants that
       -- topic to be a default bboard forum for users
       default_topic_p            varchar(1) default 't' check (default_topic_p in ('t','f')),
       -- the default color set by the web service admin for
       -- displaying topic summary lines for a forum 
       -- in #XXXXXX format (Hexadecimal)
       color			  varchar(7),
       -- the default icon set by the web service admin for displaying
       -- topic summary lines for the forum 
       icon_id			  integer REFERENCES bboard_icons
);

--
-- bboard_icons contains all icons available to the unified bboard
-- module.
--
CREATE TABLE bboard_icons (
       icon_id			integer NOT NULL PRIMARY KEY,
       -- A short name for the icon (the system will pick a
       -- non-descriptive name if the user doesn't
       icon_name                varchar(25),
       -- Actual filename of the icon.  The path name is in IconDir
       -- under the bboard/unified key in the
       -- parameters/<servername>.ini file 
       icon_file		varchar(250),
       -- The width (in pixels) that the icon will be scaled to
       icon_width		integer,
       -- The height (in pixels) that the icon will be scaled to
       icon_height		integer
);

create sequence icon_id_seq;

--
-- Map users to their customizable unified set of Forums they want to
-- participate in
--
CREATE TABLE bboard_unified (
       user_id		 	 integer NOT NULL REFERENCES users,
       topic_id			 integer NOT NULL REFERENCES bboard_topics,
       -- default_topic_p is 't' if the user wants that topic to be in
       -- his/her unified bboard view
       default_topic_p           varchar(1) DEFAULT 't' CHECK (default_topic_p IN ('t','f')),
       -- the color used to display topic summary lines for the forum,
       -- in #XXXXXX format (Hexadecimal)
       color			 varchar(7),
       -- the icon used in displaying topic summary lines for the forum
       icon_id			 integer REFERENCES bboard_icons
);


--- BEGIN BBOARD ---

--- BEGIN SURVSIMP
--- Add ability to handle blob responses, mostly borrowed from general-comments

alter table survsimp_question_responses add (
	attachment_answer	blob,
	-- file name including extension but not path
	attachment_file_name	varchar(500),
	attachment_file_type	varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	attachment_file_extension varchar(50) 	-- e.g., "jpg"
);

--Yuk, alter the constraint on presentation_type
declare
 cursor presentation_type_constraints is
  select constraint_name from user_cons_columns 
  where table_name = 'SURVSIMP_QUESTIONS' and 
  column_name in ('PRESENTATION_TYPE');
 v_sql_stmt varchar(400);
begin
 for pc in presentation_type_constraints loop
  v_sql_stmt := 'alter table survsimp_questions drop constraint ' || pc.constraint_name;
  execute immediate v_sql_stmt;
 end loop;
end;
/

alter table survsimp_questions add constraint survsimp_questions_pres_type
    check(presentation_type in ('textbox','textarea','select','radio', 'checkbox', 'date', 'upload_file'));

--- END Survey-simple.sql

--- BEGIN GENERAL COMMENTS ---
update table_acs_properties set table_name='news_items' where table_name='news';
update table_acs_properties set user_url_stub='/news/item.tcl?news_item_id=' where table_name='news_items';
update table_acs_properties set admin_url_stub='/news/admin/item.tcl?news_item_id=' where table_name='news_items';
commit;
--- END GENERAL COMMENTS ---


--- BEGIN TICKET ---
update table_acs_properties set user_url_stub='/ticket/issue-view.tcl?msg_id=' where table_name='ticket_issues';
update table_acs_properties set admin_url_stub='/ticket/issue-new.tcl?msg_id=' where table_name='ticket_issues';
update table_acs_properties set user_url_stub='/ticket/issue-view.tcl?msg_id=' where table_name='ticket_issues_i';
update table_acs_properties set admin_url_stub='/ticket/issue-new.tcl?msg_id=' where table_name='ticket_issues_i';
commit;
--- END TICKET ---


--- BEGIN USER GROUPS ---

-- remove the constraint on group_spam_history.send_to

declare
 v_constraint_name      varchar(50);
 v_sql_stmt 		varchar(400);
begin

  v_constraint_name := null;

  BEGIN 
    select constraint_name into v_constraint_name
      from user_cons_columns
     where table_name = 'GROUP_SPAM_HISTORY'
       and column_name = 'SEND_TO';
    exception when others then null;
  END;

  IF v_constraint_name is not null THEN 
    v_sql_stmt := 'alter table group_spam_history drop constraint ' || v_constraint_name;
    execute immediate v_sql_stmt;
  END IF;

end;
/
show errors;

--- END USER GROUPS ---

----  change in group_spam_history to support multi-role spamming

create table group_spam_history_temp (
	spam_id			integer primary key,
	group_id		references user_groups not null,
	sender_id		references users(user_id) not null,
	sender_ip_address	varchar(50) not null,
	from_address		varchar(100),
	subject			varchar(200),
 	body			clob,
	send_to			varchar (4000) default 'all',
	creation_date		date not null,
	-- approved_p matters only for spam policy='wait'
	-- approved_p = 't' indicates administrator approved the mail 
	-- approved_p = 'f' indicates administrator disapproved the mail, so it won't be listed for approval again
	-- approved_p = null indicates the mail is not approved/disapproved by the administrator yet 
	approved_p		char(1) default null check (approved_p is null or approved_p in ('t','f')),
	send_date		date,
	-- this holds the number of intended recipients
	n_receivers_intended	integer default 0,
	-- we'll increment this after every successful email
	n_receivers_actual	integer default 0
);


insert into group_spam_history_temp
	(spam_id,group_id,sender_id,sender_ip_address,from_address, 
	 subject,body,send_to,creation_date,approved_p,send_date,
	 n_receivers_intended,n_receivers_actual)
select   spam_id,group_id,sender_id,sender_ip_address,from_address, 
         subject,body, send_to,creation_date,approved_p,send_date,
         n_receivers_intended,n_receivers_actual
from group_spam_history;

commit;

drop table group_spam_history;
alter table group_spam_history_temp rename to group_spam_history;

----- end change in group_spam_history -------