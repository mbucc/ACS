alter table bboard_topics add group_id references user_groups;
alter table im_projects add ticket_project_id 	    references ticket_projects;
