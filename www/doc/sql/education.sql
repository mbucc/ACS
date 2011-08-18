--
-- /www/doc/sql/education.sql
--
-- by randyg@mit.edu and aileen@mit.edu on September 29, 1999
-- with much help from philg@arsdigita.com on October 28, 1999

-- the system is centered around the classes
-- as it is too difficult to have 2 types of queries to support 
-- individual users

-- instead of having a classes table, we just define a user group
-- type of "edu_class" 

-- for the class name we'll use "group_name" (a default field from
-- the user_groups table); everything else will have to be in
-- edu_class_info; this is a bit tricky since we need to
-- keep the definitions for the helper edu_classes_info table in
-- sync with what we insert into user_group_type_fields (used
-- to generate UI)

-- we don't store much contact info in the classes table; if we need
-- to send out a report on system usage, we send it to all the people
-- with the admin role in this user group


-- this table holds the terms for the classes (e.g. Fall 1999)
 
create sequence edu_term_id_sequence start with 1;

create table edu_terms (
     term_id         integer not null primary key,
     term_name       varchar(100) not null,
     start_date      date not null,
     end_date        date not null
);

-- we want the above table to automatically start with a term that extends over all time
-- (or at least 100 years) for classes that people take at their own pace

insert into edu_terms (term_id, term_name, start_date, end_date) 
select edu_term_id_sequence.nextval, 'No Term', sysdate, add_months(sysdate,1200)
from dual
where 0 = (select count(*) from edu_terms);

-- for a multi-department university, we need to this to sort courses
-- by department; we're going to want private discussion groups, etc. 
-- for people who work in departments, so we make this a user group

-- to find the department head and other big staffers, we look at people with
-- particular roles in the user_group_map

create table edu_department_info (
	group_id 		integer primary key references user_groups,
	-- for schools like MIT where each department has a number
	department_number	varchar(100),
	-- we'll generate a home page for them but if they have one already
	-- we can provide a link
	external_homepage_url	varchar(200),
	mailing_address		varchar(200),
	phone_number		varchar(20),
	fax_number		varchar(20),
	inquiry_email		varchar(50),
	description		clob,
	mission_statement	clob,
	last_modified          	date default sysdate not null,
        last_modifying_user    	references users,
        modified_ip_address    	varchar(20)
);


-- we want to audit the department information

create table edu_department_info_audit (
	group_id 		integer,
	department_number	varchar(100),
	external_homepage_url	varchar(200),
	mailing_address		varchar(200),
	phone_number		varchar(20),
	fax_number		varchar(20),
	inquiry_email		varchar(50),
	description		clob,
	mission_statement	clob,
	last_modified          	date,
        last_modifying_user    	integer,
        modified_ip_address    	varchar(20)
);


-- we create a trigger to keep the audit table current

create or replace trigger edu_department_info_audit_tr
before update or delete on edu_department_info
for each row
begin
   insert into edu_department_info_audit (
	group_id,
	department_number,
	external_homepage_url,
	mailing_address,
	phone_number,
	fax_number,
	inquiry_email,
	description,
	mission_statement,
	last_modified,
        last_modifying_user,
        modified_ip_address)
     values (
	:old.group_id,
	:old.department_number,
	:old.external_homepage_url,
	:old.mailing_address,
	:old.phone_number,
	:old.fax_number,
	:old.inquiry_email,
	:old.description,
	:old.mission_statement,
	:old.last_modified,
        :old.last_modifying_user,
        :old.modified_ip_address);
end;
/
show errors


-- now, lets create a group of type department and insert all of
-- the necessary rows to generate the user interface on the /admin pages

declare	
 n_departments_group_types integer;
begin
 select count(*) into n_departments_group_types from user_group_types where group_type = 'edu_department';
  if n_departments_group_types = 0 then
    insert into user_group_types
    (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration)
    values
   ('edu_department','Department','Departments','wait','open','full');

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'department_number', 'Department Number', 'text', 'varchar(100)', '', 1);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'external_homepage_url', 'External Homepage URL', 'text', 'varchar(200)', '', 2);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'mailing_address', 'Mailing Address', 'text', 'varchar(200)', '', 3);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'phone_number', 'Phone Number', 'text', 'varchar(20)', '', 4);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'fax_number', 'Fax Number', 'text', 'varchar(20)', '', 5);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'inquiry_email', 'Inquiry Email', 'text', 'varchar(50)', '', 6);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'description', 'Description', 'text', 'clob', '', 7);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_department', 'mission_statement', 'Mission Statement', 'text', 'clob', '', 8);

  end if;
