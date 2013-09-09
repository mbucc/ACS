-- /www/doc/sql/survey-simple.sql
--
-- based on student work from 6.916 in Fall 1999
-- which was in turn based on problem set 4
-- in http://photo.net/teaching/one-term-web.html
--
-- by philg@mit.edu and raj@alum.mit.edu on February 9, 2000
-- 
-- survey-simple.sql,v 1.14 2000/06/17 18:49:35 ron Exp 

-- we expect this to be replaced with a more powerful survey
-- module, to be developed by buddy@ucla.edu, so we prefix
-- all of our Oracle structures with "survsimp"

create sequence survsimp_survey_id_sequence start with 1;

create table survsimp_surveys (
	survey_id		integer primary key,
	name			varchar(100) not null,
	-- short, non-editable name we can identify this survey by
	short_name		varchar(20) unique not null,
	description		varchar(4000) not null,
        description_html_p      char(1) default 'f'
                                constraint survsimp_sur_desc_html_p_ck
                                check(description_html_p in ('t','f')),
	creation_user		not null references users(user_id),
	creation_date	      	date default sysdate,
	enabled_p               char(1) default 'f' check(enabled_p in ('t','f')),
	-- limit to one response per user
	single_response_p	char(1) default 'f' check(single_response_p in ('t','f')),
	single_editable_p	char(1) default 't' check(single_editable_p in ('t','f'))
);



create sequence survsimp_question_id_sequence start with 1;


-- each question can be 

create table survsimp_questions (
	question_id		integer primary key,
	survey_id		not null references survsimp_surveys,
	sort_key		integer not null,
	question_text		clob not null,
	-- can be 'text', 'shorttext', 'boolean', 'number', 'integer', 'choice'
        abstract_data_type      varchar(30) not null,
	required_p		char(1) check (required_p in ('t','f')),
	active_p		char(1) check (active_p in ('t','f')),
	presentation_type	varchar(20) not null
				check(presentation_type in ('textbox','textarea','select','radio', 'checkbox', 'date', 'upload_file')),
	-- for text, "small", "medium", "large" sizes
	-- for textarea, "rows=X cols=X"
	presentation_options	varchar(50),
	presentation_alignment	varchar(15) default 'below'
            			check(presentation_alignment in ('below','beside')),       
	creation_user		references users not null,
	creation_date		date default sysdate
);


-- Categorization:  We'd like each question to belong
-- to a category.  For example, if we write a survey
-- about a client project, we want to categorize questions
-- as "client" or "internal". Other surveys might want
-- to group questions according to category.
-- To categorize questions, we use the site wide
-- category system.

-- Categories will be stored in categories table
-- with category_type as "survsimp"

-- The site_wide_category_map table will map
-- categories to individual surveys.  The site_wide_category_map
-- will also map categories to individual questions.


-- for when a question has a fixed set of responses

create sequence survsimp_choice_id_sequence start with 1;

create table survsimp_question_choices (
	choice_id	integer not null primary key,
	question_id	not null references survsimp_questions,
	-- human readable 
	label		varchar(500) not null,
	-- might be useful for averaging or whatever, generally null
	numeric_value	number,
	-- lower is earlier 
	sort_order	integer
);



create sequence survsimp_response_id_sequence start with 1;

-- this records a response by one user to one survey
-- (could also be a proposal in which case we'll do funny 
--  things like let the user give it a title, send him or her
--  email if someone comments on it, etc.)
create table survsimp_responses (
	response_id		integer primary key,
	survey_id		not null references survsimp_surveys,
	-- scope is user, public or group
	scope           varchar(20),
	user_id			references users,
	group_id		references user_groups,
	constraint survsimp_responses_scopecheck check 
		((scope='group' and group_id is not null) 
                 or (scope='public' and group_id is null)
		or (scope='user' and group_id is null)),
	title			varchar(100),
	submission_date		date default sysdate not null,
	ip_address		varchar(50),
	-- do we sent email if 
	notify_on_comment_p	char(1) default 'f'
				check(notify_on_comment_p in ('t','f')),
	-- proposal can be public, private, or deleted
	proposal_state		varchar(30) default 'private'
				check(proposal_state in ('public','private', 'deleted'))
	-- This did not work for how we tried to use it
	-- (we wanted users to take the survey each week).
	-- If the survey should be unique to a user, this
	-- should be handled by an ini parameter
	-- unique (survey_id, user_id)
);


-- mbryzek: 3/27/2000
-- Sometimes you release a survey, and then later decide that 
-- you only want to include one response per user. The following
-- view includes only the latest response from all users
create or replace view survsimp_responses_unique as 
select r1.* from survsimp_responses r1
where r1.response_id=(select max(r2.response_id) 
                        from survsimp_responses r2
                       where r1.survey_id=r2.survey_id
                         and r1.user_id=r2.user_id);


-- this table stores the answers to each question for a survey
-- we want to be able to hold different data types in one long skinny table 
-- but we also may want to do averages, etc., so we can't just use CLOBs

create table survsimp_question_responses (
	response_id		not null references survsimp_responses,
	question_id		not null references survsimp_questions,
	-- if the user picked a canned response
	choice_id		references survsimp_question_choices,
	boolean_answer		char(1) check(boolean_answer in ('t','f')),
	clob_answer		clob,
	number_answer		number,
	varchar_answer		varchar(4000),
	date_answer		date,
	-- columns useful for attachments, column names
	-- lifted from file-storage.sql and bboard.sql
	-- this is where the actual content is stored
	attachment_answer	blob,
	-- file name including extension but not path
	attachment_file_name	varchar(500),
	attachment_file_type	varchar(100),	-- this is a MIME type (e.g., image/jpeg)
	attachment_file_extension varchar(50) 	-- e.g., "jpg"
);


create index survsimp_response_index on survsimp_question_responses (response_id, question_id);


-- We create a view that selects out only the last response from each
-- user to give us at most 1 response from all users.
create or replace view survsimp_question_responses_un as 
select qr.* 
  from survsimp_question_responses qr, survsimp_responses_unique r
 where qr.response_id=r.response_id;


begin
   administration_group_add ('Simple Survey System Staff', short_name_from_group_name('survsimp'), 'survsimp', NULL, 'f', '/survsimp/admin/');
end;
/

