--
-- polls.sql - user opinion surveys
--
-- markd@arsdigita.com 9/7/99
-- based on stuff by Ben Adida
--
-- (added integrity constraints, 9/27/99)
--

create sequence poll_id_sequence;

create table polls (
	poll_id		integer not null primary key,
	name		varchar(100) not null,
	description	varchar(4000),
	-- make the dates NULL for an on-going poll
	start_date	date,
	end_date	date,
	require_registration_p	char(1) default 'f' check (require_registration_p in ('t','f')) not null
);


create sequence poll_choice_id_sequence;


create table poll_choices (
	choice_id	integer not null primary key,
	poll_id		references polls not null,
	label		varchar(500) not null,
	sort_order	integer
);

create index poll_choices_index on poll_choices(poll_id, choice_id);



create table poll_user_choices (
	poll_id		references polls not null,
	choice_id	references poll_choices not null,
	-- user_id can be NULL if we're not requiring registration
	user_id		references users,
	ip_address	varchar(50) not null,
	choice_date	date not null
);

create index poll_user_choice_index on poll_user_choices(poll_id);
create index poll_user_choices_choice_index on poll_user_choices(choice_id);


create or replace function poll_is_active_p (start_date in date, 
					     end_date in date)
return char
as
    result char;
begin
    result := 't';

    if (trunc(start_date) > trunc(sysdate)) then
        result := 'f';
    end if;

    if (trunc(end_date) < trunc(sysdate)) then
        result := 'f';
    end if;

    return result;

end poll_is_active_p;

/
show errors;