end;
/


-- now we want to create a view to easily select departments

create or replace view edu_departments
as
select
	user_groups.group_id as department_id,
	group_name as department_name,
	department_number,
	external_homepage_url,
	mailing_address,
	phone_number,
	fax_number,
	inquiry_email,
	description,
	mission_statement
from user_groups, edu_department_info
where user_groups.group_id = edu_department_info.group_id
and group_type = 'edu_department'
and active_p = 't'
and approved_p = 't';



-- we model the subjects offered by departments

create sequence edu_subject_id_sequence;

-- we don't store the subject number in edu_subjects because a joint subject
-- may have more than one number 

create table edu_subjects (
	subject_id		integer primary key,
	subject_name		varchar(100) not null,
	description		varchar(4000),
	-- at MIT this will be a string like "3-0-9"
	credit_hours		varchar(50),	
	prerequisites		varchar(4000),
	professors_in_charge	varchar(200),
	last_modified          	date default sysdate not null,
        last_modifying_user    	not null references users,
        modified_ip_address    	varchar(20) not null
);


-- we want to audit edu_subjects

create table edu_subjects_audit (
	subject_id		integer,
	subject_name		varchar(100),
	description		varchar(4000),
	credit_hours		varchar(50),	
	prerequisites		varchar(4000),
	professors_in_charge	varchar(200),
	last_modified          	date,
        last_modifying_user    	integer,
        modified_ip_address    	varchar(20)
);


-- we create a trigger to keep the audit table current

create or replace trigger edu_subjects_audit_trigger
before update or delete on edu_subjects
for each row
begin
   insert into edu_subjects_audit (
	subject_id,
	subject_name,
	description,
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
	:old.credit_hours,
	:old.prerequisites,
	:old.professors_in_charge,
	:old.last_modified,
        :old.last_modifying_user,
        :old.modified_ip_address);
end;
/
show errors	



create table edu_subject_department_map (
	department_id		integer references user_groups,
	subject_id		integer references edu_subjects,
	-- this would be the full '6.014' or 'CS 101'
	subject_number		varchar(20),
        grad_p                  char(1) default 'f' check(grad_p in ('t','f')),
	primary key ( department_id, subject_id )
);


