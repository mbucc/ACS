-- Customer Relationship Manager
-- jsc@arsdigita.com, Sept 24, 1999


-- Reference table for available states.
create table crm_states (
	state_name	varchar(50) not null primary key,
	description	varchar(1000) not null, -- for UI
	initial_state_p	char(1) default 'f' check (initial_state_p in ('t', 'f'))
);

-- Defines allowable transitions and a bit of SQL which can trigger it.
create table crm_state_transitions (
	state_name	not null references crm_states,
	next_state	not null references crm_states,
	triggering_order	integer not null,
	-- a SQL fragment which will get called as:
	-- update users set crm_state = <next_state>, crm_state_entered_date = sysdate where crm_state = <state_name> and (<transition_condition>)
	transition_condition	varchar(500) not null,
	primary key (state_name, next_state)
);

-- Some helper functions
create or replace function activity_since (v_user_id IN INTEGER, since IN DATE)
return INTEGER
as
  n_posts	INTEGER;
  n_comments	INTEGER;
begin
  select count(*) into n_posts from bboard where user_id = v_user_id and posting_time > since;
  select count(*) into n_comments from comments where user_id = v_user_id and posting_time > since;
  return n_posts + n_comments;
end activity_since;
/

