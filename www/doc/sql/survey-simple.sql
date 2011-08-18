-- /www/doc/sql/survey-simple.sql
--
-- based on student work from 6.916 in Fall 1999
-- which was in turn based on problem set 4
-- in http://photo.net/teaching/one-term-web.html
--
-- by philg@mit.edu and raj@alum.mit.edu on February 9, 2000
-- 
-- $Id: survey-simple.sql,v 1.5.2.1 2000/03/18 02:01:26 ron Exp $ 

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
	creation_user		not null references users(user_id),
	creation_date	      	date default sysdate,
	enabled_p               char(1) default 'f' check(enabled_p in ('t','f'))
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
				check(presentation_type in ('textbox','textarea','select','radio', 'checkbox', 'date')),
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
	date_answer		date
);

create index survsimp_response_index on survsimp_question_responses (response_id, question_id);


begin
   administration_group_add ('Simple Survey System Staff', short_name_from_group_name('survsimp'), 'survsimp', NULL, 'f', '/survsimp/admin/');
end;
/