-- now we create classes.  A class is a particular subject being taught in a particular
-- term.  However, we can also have special cases where a class is not associated with 
-- a term and we can even have classes that stand by themselves and aren't associated with
-- subjects, e.g., an IAP knitting course  (IAP = MIT's Independent Activities Period)

-- the PL/SQL statement cannot create the table so we do it here.
-- create a table to hold the extra info for each group of type
-- 'edu_classes'

create table edu_class_info (
	group_id		integer not null primary key references user_groups,
	term_id			integer references edu_terms,
	subject_id		integer references edu_subjects,
	-- if the class doesn't start or end on the usual term boundary, fill these in
	start_date		date,
	end_date		date,
	description 		varchar(4000),
	-- at MIT, something like 'Room 4-231, TR 1-2:30'
	where_and_when		varchar(4000),
	-- I still don't agree with this column.  I think we should use
	-- the file system to hold this and just keep a pointer to the 
	-- syllabus.  That way we would have versioning which we do not 
	-- have now (randyg@arsdigita.com, November, 1999)
	syllabus_id		integer references fs_files,
	-- we keep references to the class folders so that we can link to them directly
	-- from various different parts of the system.
	assignments_folder_id		references fs_files,
	projects_folder_id		references fs_files,
	lecture_notes_folder_id		references fs_files,
	handouts_folder_id		references fs_files,
	exams_folder_id			references fs_files,
	-- will the class web page and the documents on it be open to the public?
	public_p			char(1) default 'f' check(public_p in ('t','f')),
	-- do students receive grades?
	grades_p  		        char(1) default 'f' check(grades_p in ('t','f')),
	-- will the class be divided into teams?
	teams_p			 	char(1) default 'f' check(teams_p in ('t','f')),
	exams_p                  	char(1) default 'f' check (exams_p in ('t', 'f')),
	-- does the class have a final exam?
	final_exam_p                	char(1) default 'f' check (final_exam_p in ('t','f')),
	last_modified           	date default sysdate not null,
        last_modifying_user     	references users,
        modified_ip_address     	varchar(20)
);

-- this table audits edu_class_info
create table edu_class_info_audit (
	group_id		integer,
	term_id			integer,
	subject_id		integer,
	start_date		date,
	end_date		date,
	description 		varchar(4000),
	where_and_when		varchar(4000),
	syllabus_id		integer,
	assignments_folder_id	integer,
	projects_folder_id	integer,
	lecture_notes_folder_id integer,
	handouts_folder_id	integer,
	exams_folder_id		integer,
	public_p		char(1),
	grades_p  		char(1),
	teams_p			char(1),
	exams_p                 char(1),
	final_exam_p            char(1),
	last_modified          	date,
        last_modifying_user     integer,
        modified_ip_address     varchar(20)
);



-- we create a trigger to keep the audit table current

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


declare
 n_classes_group_types integer;
begin
 select count(*) into n_classes_group_types from user_group_types where group_type = 'edu_class';
  if n_classes_group_types = 0 then
	insert into user_group_types
  (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration)
  values
  ('edu_class','Class','Classes','wait','open','full');


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'term_id', 'Term Class is Taught', 'text', 'integer', 'not null references edu_terms', 1);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'subject_id', 'Subject', 'text', 'integer', 'not null references edu_subjects', 2);


   insert into user_group_type_fields 
   (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
  ('edu_class', 'start_date', 'Date to Start Displaying Class Web Page', 'date', 'date', '', 3);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'end_date', 'Date to Stop Displaying Class Web Page', 'date', 'date', '', 4);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'description', 'Class Description', 'text', 'varchar(4000)', '', 5);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'where_and_when', 'Where and When', 'text', 'varchar(4000)', '', 6);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'syllabus_id', 'Syllabus ID', 'integer', 'integer', 'references fs_files', 7);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'assignments_folder_id', 'Assignments Folder', 'integer', 'integer', 'references fs_files', 8);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'projects_folder_id', 'Projects Folder', 'integer', 'integer', 'references fs_files', 8.5);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'lecture_notes_folder_id', 'Lecture Notes Folder', 'integer', 'integer', 'references fs_files', 9);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'handouts_folder_id', 'Handouts Folder', 'integer', 'integer', 'references fs_files', 10);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'public_p', 'Will the web page be open to the public?', 'boolean', 'char(1)', 'default ''t'' check(public_p in (''t'',''f''))', 11);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'grades_p', 'Do students recieve grades?', 'boolean', 'char(1)','default ''f'' check(grades_p in (''t'',''f''))', 12);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'teams_p', 'Will the class be divided into teams?', 'boolean', 'char(1)','default ''f'' check(teams_p in (''t'',''f''))', 13);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'exams_p', 'Will the class have exams?', 'boolean', 'char(1)','default ''f'' check(exams_p in (''t'',''f''))', 14);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'final_exam_p', 'Will the class have a final exam?', 'boolean', 'char(1)','default ''f'' check(final_exam_p in (''t'',''f''))', 15);

   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_class', 'exams_folder_id', 'Exams Folder', 'integer', 'integer', 'references fs_files', 16);

  end if;
end;
/

-- create a view for current classes whose webpages we should display 
-- to students

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

-- create a view for all active classes in the system - these are so
-- professors can access the admin pages even though students don't see
-- these classes

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



-- now, we want to be able to store information about each individual in
-- a class so we create an entry in user_group_type_member_fields

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values 
('edu_class', 'student', 'Institution ID', 'short_text', 1);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values 
('edu_class', 'dropped', 'Institution ID', 'short_text', 2);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values 
('edu_class', 'student', 'Student Account', 'short_text', 3);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values 
('edu_class', 'dropped', 'Student Account', 'short_text', 4);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values
('edu_class', 'ta', 'Office', 'short_text', 5);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values
('edu_class', 'professor', 'Office', 'short_text', 6);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values
('edu_class', 'professor', 'Phone Number', 'short_text', 7);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values
('edu_class', 'ta', 'Phone Number', 'short_text', 8);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values
('edu_class', 'ta', 'Office Hours', 'short_text', 9);

insert into user_group_type_member_fields 
(group_type, role, field_name, field_type, sort_key) 
values
('edu_class', 'professor', 'Office Hours', 'short_text', 10);




-- we want to be able to divide classes further into sections.
-- this is nice for tutorials and recitations.  

-- you can get the class for the section from the parent_group_id from user_groups

create table edu_section_info (
	group_id		integer not null references user_groups,
	section_time		varchar(100),
	section_place		varchar(100)
);



declare	
 n_section_group_types integer;
