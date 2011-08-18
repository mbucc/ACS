#
# /www/education/util/users/password-update-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page updates the user's password and tells the user it has done so
#

ad_page_variables {
    password_1
    password_2
    user_id
    first_names
    last_name
    {return_url ""}
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
	set id_list [edu_group_security_check $db edu_class "Manage Users"]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}

# gets the group_id.  If the user is not an admin of the group, it
# displays the appropriate error message and returns so that this code
# does not have to check the group_id to make sure it is valid

set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]


set exception_text ""
set exception_count 0

if {[empty_string_p $user_id]} {
    incr exception_count
    append exception_text "<li>You must provide an user identification number for this page to be displayed."
}


if { [empty_string_p $password_1] } {
    append exception_text "<li>You need to type in a password\n"
    incr exception_count
}

if { [empty_string_p $password_2] } {
    append exception_text "<li>You need to confirm the password that you typed.  (Type the same thing again.) \n"
    incr exception_count
}


if { [string compare $password_2 $password_1] != 0 } {
    append exception_text "<li>Your passwords don't match!  Presumably, you made a typo while entering one of them.\n"
    incr exception_count
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}


# If we are encrypting passwords in the database, do it now.
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set password_1 [ns_crypt $password_1 [ad_crypt_salt]]
}

set sql "update users set password = [ns_dbquotevalue $password_1] where user_id = $user_id"

if [catch { ns_db dml $db $sql } errmsg] {
    ad_return_error "Ouch!"  "The database choked on our update:
<blockquote>
$errmsg
</blockquote>
"
} else {

    if {[info exists return_url] && ![empty_string_p $return_url]} {
	set return_url_var $return_url
    } else {
	set return_url_var "one.tcl?user_id=$user_id"
    }

    ns_return 200 text/html "[ad_header "$group_name @ [ad_system_name]"]

<h2>Password Updated</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" Administration] [list "" Users] "Update Password"]

<hr>
<blockquote>

You can return to <a href=\"$return_url_var\">$first_names $last_name</a>

</blockquote>

[ad_footer]
"
}
