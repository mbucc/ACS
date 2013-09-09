# /www/register/user-new-2.tcl

ad_page_contract {
    Enters a new user into the database.
    @cvs-id  user-new-2.tcl,v 3.10.2.11 2001/01/12 19:58:32 khy Exp
} {
    {email:notnull}
    {password:notnull}
    {password_confirmation:notnull}
    {first_names:notnull}
    {last_name:notnull}
    {url}
    {user_id:integer,notnull,verify}
    {return_url [ad_pvt_home]}
} -errors {
    password:notnull {You must enter a password.}
    password_confirmation:notnull {You must enter your password twice.}
    first_names:notnull {You must enter a first name}
    last_name:notnull {You must enter a last name}
    email:notnull {You must enter an email address}
}

ad_handle_spammers

set exception_count 0
set exception_text ""

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
}

if {[info exists url] && ![empty_string_p $url] && ![philg_url_valid_p $url] } {
    # there is a URL but it doesn't match our REGEXP
    incr exception_count
    append exception_text "<li>You URL doesn't have the correct form.  A valid URL would be something like \"http://photo.net/philg/\"."
}

if { ![string equal $password $password_confirmation] } {
    append exception_text "<li>You must type the password the same way twice."
    incr exception_count
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
}

# If we are encrypting passwords in the database, convert

if  [ad_parameter EncryptPasswordsInDBP "" 0] { 
    set password_for_database [ns_crypt $password [ad_crypt_salt]]
} else {
    set password_for_database $password
}

set peeraddr [ns_conn peeraddr]

set insert_statement  "
insert into users 
(user_id,
 email,
 password,
 first_names,
 last_name,
 url,
 registration_date,
 registration_ip, 
 user_state, 
 last_visit) 
values 
(:user_id,
 :email,
 :password_for_database,
 :first_names,
 :last_name,
 :url, 
  sysdate, 
 :peeraddr, 
 :user_state, 
  sysdate)"

# let's look for other required tables

set insert_statements_sup ""

# need $user_id below because we want to pull that literal value out of dual.

set other_tables [ad_parameter_all_values_as_list RequiredUserTable]
foreach table_name $other_tables {
    # Where not exists clause to avoid duplicate entry caused by 
    # triggers inserting into user_preferences.  Ticket #23595

    lappend insert_statements_sup "
    insert into $table_name (user_id) 
    select :user_id 
    from   dual 
    where  not exists (select user_id from $table_name where user_id = :user_id)"
}

set double_click_p 0
set failed_transaction_p 0

db_transaction {
    db_dml user_new_2_user_insert $insert_statement 
} on_error {
    if { [db_string user_new_2_user_count {
	select count(user_id) 
	from   users 
	where  user_id = :user_id
    }] == 0 } {
	db_release_unused_handles
	ad_return_error "Insert Failed" "We were unable to create your user record in the database."
	ns_log Error "Error insert new user: $errmsg"
	# slightly nicer than return.
	ad_script_abort 
    } else {
	# assume this was a double click
	set double_click_p 1
    }
}


if { $double_click_p == 0 } {
    db_transaction {
	foreach statement $insert_statements_sup {
	    db_dml user_new_user_insert_supplement_tables $statement
	}
    } on_error {
	db_release_unused_handles
	ad_return_error "Insert Failed" "We were unable to create your user record in the database.  Here's what the error looked like:
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>"
	ad_script_abort
    }
}

if { $authorized_p } {
    # user is ready to go
    
    # we have to be careful here with the password; we put a string-trimmed
    # version into the RDBMS so we must do the same here
    set trimmed_password [string trim $password]
    
    ad_user_login $user_id
    ad_returnredirect $return_url
    
} elseif { [ad_parameter RegistrationRequiresEmailVerificationP "" 0] }  { 

    # this user won't be able to use the system until he has answered his email
    # so don't give an auth cookie, but instead tell him 
    # to read your email

    doc_return  200 text/html "
[ad_header "Please read your email"]

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

    doc_return  200 text/html "
[ad_header "Awaiting Approval"]

<h2>Awaiting Approval</h2>

<hr>

Your registration is in the database now.  A site administrator has
been notified of your request to use the system.  Once you're
approved, you'll get an email message and you can return to
[ad_site_home_link] to use the service.

[ad_footer]
"
} 

set notification_address [ad_parameter NewRegistrationEmailAddress "" [ad_system_owner]]

if {[ad_parameter NotifyAdminOfNewRegistrationsP]} {
    # we're supposed to notify the administrator when someone new registers
    ns_sendmail $notification_address $email "New registration at [ad_url]" "
$first_names $last_name ($email) registered as a user of 
[ad_url]
"
}

if { !$double_click_p } {
    
    if { [ad_parameter RegistrationRequiresEmailVerificationP "" 0] } {
	
	set row_id [db_string user_new_2_rowid_for_email "select rowid from users where user_id = :user_id"]
	# the user has to come back and activate their account

	ns_sendmail $email $notification_address "Welcome to [ad_system_name]" "To confirm your registration, please go to [ad_parameter SystemURL]/register/email-confirm.tcl?[export_url_vars row_id]"
	
    } elseif { [ad_parameter RegistrationProvidesRandomPasswordP "" 0] ||  [ad_parameter EmailRegistrationConfirmationToUserP "" 0] } {
	with_catch errmsg {
	    ns_sendmail $email $notification_address "Thank you for visiting [ad_system_name]" "Here's how you can log in at [ad_url]:
	    
Username:  $email
Password:  $password
"
	} {
	    ns_returnerror "error" "$error"
	    ns_log Warning "Error sending registration confirmation to $email in user-new-2.tcl"
	}
    }
}