begin
 select count(*) into n_section_group_types from user_group_types where group_type = 'edu_section';
  if n_section_group_types = 0 then
    insert into user_group_types
    (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy,group_module_administration)
    values
   ('edu_section','Section','Sections','wait','open','full');


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_section', 'section_time', 'Section Time', 'text', 'varchar(100)', '', 2);


   insert into user_group_type_fields (group_type, column_name, pretty_name, column_type, column_actual_type, column_extra, sort_key) 
   values
   ('edu_section', 'section_place', 'Section Place', 'text', 'varchar(100)', '', 3);

  end if;
end;
/




create or replace view edu_sections
as
select
	user_groups.group_id as section_id,
	group_name as section_name,
	parent_group_id as class_id,
	section_time,
 	section_place
from user_groups, edu_section_info
where user_groups.group_id = edu_section_info.group_id
and group_type = 'edu_section'
and active_p = 't'
and approved_p = 't';




declare	
 n_classes_group_types integer;
begin
 select count(*) into n_classes_group_types from user_group_types where group_type = 'edu_department';
  if n_classes_group_types = 0 then
    insert into user_group_types
    (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy, group_module_administration)
    values
   ('edu_department','Department','Departments','wait','open','none');
  end if;
end;
/

-- we are implementing teams as subgroups so lets create a view to see them


create or replace view edu_teams
as
select
	group_id as team_id,
	group_name as team_name,
	parent_group_id as class_id,
	admin_email,
	registration_date,
	creation_user,
	creation_ip_address,
	existence_public_p,
	new_member_policy,
	email_alert_p,
	multi_role_p,
	group_admin_permissions_p,
	index_page_enabled_p,
	body,
	html_p,
	modification_date,
	modifying_user
from user_groups
where group_type = 'edu_team'
and active_p = 't'
and approved_p = 't';

-- Create edu_team group type
declare	
 n_teams_group_types integer;
begin
 select count(*) into n_teams_group_types from user_group_types where group_type = 'edu_team';
  if n_teams_group_types = 0 then
    insert into user_group_types
    (group_type, pretty_name, pretty_plural, approval_policy, default_new_member_policy,group_module_administration)
    values
   ('edu_team','Team','Teams','wait','open','none');
  end if;
end;
/

create sequence edu_textbooks_sequence start with 1;

create table edu_textbooks (
	textbook_id	integer not null primary key,
	title		varchar(200),
	author		varchar(400),
	publisher	varchar(200),
        -- isbn has to be a varchar and not a number because some ISBNs have the letter
        -- x at the end; ISBN will be just the digits and letters mushed together
	-- (no dashes in between), amazon.com style
        isbn               varchar(50)
);


-- map the textbooks to classes

create table edu_classes_to_textbooks_map (
	textbook_id	integer references edu_textbooks,
	class_id	integer references user_groups,
	required_p	char(1) default 't' check (required_p in ('t','f')),
	comments		varchar(4000),
	primary key (class_id, textbook_id)
);




create sequence edu_grade_sequence;

-- records the grade types and their relative weights. this table will not 
-- capture the qualitative factors, but should take care of the
-- quantitative portion of the final grade
create table edu_grades (
       grade_id		       integer not null primary key,
       grade_name	       varchar(100),
       class_id		       integer not null references user_groups,
       comments		       varchar(4000),
       -- weight is a percentage
       weight		       number check (weight between 0 and 100),
       last_modified           date default sysdate not null,
       last_modifying_user     not null references users,
       modified_ip_address     varchar(20) not null
);

-- we want to audit edu_grades

create table edu_grades_audit (
       grade_id		       integer,
       grade_name	       varchar(100),
       class_id		       integer,
       comments		       varchar(4000),
       -- weight is a percentage
       weight		       number,
       last_modified           date,
       last_modifying_user     integer,
       modified_ip_address     varchar(20),
       delete_p                char(1) default('f') check (delete_p in ('t','f'))
);


-- we create a trigger to keep the audit table current

create or replace trigger edu_grades_audit_trigger
before update or delete on edu_grades
for each row
begin
   insert into edu_grades_audit (
        grade_id,
        grade_name,
	class_id,
	comments,
	weight,
	last_modified,
	last_modifying_user,
	modified_ip_address)
    values (
        :old.grade_id,
        :old.grade_name,
	:old.class_id,
	:old.comments,
	:old.weight,
	:old.last_modified,
	:old.last_modifying_user,
	:old.modified_ip_address);
end;
/
show errors



-- we want to be able to easily keep track of lecture notes/handouts
-- note that we do not keep track of author or date uploaded or even
-- a comment about it.  We do not because is all kept in the
-- fs_files table, which edu_handouts references.  We keep the handout_name
-- in both places because we will be displaying that a lot and we do not
-- want to always have to join with fs_files

