
-- Create the basic groups for intranet
begin
   user_group_add ('intranet', 'Customers', 'customer', 'f'); 
   user_group_add ('intranet', 'Projects', 'project', 'f'); 
   user_group_add ('intranet', 'Offices', 'office', 'f'); 
   user_group_add ('intranet', 'Employees', 'employee', 'f'); 
   user_group_add ('intranet', 'Procedure', 'procedure', 'f'); 
   user_group_add ('intranet', 'Partners', 'partner', 'f'); 
   user_group_add ('intranet', 'Authorized Users', 'authorized_users', 'f'); 
end;
/
show errors;

-- Set up the project types
insert into im_project_types
(project_type_id, project_type, display_order) 
values
(im_project_types_id_seq.nextVal, 'Client', 1);

insert into im_project_types
(project_type_id, project_type, display_order) 
values
(im_project_types_id_seq.nextVal, 'Sales', 2);

insert into im_project_types
(project_type_id, project_type, display_order) 
values
(im_project_types_id_seq.nextVal, 'Internal', 3);

insert into im_project_types
(project_type_id, project_type, display_order) 
values
(im_project_types_id_seq.nextVal, 'Toolkit', 4);

-- set up the project status
insert into im_project_status 
(project_status_id, project_status, display_order) 
values
(im_project_status_id_seq.nextVal, 'Open', 1);

insert into im_project_status 
(project_status_id, project_status, display_order) 
values
(im_project_status_id_seq.nextVal, 'Future', 2);

insert into im_project_status 
(project_status_id, project_status, display_order) 
values
(im_project_status_id_seq.nextVal, 'Inactive', 3);

insert into im_project_status 
(project_status_id, project_status, display_order) 
values
(im_project_status_id_seq.nextVal, 'Closed', 4);

insert into im_project_status 
(project_status_id, project_status, display_order) 
values
(im_project_status_id_seq.nextVal, 'Deleted', 5);



-- set up the types of urls we ask for
insert into im_url_types
(url_type_id, url_type, to_ask, to_display, display_order)
values 
(im_url_types_type_id_seq.nextVal, 'website', 'Service URL', 'URL', 1);

insert into im_url_types
(url_type_id, url_type, to_ask, to_display, display_order)
values 
(im_url_types_type_id_seq.nextVal, 'staff', 'Staff URL', 'Staff Server', 2);

insert into im_url_types
(url_type_id, url_type, to_ask, to_display, display_order)
values 
(im_url_types_type_id_seq.nextVal, 'development', 'Development URL', 'Development Server', 3);

insert into im_url_types
(url_type_id, url_type, to_ask, to_display, display_order)
values 
(im_url_types_type_id_seq.nextVal, 'staging', 'Staging URL', 'Staging Server', 4);

insert into im_url_types
(url_type_id, url_type, to_ask, to_display, display_order)
values 
(im_url_types_type_id_seq.nextVal, 'glassroom', 'Glassroom URL', 'Glassroom', 5);


insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Current', 1);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Inquiries', 2);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Creating Bid', 3);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Bid out', 4);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Bid and Lost', 5);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Past', 6);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Declined', 7);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Non-converted', 8);

insert into im_customer_status
(customer_status_id, customer_status, display_order)
values
(im_customer_status_seq.nextVal, 'Potential', 9);

-- now for the different types a partner can have
insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Usability', 1);

insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Graphics', 2);

insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Strategy', 3);

insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Supplier', 4);

insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Sys-admin', 5);

insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Hosting', 6);

insert into im_partner_types
(partner_type_id, partner_type,display_order)
values
(im_partner_types_seq.nextVal, 'Systems Integrator', 7);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Targeted', 1);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'In Discussion', 2);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Active', 3);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Announced', 4);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Dormant', 5);

insert into im_partner_status 
(partner_status_id, partner_status, display_order)
values
(im_partner_status_id_seq.nextVal, 'Dead', 6);


