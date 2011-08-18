#
# /www/education/util/users/add-new-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page is a confirmation page so the admin can make sure that
# all of the information is correct.
#

ad_page_variables {
    email
    first_names
    last_name
    {user_url ""}
    role
}


set db [ns_db gethandle]

set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    if {[string compare $group_pretty_type class] == 0} {
	set id_list [edu_user_security_check $db]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}


set user_id [lindex $id_list 0]
set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


set exception_text ""
set exception_count 0

set list_to_check [list [list email email] [list first_names "first name"] [list last_name "last name"] [list role Role]]

foreach item $list_to_check {
    if {[empty_string_p [set [lindex $item 0]]]} {
	incr exception_count
	append exception_text "<li>You must provide the user's [lindex $item 1]\n"
    }
}


if {[string compare $user_url "http://"] == 0} {
    set user_url ""
}

if {![philg_email_valid_p $email]} {
    incr exception_count
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}


if {![empty_string_p $user_url] && ![philg_url_valid_p $user_url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}


#see if the email address is already in use
#make it so that it is not case sensative

set used_email [database_to_tcl_string_or_null $db "select email from users where lower(email) = lower('$email')"]

if {![empty_string_p $used_email]} {
    incr exception_count
    append exception_text "<li>The person owning the email address $email is already a user of [ad_system_name].  To add this person to your company, please use the search function provided at the <a href=user-add.tcl>add user</a> page."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


#create the user_id
set new_user_id [database_to_tcl_string $db "select user_id_sequence.nextval from dual"]


set return_string "
[ad_header "$group_name @ [ad_system_name]"]

<h2>Verify User Information</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a New User"]

<hr>

<blockquote>

<p>
<B>New user's email address:</b> $email
<p>
<B>Full name:</b> $first_names $last_name
<p>
<b>Role:</b> [capitalize $role]
<p>

When you add a user, the user receives email notification and
a temporary password.

</p>

<form method=post action=\"add-new-3.tcl\">

[export_form_vars new_user_id role email first_names last_name user_url]

<input type=submit name=action value=\"Add User\"></form>

</blockquote>

[ad_footer]
"

ns_return 200 text/html $return_string


