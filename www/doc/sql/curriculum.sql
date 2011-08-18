--
-- curriculum.sql
--
-- created by philg@mit.edu on September 25, 1999
--
-- supports the /doc/curriculum.html system that enables publisher
-- to say "I want novice users to see the following N things over
-- their months or years of casual surfing"
--

create sequence curriculum_element_id_sequence start with 1;

create table curriculum (
	curriculum_element_id	integer primary key,
	-- 0 is the first element of the course, 8 would be the 9th
	element_index		integer,
	url			varchar(200) not null,
	very_very_short_name	varchar(30) not null,
	one_line_description	varchar(200) not null,
	full_description	varchar(4000)
);

-- what has a particular user seen

create table user_curriculum_map (
	user_id			not null references users,
	curriculum_element_id	not null references curriculum,
	completion_date		date default sysdate not null,
	primary key (user_id, curriculum_element_id)
);
