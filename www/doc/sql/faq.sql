-- faq.sql  

-- a simple data model for holding a set of FAQs
-- by dh@arsdigita.com

-- Created Dec. 19 1999


create sequence faq_id_sequence;

create table faqs (
	faq_id		integer primary key,
	-- name of the FAQ.
	faq_name	varchar(250) not null,
	-- group the viewing may be restricted to 
	group_id	integer references user_groups,
	-- permissions can be expanded to be more complex later
        scope		varchar(20) not null,
        -- insure consistant state 
       	constraint faq_scope_check check ((scope='group' and group_id is not null) 
                                          or (scope='public' and group_id is null))
);

create index faqs_group_idx on faqs ( group_id );

create sequence faq_entry_id_sequence;

create table faq_q_and_a (
	entry_id	integer primary key,
	 -- which FAQ
	faq_id		integer references faqs not null,
	question	varchar(4000) not null,
	answer		varchar(4000) not null,
	 -- determines the order of questions in a FAQ
	sort_key	integer not null
);


