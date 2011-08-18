# $Id: ae-2.tcl,v 3.2.2.2 2000/04/28 15:11:05 carsten Exp $
# File: /www/intranet/customers/ae-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Writes all the customer information to the db. 
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# Bunch of stuff for dp

set required_vars [list \
	[list "dp_ug.user_groups.group_name" "You must specify the customer's name"]]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    incr exception_count
}

set db [ns_db gethandle]

# Make sure customer name is unique
set exists_p [database_to_tcl_string $db \
	"select decode(count(1),0,0,1) 
           from user_groups 
          where lower(trim(short_name))=lower(trim('[DoubleApos ${dp_ug.user_groups.short_name}]'))
            and group_id != $group_id"]

if { $exists_p } {
    incr exception_count
    append errors "  <li> The specified customer short name already exists. Either choose a new name or go back to the customer's page to edit the existing record\n"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count "<ul>$errors</ul>"
    return
}

set form_setid [ns_getform]

# Create/update the user group frst since projects reference it
# Note: group_name, creation_user, creation_date are all set in ae.tcl
ns_set put $form_setid "dp_ug.user_groups.group_id" $group_id
ns_set put $form_setid "dp_ug.user_groups.group_type" [ad_parameter IntranetGroupType intranet]
ns_set put $form_setid "dp_ug.user_groups.approved_p" "t"
ns_set put $form_setid "dp_ug.user_groups.new_member_policy" "closed"
ns_set put $form_setid "dp_ug.user_groups.parent_group_id" [im_customer_group_id]

# Log the modification date
ns_set put $form_setid "dp_ug.user_groups.modification_date.expr" sysdate
ns_set put $form_setid "dp_ug.user_groups.modifying_user" $user_id

# Put the group_id into projects
ns_set put $form_setid "dp.im_customers.group_id" $group_id

# Log the change in state if necessary
set old_status_id [database_to_tcl_string_or_null $db \
	"select customer_status_id from im_customers where group_id=$group_id"]
if { ![empty_string_p $old_status_id] && $old_status_id != ${dp.im_customers.customer_status_id} } {
    ns_set put $form_setid "dp.im_customers.old_customer_status_id" $old_status_id
    ns_set put $form_setid "dp.im_customers.status_modification_date.expr" sysdate
}

ns_db dml $db "begin transaction"

# Update user_groups
dp_process -db $db -form_index "_ug" -where_clause "group_id=$group_id"

# Now update im_projects
dp_process -db $db -where_clause "group_id=$group_id"

ns_db dml $db "end transaction"


if { ![exists_and_not_null return_url] } {
    set return_url [im_url_stub]/customers/view.tcl?[export_url_vars group_id]
}

if { [exists_and_not_null dp_ug.user_groups.creation_user] } {
    # add the creating current user to the group
    ad_returnredirect "/groups/member-add-3.tcl?[export_url_vars group_id return_url]&user_id_from_search=$user_id&role=administrator"
} else {
    ad_returnredirect $return_url
}