create sequence edu_handout_id_sequence start with 1;

create table edu_handouts (
	handout_id		integer not null primary key,
	class_id		integer references user_groups,
	handout_name		varchar(500) not null,
	file_id			integer references fs_files not null,
	-- what kind of handout is this?  Possibilities include
	-- lecture_notes and announcement
	handout_type		varchar(200),
	-- what date was this handout given out
	distribution_date 	date default sysdate
);




-- we want to be able to keep track of assignemnts within the class.

create sequence edu_task_sequence;

-- includes assignments, projects, exams, any tasks a student might be
-- graded on

create table edu_student_tasks (
	task_id		integer primary key,
	class_id 	not null references user_groups,
	grade_id	references edu_grades,
        -- we have to have a task type so we can categorize tasks in the
        -- user pages
	task_type	varchar(100) check (task_type in ('assignment', 'exam', 'project')),
	task_name	varchar(100),
	description	varchar(4000),
	-- the date we assigned/created the task
	date_assigned	date,
	-- we want to know the last time the task was modified
	-- (the permissions were changed or a new version was uploaded, etc)
        last_modified   date,
	-- could be date assignment is due, or date of an exam
	due_date	date,
	-- this references the fs_files that holds either the 
	-- actual assignment available for download or the url of the
	-- assignment
	file_id		references fs_files,
	-- who assigned this?
	assigned_by	not null references users,
        -- This column is for projects where students can
        -- assign themselves to teams.
        self_assignable_p char(1) default 'f' check (self_assignable_p in ('t','f')),
        self_assign_deadline    date,
	-- how much is this assignment worth compared to the others with
        -- the same grade_id (e.g. under the same grade group)?
	-- weight is a percentage	
	weight			number check (weight between 0 and 100),
	requires_grade_p char(1) check (requires_grade_p in ('t','f')),
	-- whether the task is submitted/administered online
	online_p char(1) check (online_p in ('t','f')),
	-- if an assignment has been deleted we mark it as inactive
	active_p char(1) default 't' check (active_p in ('t','f'))
);


-- views for assignments, exams, and projects
create or replace view edu_projects
as 
  select
  task_id as project_id,
  class_id,
  task_type,
  assigned_by as teacher_id,
  grade_id,
  task_name as project_name,
  description,
  date_assigned,
  last_modified,
  due_date,
  file_id,
  weight,
  requires_grade_p,
  online_p as electronic_submission_p
from edu_student_tasks 
where task_type='project'
and active_p='t';

create or replace view edu_exams
as
  select
  task_id as exam_id,
  task_type,
  class_id,
  assigned_by as teacher_id,
  grade_id,
  task_name as exam_name,
  description as comments,
  date_assigned as creation_date,
  last_modified,
  due_date as date_administered,
  file_id,
  weight,
  requires_grade_p,
  online_p
from edu_student_tasks 
where task_type='exam'
and active_p='t';

create or replace view edu_assignments 
as 
  select 
  task_id as assignment_id,
  task_type,
  class_id,
  assigned_by as teacher_id,
  grade_id,
  task_name as assignment_name,
  description,
  date_assigned,
  last_modified,
  due_date,
  file_id,
  weight,
  requires_grade_p,
  online_p as electronic_submission_p
from edu_student_tasks
where task_type = 'assignment'
and active_p='t';


-- we want to be able to post the solutions and associate the solutions
-- to a given file

create table edu_task_solutions (
	task_id			references edu_student_tasks,
	file_id			references fs_files,
	primary key(task_id, file_id)
);



-- we want a table to map student solutions to assignments
-- this is what allows students to upload their finished papers, etc.

create table edu_student_answers (
	student_id		references users,
	task_id			references edu_student_tasks,
	file_id			references fs_files,
	-- this is the date of the last time the solutions were changed
	last_modified           date default sysdate not null,
        last_modifying_user     not null references users,
	-- modified_ip_address is stored as a string separated by periods.
        modified_ip_address     varchar(20) not null
);


create table edu_student_answers_audit (
	student_id		integer,
	task_id			integer,
	file_id			integer,
	-- this is the date of the last time the solutions were changed
	last_modified           date,
        last_modifying_user     integer,
	-- modified_ip_address is stored as a string separated by periods.
        modified_ip_address     varchar(20)
);


-- we create a trigger to keep the audit table current

