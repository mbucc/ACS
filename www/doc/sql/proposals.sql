-- proposals.sql
--
-- by tzumainn@mit.edu 9/18/99
--
-- supports 6.916/ArsDigita project proposal system in /proposals/
--

create sequence proposal_id_sequence start with 1;

create table proposals (
	proposal_id			integer primary key,
	purpose				varchar(10) check (purpose in ('6.916','ArsDigita')),
	title				varchar(100) not null,
	user_classes			clob,
	significant_new_capabilities	clob,
	feature_list_complete		clob,
	feature_list_ranking		clob,
	dependencies			clob,
	minimum_launchable_feature_set	clob,
	promotion			clob,
	name				varchar(100) not null,
	email				varchar(100) not null,
	phone				varchar(100),
	date_submitted			date default sysdate,
	deleted_p			char(1) default 'f' check(deleted_p in ('t','f'))
);

