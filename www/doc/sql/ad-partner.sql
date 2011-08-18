-- we need a table that will let us dynamically create cobranded pages.
-- we do this by stuffing some appearance variables in a table and 
-- create some header and footer functions in the tcl directory for 
-- every partner. The partner_id fields in the gs_partner table 
-- will all be automatically registered to set a cookie and redirect
-- to the appropriate page

-- To kill ad-partner
-- drop view ad_partner_header_procs;
-- drop view ad_partner_footer_procs;
-- drop table ad_partner_procs;
-- drop table ad_partner_url;
-- drop table ad_partner;

create sequence ad_partner_partner_id_seq start with 1000;
create table ad_partner (
        partner_id		integer primary key,
	-- a human understandable name of the partner
	partner_name		varchar(250) not null,
	-- the cookie that will get set in the  ad_partner cookie (e.g. aol)
	partner_cookie		varchar(50) not null,
        -- now we start defining stuff that we use in the templates 
        -- font face and color for standard text
	default_font_face	varchar(100),
	default_font_color	varchar(20),
        -- font face and color for titles
	title_font_face		varchar(100),
	title_font_color	varchar(20),
	group_id		references user_groups
);
create index ad_partner_partner_cookie on ad_partner(partner_cookie);
create index ad_partner_partner_name_idx on ad_partner(partner_name);

create sequence ad_partner_url_url_id_seq start with 1000;
create table ad_partner_url (
	url_id			integer primary key,
	partner_id  		not null references ad_partner(partner_id),
	-- the url stub of the section(directory) we are cobranding (e.g. /search)
        -- use a leading slash but don't include the partner_cookie
	url_stub		varchar(50) not null,
	unique(partner_id,url_stub)
);
create index ad_partner_url_url_stub on ad_partner_url(url_stub);

create sequence ad_partner_procs_proc_id_seq start with 1000;
-- each partner can have multiple procs registered for displaying section
-- headers. These will be called in order based on call_number
create table ad_partner_procs (
	proc_id			integer primary key,
	url_id 			not null references ad_partner_url(url_id),
	proc_name		varchar(100) not null,
	call_number		integer not null,
	proc_type		char(15) not null check(proc_type in ('header','footer')),
	unique(call_number,url_id,proc_type)
);

create or replace view ad_partner_header_procs as
select u.partner_id, u.url_id, p.proc_name, p.call_number, p.proc_id
from ad_partner_procs p, ad_partner_url u
where proc_type='header'
and p.url_id=u.url_id
order by call_number;

create or replace view ad_partner_footer_procs as
select u.partner_id, u.url_id, p.proc_name, p.call_number, p.proc_id
from ad_partner_procs p, ad_partner_url u
where proc_type='footer'
and p.url_id=u.url_id
order by call_number;


create table ad_partner_group_map (
	partner_id  	integer references ad_partner not null,
	group_id	integer references user_groups not null,
	primary key (group_id, partner_id)
);


create or replace function ad_partner_get_cookie (v_group_id integer)
return varchar
IS
  v_partner_cookie  ad_partner.partner_cookie%TYPE;
BEGIN
  select partner_cookie into v_partner_cookie
    from ad_partner_group_map, ad_partner
   where ad_partner_group_map.partner_id = ad_partner.partner_id
     and ad_partner_group_map.group_id = v_group_id;

  return v_partner_cookie;

END;
/
show errors;

-- Initial Population for ArsDigita (cookie = ad)

insert into ad_partner 
(partner_id,partner_cookie, partner_name, default_font_face, default_font_color, title_font_face, title_font_color)
values
('1',
 'ad',
 'ArsDigita',
 '',
 '',
 '',
 ''
);

insert into ad_partner_url 
(url_id, partner_id, url_stub)
values 
(1,1,'/');

insert into ad_partner_procs 
(proc_id, url_id, proc_name, call_number, proc_type)
values 
(1,1,'ad_partner_generic_header',1,'header');

insert into ad_partner_procs 
(proc_id, url_id, proc_name, call_number, proc_type)
values 
(4,1,'ad_partner_generic_footer',1,'footer');

