

alter table ticket_projects add (
	group_id references user_groups
);