create or replace trigger edu_student_answers_audit_tr
before update or delete on edu_student_answers
for each row
begin
	insert into edu_student_answers_audit (
	    	student_id,
		task_id,
		file_id,
		last_modified,
		last_modifying_user,
		modified_ip_address)
           values (
	    	:old.student_id,
		:old.task_id,
		:old.file_id,
		:old.last_modified,
		:old.last_modifying_user,
		:old.modified_ip_address);                     
end;
/
show errors




-- this is where we keep the student grades and the evaluations
-- that students receive from teachers

create sequence edu_evaluation_id_sequence;

create table edu_student_evaluations (
	evaluation_id		integer primary key,
	class_id		not null references user_groups,
        -- must have student_id or team_id 
	student_id		references users,
	team_id			references user_groups,
	task_id		        references edu_student_tasks,
	-- there may be several times during the term that the prof 
        -- wants to evaluate a student.  So, the evaluation_type 
        -- is something like 'end_of_term' or 'midterm'
	evaluation_type		varchar(100),
	grader_id		not null references users,
	grade			varchar(5),
	comments		varchar(4000),
	show_student_p		char(1) default 't' check (show_student_p in ('t','f')),
	evaluation_date		date default sysdate,
	last_modified           date default sysdate not null,
        last_modifying_user     not null references users,
	-- modified_ip_address is stored as a string separated by periods.
        modified_ip_address     varchar(20) not null
);


-- we want to audit the evaluations table

create table edu_student_evaluations_audit (
	evaluation_id		integer,
	class_id		integer,
        -- must have student_id or team_id 
	student_id		integer,
	team_id			integer,
	task_id		        integer,
	evaluation_type		varchar(100),
	grader_id		integer,
	grade			varchar(5),
	comments		varchar(4000),
	show_student_p		char(1),
	evaluation_date		date,
	last_modified           date,
        last_modifying_user	integer,
        modified_ip_address     varchar(20)
);


-- we create a trigger to keep the audit table current

create or replace trigger edu_student_answers_audit_tr
before update or delete on edu_student_answers
for each row
begin
	insert into edu_student_answers_audit (
	    	student_id,
		task_id,
		file_id,
		last_modified,
		last_modifying_user,
		modified_ip_address)
           values (
	    	:old.student_id,
		:old.task_id,
		:old.file_id,
		:old.last_modified,
		:old.last_modifying_user,
		:old.modified_ip_address);                     
end;
/
show errors



-- now, we want to hold information about each project.  It is possible
-- to have one term project but many instances of that project.  For
-- instance, "Final Project for 6.916" is a term project that would
-- be kept in the edu_tasks table but ArfDigita.org is a project
-- instance that would be kept in this table.  There is a many to 
-- one mapping

-- we make task_id not null because every project has to be part of
-- some sort of task (either an assignment or a project)
-- we make it a task because all evaluations are done on tasks

create sequence edu_project_instance_id_seq start with 1;

create table edu_project_instances  (
	project_instance_id 	integer not null primary key,
	project_instance_name	varchar(200),
	project_instance_url	varchar(500),
	-- which project is this an instance of?
	project_id		integer not null references edu_student_tasks,
	description		varchar(4000),
	approved_p		char(1) default 'f' check(approved_p in ('t','f')),
        approved_date           date,
        approving_user          references users(user_id),
	-- we want to be able to generate a consistent user interface so
	-- we record the type of project.  
	project_type		varchar(10) default 'team' check(project_type in ('user','team')),
	min_body_count		integer,
	max_body_count		integer,
	-- we want to be able to "delete" project instances so we have active_p
	active_p		char(1) default 't' check(active_p in ('t','f'))
);




-- we want to be able to assign students and teams to projects

create table edu_project_user_map (
	project_instance_id	integer not null references edu_project_instances,
	team_id			integer references user_groups,
	student_id		integer references users,
	constraint edu_project_user_map_check check ((team_id is null and student_id is not null) or (team_id is not null and student_id is null))
);

create index edu_project_map_idx on edu_project_user_map(project_instance_id, team_id, student_id);


-- we want to allow classes to rename their roles.  That is,
-- some people want to be called Professor where others want
-- to be called Instructor and still others want to be called
-- Lecturer.  We don't want to just use the 'role' column
-- in user_group_roles because then we would not have a way
-- to "spam all professors and TAs" because we would not know
-- which role was a prof and which was a TA.  Also, we want to
-- have a sort_key so that we know which order to display these
-- items when they are shown to the user.  So, we have the following
-- table

-- so, for the case where a class wants to call the prof a Lecturer, 
-- we would have role = Professor and pretty_role = Lecturer

