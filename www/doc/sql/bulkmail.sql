create sequence bulkmail_id_sequence start with 1;

create table bulkmail_instances (
	bulkmail_id	integer primary key,
	description	varchar(400),
	creation_date	date not null,
	creation_user	references users(user_id),
	end_date	date,
	n_sent		integer
);

create table bulkmail_log (
	bulkmail_id	references bulkmail_instances,
	user_id		references users,
	sent_date	date not null
);

create table bulkmail_bounces (
	bulkmail_id	references bulkmail_instances,
	user_id		references users,
	creation_date	date default sysdate,
	active_p	char(1) default 't' check(active_p in ('t', 'f'))
);	
	
create index bulkmail_user_bounce_idx on bulkmail_bounces(user_id, active_p);
