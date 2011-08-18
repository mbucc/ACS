#
# /www/education/util/users/add-new.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to select the correct role for the
# user and it also checks to make sure the user is not already in
# the system
#

ad_page_variables {
    email
    first_names
    last_name
    {user_url ""}
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

set list_to_check [list [list email email] [list first_names "first name"] [list last_name "last name"]]

foreach item $list_to_check {
    if {[empty_string_p [set [lindex $item 0]]]} {
	incr exception_count
	append exception_text "<li>You must provide the user's [lindex $item 1]\n"
    }
}


if {[string compare $user_url "http://"] == 0} {
    set user_url ""
}

set email [string trim $email]

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


# see if the email address is already in use
# make it so that it is not case sensitive
set used_email [database_to_tcl_string_or_null $db "select email from users where lower(email) = lower('$email')"]

if {![empty_string_p $used_email]} {

    #if this is the case, bounce the person over so that it is like they
    #performed the search on the user.
    set selection [ns_db 1row $db "select user_id as user_id_to_add, first_names, last_name, deleting_user, banning_user from users where lower(email) = lower ('$email')"]
    set_variables_after_query

    if { [empty_string_p $banning_user] && [empty_string_p $deleting_user] } {
	ad_returnredirect user-add-3.tcl?[export_url_vars user_id_to_add first_names last_name user_url]
	return
    } else {
	# This user was deleted or banned
	incr exception_count
	append exception_text "<li>User $email was deleted or banned.\n"
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


#NOW THAT THE AUTHORIZATION IS TAKEN CARE, GET OF THE ROLE

set return_string "
[ad_header "$group_name @ [ad_system_name]"]


<h2>Select Roles for $first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a New User"]

<hr>


<form method=post action=\"add-new-2.tcl\">
[export_entire_form]

<blockquote>

[edu_group_user_role_select_widget $db role $group_id ""]

<p>
<input type=submit name=action value=\"Continue\">

</form>
</blockquote>

[ad_footer]
"

ns_db releasehandle $db 

ns_return 200 text/html $return_string
