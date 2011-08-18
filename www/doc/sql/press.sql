-- Data model for the press module
--
-- Author: ron@arsdigita.com, December 1999
--
-- $Id: press.sql,v 3.0 2000/02/06 03:29:04 ron Exp $


--
-- Press release templates
--

create sequence press_template_id_sequence start with 2;

create table press_templates (
	template_id		integer primary key,
	-- we use this to select the template
	template_name		varchar(100) not null,
	-- the adp code fraqment
	template_adp		varchar(4000) not null
);

-- Initialize with one site-wide Default template
-- (if executed twice, the second execution will fail due to 
--  primary key constraint above; we won't end up with an 
--  extra row in the db)

insert into press_templates
(template_id, 
 template_name,
 template_adp)
values
(1, 
'Default',
'<b><%=$publication_name%></b> - <%=$article_title%><br>
 <%=$publication_date%> - "<%=$abstract%>"');

create sequence press_id_sequence;

create table press (
	press_id		integer primary key,
	-- if scope=public, this is press coverage for the whole system
        -- if scope=group, this is press coverage for a subcommunity
        scope			varchar(20) not null,
	-- will be NULL if scope=public 
	group_id		references user_groups,
	-- determines how the release is formatted
	template_id		references press_templates,
	-- if true, keep the release active after it would normally expire. 
	important_p		char(1) default 'f' check (important_p in ('t','f')),
	-- the name of the publication, e.g. New York Times
	publication_name	varchar(100) not null,
	-- the home page of the publication, e.g., http://www.nytimes.com
	publication_link	varchar(200),
	-- we use this for sorting
	publication_date	date not null,
	-- this will override publication_date where we need to say "Oct-Nov 1998 issue"
	-- but will typically be NULL
	publication_date_desc	varchar(100),
	-- might be null if the entire publication is about the site or company
	article_title		varchar(100),
	-- if the article is Web-available
	article_link		varchar(200),
	-- optional page reference, e.g. page 100
	article_pages		varchar(100),
	-- quote from or summary of article
	abstract		varchar(4000),
	-- is the abstract in HTML or plain text (the default)
	html_p			char(1) default 'f' check (html_p in ('t','f')),
	creation_date		date not null,
	creation_user		not null references users(user_id),
	creation_ip_address	varchar(50) not null
);

