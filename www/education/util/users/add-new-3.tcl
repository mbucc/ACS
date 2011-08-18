#
# /www/education/util/users/add-new-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page enters the new user into the database and the class
# it then mails the user a temporary password to access the site
#

ad_page_variables {
    email
    first_names
    last_name
    {user_url ""}
    new_user_id
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

set list_to_check [list [list email email] [list first_names "first name"] [list last_name "last name"] [list new_user_id "User Id"] [list role Role]]

foreach item $list_to_check {
    if {[empty_string_p [set [lindex $item 0]]]} {
	incr exception_count
	append exception_text "<li>You must provide the user's [lindex $item 1].\n"
    }
}

if {[string compare $user_url "http://"] == 0} {
    set user_url ""
}

#see if the email address is already in use
#make it so that it is not case sensative
set used_email [database_to_tcl_string_or_null $db "select email from users where lower(email) = lower('$email')"]

if {![empty_string_p $used_email]} {
    incr exception_count
    append exception_text "<li>The person owning the email address $email is already a user of [ad_system_name].  To add this person to your $group_pretty_type, please use the search function provided at the <a href=\"add.tcl\">add user</a> page."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


if {[ad_parameter RegistrationRequiresApprovalP "" 0] || [ad_parameter RegistrationRequiresEmailVerification "" 0]} {
    # we require approval by site admin before registration is 
    # effective
    set approved_p "f"
} else {
    # let this guy go live immediately
    # (approving_user will be NULL)
    set approved_p "t"
}



# Autogenerate a password

set password [ad_generate_random_string]

# If we are encrypting passwords in the database, convert
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set password_for_database [DoubleApos [ns_crypt $password [ad_crypt_salt]]]
} else {
    set password_for_database $password
}


set insert_statement  "insert into users 
(user_id,email,password,first_names,last_name,url,registration_date,registration_ip, user_state) 
values 
($new_user_id,[ns_dbquotevalue $email],[ns_dbquotevalue $password_for_database],[ns_dbquotevalue $first_names],[ns_dbquotevalue $last_name],[ns_dbquotevalue $user_url], sysdate, '[ns_conn peeraddr]', 'authorized')"



# let's look for other required tables

set insert_statements_sup ""

set other_tables [ad_parameter_all_values_as_list RequiredUserTable]
foreach table_name $other_tables {
    lappend insert_statements_sup "insert into $table_name (user_id) values ($new_user_id)"
}

set double_click_p 0

if [catch { ns_db dml $db "begin transaction"
            ns_db dml $db $insert_statement
    } errmsg] {
	# if it was not a double click, produce an error
	if { [database_to_tcl_string $db "select count(user_id) from users where user_id = $new_user_id"] == 0 } {
	    ad_return_error "Insert Failed" "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return 
       } else {
	   # assume this was a double click
	   set double_click_p 1
       }
   }



if { $double_click_p == 0 } {
    if [catch { 
	foreach statement $insert_statements_sup {
	    ns_db dml $db $statement
	}
	ns_db dml $db "end transaction"
    } errmsg] {
	ad_return_error "Insert Failed" "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return
    }
}


#This is the email of the person adding the new user
set selection [ns_db 1row $db "select email as admin_email, first_names as admin_first_names, last_name as admin_last_name from users where user_id = '$user_id'"]
set_variables_after_query


if { !$double_click_p } {
    set rowid [database_to_tcl_string $db "select rowid from users where user_id = $new_user_id"]
    # the user has to come back and activate their account
    ns_sendmail  "$email" "$admin_email" "Welcome to [ad_system_name]" "$admin_first_names $admin_last_name has added you as a user of [ad_system_name] and a member of $group_name.  To confirm your registration, please go to [ad_parameter SystemURL]/register/email-confirm.tcl?[export_url_vars rowid]

Your password is '$password'  Please change this the first time you log in."
}


ad_user_group_user_add $db $new_user_id $role $group_id


set return_string "
[ad_header "Add User @ [ad_system_name]"]

<h2> Confirm Add User for $group_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$group_name Home"] [list "../" "Administration"] [list "" Users] "Add a New User"]

<hr>
<blockquote>

$first_names $last_name has been added to $group_name.

<p>

You may now
<a href=\"one.tcl?user_id=$new_user_id\">
View User Information</a> for $first_names $last_name
or
<a href=\"\">Return to the Users Page</a>
</blockquote>

[ad_footer]
"

ns_return 200 text/html $return_string

