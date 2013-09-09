# /www/intranet/customers/ae-2.tcl

ad_page_contract {
    Writes all the customer information to the db. 

    @param group_id The group this customer belongs to 
    @param start Date this customer starts.
    @param return_url The Return URL
    @param dp_ug.user_groups.creation_ip_address IP Address of the creating user (if we're creating this group)
    @param dp_ug.user_groups.creation_user User ID of the creating user (if we're creating this group)
    @param dp_ug.user_groups.group_name Customer's name
    @param dp_ug.user_groups.short_name Group short name for things like email aliases
    @param dp.im_customers.referral_source How did this customer find us
    @param dp.im_customers.customer_status_id What's the customer's status
    @param dp.im_customers.customer_type_id The type of the customer
    @param dp.im_customers.annual_revenue.money How much they make
    @param dp.im_customers.note General notes about the customer

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id ae-2.tcl,v 3.6.2.19 2001/01/12 17:18:31 khy Exp

} {
    group_id:integer,notnull,verify
    { return_url "" }
    { dp_ug.user_groups.group_id "" }
    { dp_ug.user_groups.group_type "" }
    { dp_ug.user_groups.approved_p "" }
    { dp_ug.user_groups.new_member_policy "" }
    { dp_ug.user_groups.parent_group_id "" }
    { dp_ug.user_groups.modification_date.expr "" }
    { dp_ug.user_groups.modification_date.modifying_user "" }
    { dp_ug.user_groups.creation_ip_address "" }
    { dp_ug.user_groups.creation_user "" }
    { dp_ug.user_groups.group_name "" }
    { dp_ug.user_groups.short_name "" }
    { dp_ug.user_groups.modifying_user "" }
    { dp.im_customers.referral_source "" }
    { dp.im_customers.customer_status_id:integer "" }
    { dp.im_customers.customer_type_id:integer "" }
    { dp.im_customers.annual_revenue.money "" }
    { dp.im_customers.note "" }
    { dp.im_customers.contract_value.money "" }
    { dp.im_customers.site_concept "" }
    { dp.im_customers.manager "" }
    { dp.im_customers.billable_p "" }
    { dp.im_customers.group_id "" }
    { dp.im_customers.start_date "" }
    { start:array,date "" }
    { dp.im_customers.old_customer_status_id "" }
    { dp.im_customers.status_modification_date.expr "" }
}

set user_id [ad_maybe_redirect_for_registration]

set required_vars [list \
	[list "dp_ug.user_groups.group_name" "You must specify the customer's name"] \
	[list "dp_ug.user_groups.short_name" "You must specify a short name"]]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    incr exception_count
}


if { [string length ${dp.im_customers.note}] > 4000 } {
    incr exception_count
    append errors "  <li> The note you entered is too long. Please limit the note to 4000 characters\n"
}


# Periods don't work in bind variables...
set short_name ${dp_ug.user_groups.short_name}
# Make sure customer name is unique
set exists_p [db_string group_exists_p \
	"select decode(count(1),0,0,1) 
           from user_groups 
          where lower(trim(short_name))=lower(trim(:short_name))
            and group_id != :group_id"]

if { $exists_p } {
    incr exception_count
    append errors "  <li> The specified customer short name already exists. Either choose a new name or go back to the customer's page to edit the existing record\n"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count "<ul>$errors</ul>"
    return
}

set form_setid [ns_getform]

if { [info exists start(date)] } {
    ns_set put $form_setid dp.im_customers.start_date $start(date)
}

# Create/update the user group frst since projects reference it
# Note: group_name, creation_user, creation_date are all set in ae
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
set old_status_id [db_string customer_previous_status \
	"select customer_status_id from im_customers where group_id=:group_id" -default "" ]
if { ![empty_string_p $old_status_id] && $old_status_id != ${dp.im_customers.customer_status_id} } {
    ns_set put $form_setid "dp.im_customers.old_customer_status_id" $old_status_id
    ns_set put $form_setid "dp.im_customers.status_modification_date.expr" sysdate
}


# Create an ns set of the variables to bind for the where clause
set bind_vars [ns_set create]
ns_set put $bind_vars group_id $group_id

# Update user_groups
dp_process -form_index "_ug" -where_clause "group_id=:group_id" -where_bind $bind_vars

# Now update im_customers
dp_process -where_clause "group_id=:group_id" -where_bind $bind_vars

ns_set free $bind_vars

if { ![exists_and_not_null return_url] } {
    set return_url [im_url_stub]/customers/view?[export_url_vars group_id]
}

db_release_unused_handles

if { ![empty_string_p ${dp_ug.user_groups.creation_user}] } {
    # add the creating current user to the group
    ad_returnredirect "[im_url_stub]/member-add-3?[export_url_vars group_id return_url]&user_id_from_search=$user_id&role=administrator"
} else {
    ad_returnredirect $return_url
}
