# $Id: info-update-2.tcl,v 3.0.4.2 2000/04/28 15:11:11 carsten Exp $
# File: /www/intranet/users/info-update-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: stores intranet info about a user to the db
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_the_usual_form_variables 0
# return_url, office_id, dp variables

set required_vars [list \
	[list dp.users.first_names "You must enter your first name"] \
	[list dp.users.last_name "You must enter your last name"] \
	[list dp.users.email.email "You must enter your email address"]]

set exception_text [im_verify_form_variables $required_vars]
# $required_vars]

if { ![empty_string_p ${dp.users.email.email}] && ![philg_email_valid_p ${dp.users.email.email}] } {
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}

if { ![empty_string_p $exception_text] } {
    ad_return_complaint 2 "<ul>$exception_text</ul>"
    return
}

# We have all the data - do the updates

set form_setid [ns_getform]

# In case we have to insert the row, we need to stick the user_id in the set
ns_set put $form_setid "dp.users_contact.user_id" $user_id
ns_set put $form_setid "dp.im_employee_info.user_id" $user_id

set db [ns_db gethandle]

# Create/update the mapping between between this users and the office
# Note: group_name, creation_user, creation_date are all set in ae.tcl
ns_set put $form_setid "dp_ug.user_group_map.group_id" $office_id
ns_set put $form_setid "dp_ug.user_group_map.user_id" $user_id
ns_set put $form_setid "dp_ug.user_group_map.registration_date.expr" sysdate
ns_set put $form_setid "dp_ug.user_group_map.mapping_user" $user_id
ns_set put $form_setid "dp_ug.user_group_map.mapping_ip_address" [ns_conn peeraddr]

ns_db dml $db "begin transaction"

# First delete this users mappings in user_group_map (for offices)
ns_db dml $db "delete from user_group_map where user_id=$user_id and group_id in (select group_id from user_groups where parent_group_id=[im_office_group_id])"

if { ![empty_string_p $office_id] } {
    # And replace with the new office
    dp_process -db $db -form_index "_ug" -where_clause "user_id=$user_id and group_id=$office_id"
}

# Now add to the users, users_contact, and im_employee_info tables
dp_process -db $db -where_clause "user_id=$user_id"

ns_db dml $db "end transaction"

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect view.tcl
}
