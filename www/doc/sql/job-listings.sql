--
-- /www/doc/sql/job-listings.sql
--
-- Simple table to store job listings for the intranet
--
-- @author markc@arsdigita.com
-- @creation-date 4/2000
--
-- job-listings.sql,v 3.4.2.1 2001/01/10 18:04:38 mbryzek Exp
--


create table job_listings (
    listing_id integer primary key,
    -- job title (publicly visible)
    title varchar(40) not null,
    -- main text of listing
    text varchar(4000) not null,
    html_p char(1) default 'f' check (html_p in ('t','f')),
    -- is this listing visible to the general public?
    public_p char(1) default 't' check (public_p in ('t','f')),
    -- how many openings?
    positions_open integer,
    -- text description of compensation
    salary varchar(40),
    basis varchar(20) check (basis in ('full-time','part-time','contract','internship')),
    listing_date date default sysdate not null,
    listing_user_id integer not null references users,
    deleted_p char(1) default 'f' check (deleted_p in ('t','f')),
    -- who to send resume to (if online job application is not configured)
    contact_email varchar(40),
    -- support for online job applications
    initial_state_id  references categories,
    survey_id integer references survsimp_surveys,
    -- which project will we create tickets in for online applications 
    ticket_project_id integer references ticket_projects(project_id),
    -- who will be listed as the ticket creator for online applications
    ticket_creator_id integer references users
);

alter table job_listings add constraint job_listing_all_or_none 
check ((survey_id         is not null and  
	ticket_project_id is not null and
        ticket_creator_id is not null) or
       (contact_email is  not null and 
	survey_id         is null and 
	ticket_project_id is null and
        ticket_creator_id is null));


create table job_listing_office_map (
    listing_id integer references job_listings,
    group_id integer references user_groups
);


create sequence job_listing_id_seq;

-- Support for handling job applications

create sequence jl_email_template_id_seq;

create table job_listing_email_templates (
	email_template_id	integer primary key,
	email_template_name	varchar(100) unique not null,
	pretty_name		varchar(100),
	from_email		varchar(100) not null,
	from_name		varchar(100),
	subject			varchar(100) not null,
	template		clob not null,
	html_p			char(1) default 'f' check (html_p in ('t','f')),
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(20) not null,
	last_modified		date not null,
	last_modifying_user	not null references users(user_id),
	modified_ip_address	varchar(20) not null
);

create table job_listing_email_template_map (
    listing_id integer not null references job_listings,
    email_template_id  integer not null references job_listing_email_templates
);



