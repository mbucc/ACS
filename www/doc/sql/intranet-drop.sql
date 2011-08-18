drop sequence im_url_types_type_id_seq;
drop sequence im_project_status_id_seq;
drop sequence im_project_types_id_seq;
drop sequence im_customer_status_seq;
drop sequence im_partner_type_seq;

delete from im_project_payments;
delete from im_partners;
delete from im_partner_types;

delete from im_project_payments ;
delete from im_project_payments_audit;
delete from im_allocations;
delete from im_allocations_audit;
delete from im_employee_percentage_time; 
delete from im_start_blocks;

delete from im_project_url_map;
delete from im_hours;

delete from im_url_types;
delete from im_projects;

delete from im_project_status;
delete from im_project_types;

delete from im_customers;
delete from im_customer_status;

delete from im_employee_info;
delete from im_offices;

delete from user_group_map_queue where group_id in (select group_id from user_groups where group_type='intranet');
delete from user_group_map_queue where group_id in (select group_id from user_groups where group_type='intranet');
delete from user_group_map where group_id in (select group_id from user_groups where group_type='intranet');
delete from user_group_member_fields where group_id in (select group_id from user_groups where group_type='intranet');
delete from user_group_roles where group_id in (select group_id from user_groups where group_type='intranet');
delete from user_group_action_role_map where group_id in (select group_id from user_groups where group_type='intranet');
delete from user_group_actions where group_id in (select group_id from user_groups where group_type='intranet');

delete from content_section_links
where from_section_id in (select section_id
                          from content_sections
                          where group_id in (select group_id from user_groups where group_type='intranet'))
or to_section_id in (select section_id
                          from content_sections
                          where group_id in (select group_id from user_groups where group_type='intranet'));

delete from content_files
where section_id in (select section_id
                          from content_sections
                          where group_id in (select group_id from user_groups where group_type='intranet'));

delete from content_sections where group_id in (select group_id from user_groups where group_type='intranet');
delete from faqs where group_id in (select group_id from user_groups where group_type='intranet');

delete from user_groups where group_type='intranet';


