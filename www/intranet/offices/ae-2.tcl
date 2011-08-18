# $Id: ae-2.tcl,v 3.0.4.2 2000/04/28 15:11:08 carsten Exp $
# File: /www/intranet/offices/ae-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
# 
# Saves office info to db
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id, group_name, short_name, Bunch of stuff for dp

if { ![exists_and_not_null group_id] }  {
    ad_return_error "We've lost the office's group id" "Please back up, hit reload, and try again."
    return
}
 
set required_vars [list \
	[list group_name "You must specify the office's name"] \
	[list short_name "You must specify the office's short name"]]

set errors [im_verify_form_variables $required_vars]

set exception_count 0
if { ![empty_string_p $errors] } {
    set exception_count 1
}

set db [ns_db gethandle]

# Make sure short name is unique - this is enforced in user groups since short_name 
# must be unique for different UI stuff
if { ![empty_string_p $short_name] } {
    set exists_p [database_to_tcl_string $db \
	    "select decode(count(1),0,0,1) 
               from user_groups 
              where lower(trim(short_name))=lower(trim('[DoubleApos ${short_name}]'))
                and group_id != $group_id"]

    if { $exists_p } {
	incr exception_count
	append errors "  <li> The specified short name already exists for another user group. Please choose a new short name\n"
    }
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count $errors
    return
}

set form_setid [ns_getform]

# Create/update the user group frst since projects reference it
# Note: group_name, creation_user, creation_date are all set in ae.tcl
ns_set put $form_setid "dp_ug.user_groups.group_id" $group_id
ns_set put $form_setid "dp_ug.user_groups.group_type" [ad_parameter IntranetGroupType intranet]
ns_set put $form_setid "dp_ug.user_groups.approved_p" "t"
ns_set put $form_setid "dp_ug.user_groups.new_member_policy" "closed"
ns_set put $form_setid "dp_ug.user_groups.parent_group_id" [util_memoize {im_group_id_from_parameter OfficeGroupShortName}]
ns_set put $form_setid "dp_ug.user_groups.group_name" $group_name
ns_set put $form_setid "dp_ug.user_groups.short_name" $short_name

# Put the group_id into the office information
ns_set put $form_setid "dp.im_offices.group_id" $group_id

ns_db dml $db "begin transaction"

# Update user_groups
dp_process -db $db -form_index "_ug" -where_clause "group_id=$group_id"

# Now update im_offices
dp_process -db $db -where_clause "group_id=$group_id"

ns_db dml $db "end transaction"

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect index.tcl
}
