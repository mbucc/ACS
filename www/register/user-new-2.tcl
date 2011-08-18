# $Id: user-new-2.tcl,v 3.6.2.2 2000/04/28 15:11:25 carsten Exp $
#
# user-new-2.tcl
#
# actually inserts the new user into the database
#

ad_handle_spammers

set_the_usual_form_variables

# email password first_names last_name url, user_id, possibly return_url

if ![info exists return_url] {
    set return_url [ad_pvt_home]
}

# Error Count and List
set exception_count 0
set exception_text ""

# Check input

if {![info exists user_id] || [empty_string_p $user_id] } {
    incr exception_count
    append exception_text "<li>Your browser dropped the user_id variable or something is wrong with our code.\n"
}

if {![info exists email] || ![philg_email_valid_p $email]} {
    incr exception_count
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}

if {(![info exists password] || [empty_string_p $QQpassword]) && ![ad_parameter RegistrationProvidesRandomPasswordP "" 0] } {
    incr exception_count
    append exception_text "<li> You didn't enter a password."
}


if {(![info exists password_confirmation] || ![info exists password] || $password != $password_confirmation) && ![ad_parameter RegistrationProvidesRandomPasswordP "" 0] } {
    incr exception_count
    append exception_text "<li> Your password and password confirmation do not match."
}


if {![info exists first_names] || [empty_string_p $QQfirst_names]} {
    incr exception_count
    append exception_text "<li> You didn't enter a first name."
}

if {![info exists last_name] || [empty_string_p $QQlast_name]} {
    incr exception_count
    append exception_text "<li> You didn't enter a last name."
}

if {[info exists first_names] && [string first "<" $first_names] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your first name because it will look like an HTML tag and confuse other users."
}

if {[info exists last_name] && [string first "<" $last_name] != -1} {
    incr exception_count
    append exception_text "<li> You can't have a &lt; in your last name because it will look like an HTML tag and confuse other users."
}

if { [info exists url] && [string match $url "http://"] ==  1 } {
    # the user left the default hint for the url
    set url ""
    set QQurl ""
}

if {[info exists url] && ![empty_string_p $url] && ![philg_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}

# We've checked everything.
# If we have an error, return error page, otherwise, do the insert

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

set authorized_p 0

if {[ad_parameter RegistrationRequiresApprovalP "" 0] && [ad_parameter RegistrationRequiresEmailVerificationP "" 0]} {
    set user_state "need_email_verification_and_admin_approv"
} elseif {[ad_parameter RegistrationRequiresApprovalP "" 0]} {
    set user_state "need_admin_approv"
} elseif {[ad_parameter RegistrationRequiresEmailVerificationP "" 0]} {
    set user_state "need_email_verification"
} else {
    set user_state "authorized"
    set authorized_p 1
}

# Autogenerate a password

if  {[ad_parameter RegistrationProvidesRandomPasswordP "" 0]} {
    set password [ad_generate_random_string]
    set QQpassword [DoubleApos $password]
}

# If we are encrypting passwords in the database, convert
if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set QQpassword_for_database [DoubleApos [ns_crypt $password [ad_crypt_salt]]]
} else {
    set QQpassword_for_database $QQpassword
}

set insert_statement  "insert into users 
(user_id,email,password,first_names,last_name,url,registration_date,registration_ip, user_state, last_visit) 
values 
($user_id,'$QQemail','$QQpassword_for_database','$QQfirst_names','$QQlast_name','$QQurl', sysdate, '[ns_conn peeraddr]', '$user_state', sysdate)"


# let's look for other required tables

set insert_statements_sup ""

set other_tables [ad_parameter_all_values_as_list RequiredUserTable]
foreach table_name $other_tables {
    lappend insert_statements_sup "insert into $table_name (user_id) values ($user_id)"
}

set double_click_p 0

set db [ns_db gethandle]

with_catch errmsg {
    ns_db dml $db "begin transaction"
    ns_db dml $db $insert_statement
} {
    # if it was not a double click, produce an error
    if { [database_to_tcl_string $db "select count(user_id) from users where user_id = $user_id"] == 0 } {
	ns_db releasehandle $db
	ad_return_error "Insert Failed" "We were unable to create your user record in the database."
	ns_log Error "Error insert new user:
$errmsg"
	return 
    } else {
	# assume this was a double click
	set double_click_p 1
    }
}



if { $double_click_p == 0 } {
    with_catch errmsg {
	foreach statement $insert_statements_sup {
	    ns_db dml $db $statement
	}
	ns_db dml $db "end transaction"
    } {
	ns_db releasehandle $db
	ad_return_error "Insert Failed" "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return
    }
}

if { $authorized_p } {
    # user is ready to go

    # we have to be careful here with the password; we put a string-trimmed
    # version into the RDBMS so we must do the same here
    set trimmed_password [string trim $password]
    
    ad_user_login $db $user_id
    ad_returnredirect $return_url
#    ad_returnredirect "/cookie-chain.tcl?cookie_name=[ns_urlencode ad_auth]&cookie_value=[ad_encode_id $user_id $trimmed_password]&final_page=[ns_urlencode $return_url]"

} elseif { [ad_parameter RegistrationRequiresEmailVerificationP "" 0] }  { 

    # this user won't be able to use the system until he has answered his email
    # so don't give an auth cookie, but instead tell him 
    # to read your email

    ns_return 200 text/html "[ad_header "Please read your email"]

<h2>Please read your email</h2>

<hr>

Registration information for this service has been
sent to $email.
<p>
Please read and follow the instructions in this email.

[ad_footer]
"

} elseif {[ad_parameter RegistrationRequiresApprovalP "" 0]} {

    # this user won't be able to use the system until an admin has
    # approved him, so don't give an auth cookie, but instead tell him 
    # to wait
    ns_return 200 text/html "[ad_header "Awaiting Approval"]

<h2>Awaiting Approval</h2>

<hr>

Your registration is in the database now.  A site administrator has
been notified of your request to use the system.  Once you're
approved, you'll get an email message and you can return to
[ad_site_home_link] to use the service.

[ad_footer]
"
} 


if {[ad_parameter NotifyAdminOfNewRegistrationsP]} {
    # we're supposed to notify the administrator when someone new registers
    set notification_address [ad_parameter NewRegistrationEmailAddress "" [ad_system_owner]]
    ns_sendmail $notification_address $email "New registration at [ad_url]" "
$first_names $last_name ($email) registered as a user of 
[ad_url]
"
}


if { !$double_click_p } {

    if { [ad_parameter RegistrationRequiresEmailVerificationP "" 0] } {
	set rowid [database_to_tcl_string $db "select rowid from users where user_id = $user_id"]
    # the user has to come back and activate their account
    ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress]" "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter SystemURL]/register/email-confirm.tcl?[export_url_vars rowid]"

    } elseif { [ad_parameter RegistrationProvidesRandomPasswordP "" 0] ||  [ad_parameter EmailRegistrationConfirmationToUserP "" 0] } {
	with_catch errmsg {
	    ns_sendmail "$email" "[ad_parameter NewRegistrationEmailAddress]" "Thank you for visiting [ad_system_name]" "Here's how you can log in at [ad_url]:

Username:  $email
Password:  $password

"
	} {
	    ns_returnerror "error" "$error"
	    ns_log Warning "Error sending registration confirmation to $email in usre-new.tcl"
	}
    }
}