create table edu_role_pretty_role_map (
	group_id		not null references user_groups,
	-- role should reference user_group_roles(role)
	role			varchar(200),
	-- what the class wants to call the role
	pretty_role		varchar(200),
	pretty_role_plural 	varchar(300),
	-- sort key for display of columns.
	sort_key		integer not null,
	-- this is to capture info about the hierarchy of role permissions
	priority		integer,
	primary key (group_id, role)
);







-------------------------------------------------
-------------------------------------------------
--
--        	BEGIN PL/SQL 
--
--
-------------------------------------------------
-------------------------------------------------




-- now, we need a trigger to update the table we just created
-- this is included in case people want to add new roles to
-- the class all they have to do insert into user_group_roles
-- and this will take care of the rest

-- I. temporary table: holds rowids so that we know which rows
--    have changed/been inserted

create global temporary table edu_role_change_state_info (
	role_rowid	rowid,
        old_role	varchar(200)
);


-- II. row-level trigger: stores what changes in temporary table.

CREATE OR REPLACE TRIGGER edu_role_before_update_tr
BEFORE UPDATE OF role ON user_group_roles
FOR EACH ROW
BEGIN
	insert into edu_role_change_state_info(role_rowid, old_role)
	values (:new.rowid, :old.role);
END;
/
show errors


-- III. update the edu_role_pretty_role table

CREATE OR REPLACE TRIGGER edu_class_role_update_tr
AFTER UPDATE OF role ON user_group_roles
DECLARE

	CURSOR changes_cursor IS
	SELECT unique role_rowid, old_role
	FROM edu_role_change_state_info;

	v_group_id	user_group_roles.group_id%TYPE;
	v_new_role	user_group_roles.role%TYPE;
	v_rowid		rowid;
	v_class_p	integer;
	v_old_role	edu_role_change_state_info.old_role%TYPE;
BEGIN
	FOR changes_cursor_rec IN changes_cursor LOOP
		v_rowid := changes_cursor_rec.role_rowid;
		v_old_role := changes_cursor_rec.old_role;

		select count(user_group_roles.group_id), 
                       user_group_roles.group_id, 
                       role
                       into v_class_p, v_group_id, v_new_role
		from user_groups, user_group_roles
		where group_type = 'edu_class'
                and user_group_roles.rowid = v_rowid
                and user_group_roles.group_id = user_groups.group_id
                group by user_group_roles.group_id, role;

 	    -- if this is a group of type edu_class
	    IF v_class_p > 0 THEN
			-- we want to update the existing row
			update edu_role_pretty_role_map
                           set role = v_new_role
                        where group_id = v_group_id
                          and role = v_old_role;
	    END IF;
	END LOOP;
		
	DELETE FROM edu_role_change_state_info;
END;
/
show errors


-- for every row that is inserted into the user_group_roles, if
-- the group is of type edu_class then we want to insert a corresponding
-- role into edu_role_pretty_role_map

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


-- if a role is delete from user_group_roles and the group
-- is of type edu_class then we also want to delete it from
-- edu_role_pretty_role_map

CREATE OR REPLACE TRIGGER edu_class_role_insert_tr
BEFORE DELETE ON user_group_roles
FOR EACH ROW
DECLARE
	v_class_p	integer;
BEGIN
	select count(group_id) into v_class_p
	from user_groups
	where group_type = 'edu_class'
        and group_id = :old.group_id
	and group_type = 'edu_class';

	IF v_class_p > 0 THEN

		delete from edu_role_pretty_role_map 
		where group_id = :old.group_id
                and role = :old.role;

	END IF;
END;
/
show errors





---------------------------------------------------
--
--
--
--    begin the portal tables
--
--
--
---------------------------------------------------



-- the portal mini-tables

create sequence weather_id_sequence;


create table portal_weather (
       weather_id    integer not null primary key,
       user_id		    not null references users,
       city		    varchar(100),
       usps_abbrev	    references states,
       zip_code		    varchar(10),
       -- the type can be: next day forecast, 5 day forecast, current conditions
       five_day_p		    char(1) default 'f' check (five_day_p in ('t','f')),
       next_day_p		    char(1) default 'f' check (next_day_p in ('t','f')),
       current_p	    char(1) default 'f' check (current_p in ('t','f'))
);

create table portal_stocks (
       user_id		   not null references users,
       symbol		   varchar(10) not null,
       default_p	   char(1) default 'f' check(default_p in ('t','f'))
);

