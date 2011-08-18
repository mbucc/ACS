# $Id: user-add-2.tcl,v 3.1.2.1 2000/04/28 15:09:37 carsten Exp $
set_the_usual_form_variables

set admin_user_id [ad_verify_and_get_user_id]

if { $admin_user_id == 0 } {
    ad_returnredirect /register.tcl?return_url=[ns_urlencode "/admin/users/"]
    return
}

# email first_names last_name, user_id

# Error Count and List
set exception_count 0
set exception_text ""

# Check input

if {![info exists user_id] || [empty_string_p $user_id] } {
    incr exception_count
    append exception_text "<li>Your browser dropped the user_id variable or something is wrong with our code.\n"
}

set db [ns_db gethandle]

if {![info exists email] || ![philg_email_valid_p $email]} {
    incr exception_count
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
} else {

    set email_count [database_to_tcl_string $db "select count(email)
from users where upper(email) = '[string toupper $QQemail]' 
and user_id <> $user_id"]

    # note, we dont' produce an error if this is a double click
    if {$email_count > 0} {
	incr exception_count
	append exception_text "$email was already in the database."
    }

}


if {![info exists first_names] || [empty_string_p $first_names]} {
    incr exception_count
    append exception_text "<li> You didn't enter a first name."
}

if {![info exists last_name] || [empty_string_p $last_name]} {
    incr exception_count
    append exception_text "<li> You didn't enter a last name."
}

# We've checked everything.
# If we have an error, return error page, otherwise, do the insert

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set password [ad_generate_random_string]
set QQpassword [DoubleApos $password]

# If we are encrypting passwords in the database, convert
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set QQpassword_for_database [DoubleApos [ns_crypt $password [ad_crypt_salt]]]
} else {
    set QQpassword_for_database $QQpassword
}

set insert_statement  "insert into users 
(user_id,email,password,first_names,last_name,registration_date,registration_ip, user_state) 
values 
($user_id,'$QQemail','$QQpassword_for_database','$QQfirst_names','$QQlast_name', sysdate, '[ns_conn peeraddr]', 'authorized')"


if [catch { ns_db dml $db $insert_statement } errmsg] {
    # if it was not a double click, produce an error
    if { [database_to_tcl_string $db "select count(user_id) from users where user_id = $user_id"] == 0 } {
	ad_return_error "Insert Failed" "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return 
     }
}

set administration_name [database_to_tcl_string $db "select
first_names || ' ' || last_name from users where user_id = $admin_user_id"]


append whole_page "[ad_admin_header "Add a user"]

<h2>Add a user</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "Notify added user"]

<hr>

$first_names $last_name has been added to [ad_system_name].
Edit the message below and hit \"Send Email\" to 
notify this user.

<p>
<form method=POST action=\"user-add-3.tcl\">
[export_form_vars email first_names last_name user_id]
Message:

<p>

<textarea name=message rows=10 cols=70 wrap=hard>
$first_names $last_name, 

You have been added as a user to [ad_system_name] 
at [ad_parameter SystemUrl].

Login information:
Email: $email
Password: $password 
(you may change your password after you log in)

Thank you,
$administration_name
</textarea>

<p>

<center>

<input type=submit value=\"Send Email\">

</center>

</form>
<p>


[ad_admin_footer]
"
ns_db releasehandle $db
ns_return 200 text/html $whole_page
