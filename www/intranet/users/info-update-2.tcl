# /www/intranet/users/info-update-2.tcl

ad_page_contract {
    Purpose: stores intranet info about a user to the db

    @param office_id
    @param return_url
    @param db:array

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id info-update-2.tcl,v 3.5.2.9 2000/08/16 21:25:05 mbryzek Exp
} {
    { office_id:integer "" }
    { return_url "view" }
    { dp.users.first_names "" }
    { dp.users.last_name "" }
    { dp.users.email.email "" }
    { dp.users.url "" }
    { dp.users_contact.aim_screen_name "" }
    { dp.users_contact.icq_number "" }
    { dp.users_contact.home_phone "" }
    { dp.users_contact.work_phone "" }
    { dp.users_contact.cell_phone "" }
    { dp.users_contact.ha_line1 "" }
    { dp.users_contact.ha_line2 "" }
    { dp.users_contact.ha_city "" }
    { dp.users_contact.ha_state "" }
    { dp.users_contact.ha_postal_code "" }
    { dp.im_employee_info.educational_history:html "" }
    { dp.users.bio:html "" }
    { dp.im_employee_info.skills:html "" }
    { dp.im_employee_info.years_experience.integer "" }
    { dp.im_employee_info.resume.clob:html "" }
    { dp.im_employee_info.resume_html_p "" }
    { dp.users_contact.note "" }
    { dp.im_employee_info.featured_employee_blurb.clob:html "" }
    { dp.im_employee_info.featured_employee_blurb_html_p "" }
    { dp.im_employee_info.recruiting_blurb.clob:html "" }
    { dp.im_employee_info.recruiting_blurb_html_p "" }
    { dp.im_employee_info.last_degree_completed "" }
    { dp.users_contact.user_id "" }
    { dp.im_employee_info.user_id "" }
}

set user_id [ad_maybe_redirect_for_registration]


set required_vars [list \
	[list dp.users.first_names "You must enter your first name"] \
	[list dp.users.last_name "You must enter your last name"] \
	[list dp.users.email.email "You must enter your email address"]]

set exception_text [im_verify_form_variables $required_vars]

if { ![empty_string_p ${dp.users.email.email}] && ![philg_email_valid_p ${dp.users.email.email}] } {
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
} else {
    # Make sure the email address, if changed, is unique
    set user_email [string toupper ${dp.users.email.email}]
    set exists_p [db_string check_email_unique \
	    "select decode(count(1),0,0,1) 
               from users 
              where upper(email)=:user_email
                and user_id <> :user_id" ]
    if { $exists_p } {
	append exception_text "  <li> The email address that you entered is not unique. Please enter a unique email address\n"
    }
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

set where_bind [ns_set create]
ns_set put $where_bind user_id $user_id

# Add to the users, users_contact, and im_employee_info tables
dp_process -where_clause "user_id=:user_id" -where_bind $where_bind

ns_set free $where_bind

db_release_unused_handles
ad_returnredirect $return_url