--- we're currently using the calendar module and not edu_calendar
--- because the features have not been fully implemented 
-- this is taken from the intranet calendar
create table edu_calendar_categories (
	category	varchar(100) primary key,
	enabled_p	char(1) default 't' check(enabled_p in ('t','f'))
);

create sequence edu_calendar_id_sequence;

-- updates from intranet/doc/sql/calendar.sql:
-- the addition of a viewable column that specifies whether the calendar
-- entry is viewable by the public and if so, whether we should show the
-- title or something in place of the title (e.g. Busy, Free, Tentative --
-- MS Outlook options). also, addition of owner column that identifies who
-- the entry is for: so we can display calendars with respect to individual
-- users or groups of users (like in a team)

create table edu_calendar (
	calendar_id	integer primary key,
	category	not null references calendar_categories,
	-- the way we connect calendar entries to users
	owner		not null references users,
	title		varchar(100) not null,
	body		varchar(4000) not null,
	-- is the body in HTML or plain text (the default)
	html_p			char(1) default 'f' check(html_p in ('t','f')),
	start_date	date not null,  -- first day of the event
	end_date	date not null,  -- last day of the event (same as start_date for single-day events)
	expiration_date	date not null,  -- day to stop including the event in calendars, typically end_date
	-- viewable as public means the title will be displayed. private
	-- means the entry will be invisible unless viewed by the
	-- owner. busy, free, or tentative will be displayed instead of title
	-- to viewers other than owner
	viewable	varchar(100) default 'public' check(viewable in
	('public', 'busy', 'free', 'tentative', 'private')),
	event_url	varchar(200),  -- URL to the event
	event_email	varchar(100),  -- email address for the event
	-- for events that have a geographical location
	country_code	references country_codes(iso),
	-- within the US
	usps_abbrev	references states,
	-- we only want five digits
	zip_code	varchar(10),
	approved_p	char(1) default 'f' check(approved_p in ('t','f')),
	creation_date	date not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null
);

-- create default tables for each portal
-- start a personal category so the user can enter personal events of
-- "user" scope
create or replace trigger portal_page_upon_new_user
after insert on users
  for each row
  begin
    insert into portal_pages 
    (page_id, user_id, page_number)
    values
    (portal_page_id_sequence.nextval, :new.user_id, 1);
    insert into calendar_categories (category_id, scope, user_id, category,
enabled_p) 
    values 
    (calendar_category_id_sequence.nextval, 'user', :new.user_id,
'Personal', 't');    
  end;
/
show errors

-- the opposite of the above trigger -- for deleting users
create or replace trigger portal_remove_upon_user_delete
before delete on users
       for each row
       begin
	delete from portal_pages
	where user_id=:old.user_id;
       end;
/
show errors 

create or replace trigger portal_setup_upon_page_insert
after insert on portal_pages
  for each row
  declare
	stock_table_id		portal_tables.table_id%TYPE;
	weather_table_id	portal_tables.table_id%TYPE;
	classes_table_id	portal_tables.table_id%TYPE;
	announcements_table_id	portal_tables.table_id%TYPE;
	calendar_table_id	portal_tables.table_id%TYPE;
  begin 
	select table_id into stock_table_id from portal_tables where
table_name='Stock Quotes';
	select table_id into weather_table_id from portal_tables where
table_name='Current Weather';
	select table_id into classes_table_id from portal_tables where
table_name='Classes';
	select table_id into announcements_table_id from portal_tables where
table_name='Announcements';
	select table_id into calendar_table_id from portal_tables where
table_name='Calendar';
     insert into portal_table_page_map
     (page_id, table_id, sort_key, page_side)
     values
     (:new.page_id, stock_table_id, 1, 'l');
     insert into portal_table_page_map
     (page_id, table_id, sort_key, page_side)
     values
     (:new.page_id, weather_table_id, 2, 'l');
     insert into portal_table_page_map
     (page_id, table_id, sort_key, page_side)
     values
     (:new.page_id, classes_table_id, 1, 'r');
     insert into portal_table_page_map
     (page_id, table_id, sort_key, page_side)
     values
     (:new.page_id, announcements_table_id, 3, 'l');
     insert into portal_table_page_map
     (page_id, table_id, sort_key, page_side)
     values
     (:new.page_id, calendar_table_id, 2, 'r');
  end;
/
show errors

-- the opposite of the trigger above -- upon deleting a page for portal
-- table we also want to delete the entries from portal_table_page_map
create or replace trigger portal_update_upon_page_delete
before delete on portal_pages
    for each row
    begin
       delete from portal_table_page_map where page_id=:old.page_id;
    end;
/
show errors   

