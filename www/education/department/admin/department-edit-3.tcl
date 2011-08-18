#
# /www/education/department/admin/department-edit-3.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# this page allows the user to edit informaiton about a department
#

ad_page_variables {
    group_name
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

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


set exception_text ""
set exception_count 0

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


if {[string compare $external_homepage_url "http://"] == 0} {
    set QQexternal_homepage_url ""
}


# now that all of the input has been check, lets update the row


ns_db dml $db "update edu_department_info 
                   set department_number = '$QQdepartment_number',
                       external_homepage_url = '$QQexternal_homepage_url',
                       mailing_address = '$QQmailing_address',
                       phone_number = '$QQphone_number',
                       fax_number = '$QQfax_number',
                       inquiry_email = '$QQinquiry_email',
                       description = '$QQdescription',
                       mission_statement = '$QQmission_statement',
      	               last_modified = sysdate,
                       last_modifying_user = $user_id,
                       modified_ip_address = '[ns_conn peeraddr]'                       
                 where group_id = $department_id"


ns_db releasehandle $db

ad_returnredirect ""














