#
# /www/admin/education/department-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add a new department to the system
# this page actually does the insert
#


ad_page_variables {
    group_name
    group_id
    {department_number ""}
    {external_homepage_url ""}
    {mailing_address ""}
    {phone_number ""}
    {fax_number ""}
    {inquiry_email ""}
    {description ""}
    {mission_statement ""}
}


set db [ns_db gethandle]

# lets make sure this is not a double-click.  If so, just redirect the user

if {[empty_string_p $group_id]} {
    append exception_text "<li> You must provide an identification nubmer for the new department."
    incr exception_count
} else {
    if {[database_to_tcl_string $db "select count(group_id) from user_groups where group_id = $group_id"] > 0} {
	ad_returnredirect ""
    }
}

# check and make sure we received all of the input we were supposed to

set exception_text ""
set exception_count 0

# group_name is the only one that cannot be null

if {[empty_string_p $group_name]} {
    append exception_text "<li> You must provide a name for the new department."
    incr exception_count
}


# if an email is provided, make sure that it is of the correct for.

if {[info exists inquiry_email] && ![empty_string_p $inquiry_email] && ![philg_email_valid_p $inquiry_email]} {
    incr exception_count
    append exception_text "<li>The inquiry email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}


# if a phone number is provided, check its form

if {[info exists phone_number] && ![empty_string_p $phone_number] && ![edu_phone_number_p $phone_number]} {
    incr exception_count
    append exception_text "<li> The phone number you have entered is not in the correct form.  It must be of the form XXX-XXX-XXXX \n"
}


# if a fax nubmer is provided, check its form

if {[info exists fax_number] && ![empty_string_p $fax_number] && ![edu_phone_number_p $fax_number]} {
    incr exception_count
    append exception_text "<li> The fax number you have entered is not in the correct form.  It must be of the form XXX-XXX-XXXX \n"
}



if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


if {[empty_string_p $external_homepage_url]} {
    set external_homepage_url ""
}


# now that all of the input has been check, lets put the information into
# an ns_set


set var_set [ns_set new]

ns_set put $var_set department_number $department_number
ns_set put $var_set external_homepage_url $external_homepage_url
ns_set put $var_set mailing_address $mailing_address
ns_set put $var_set phone_number $phone_number
ns_set put $var_set fax_number $fax_number
ns_set put $var_set inquiry_email $inquiry_email
ns_set put $var_set description $description
ns_set put $var_set mission_statement $mission_statement


ad_user_group_add $db edu_department $group_name t f closed f $var_set $group_id

ns_db releasehandle $db

ad_returnredirect ""






















