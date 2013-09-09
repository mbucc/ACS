#email-changed-password.tcl

ad_page_contract {
    emails the user their new password
  
    @param user_id
    @param password
    @author hqm@arsdigita.com
    @creation-date ?
    @cvs-id email-changed-password.tcl,v 3.2.2.3.2.4 2000/09/13 16:46:41 lars Exp

} {
    user_id:integer,notnull
    password:notnull
}


db_1row user_email_password "select email, password from users where user_id = :user_id"

ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress "" [ad_parameter SystemOwner]]" "Your password for [ad_system_name] has been changed" "Your password for [ad_system_name] ([ad_parameter SystemURL]) has been changed. 

Here's how you can now log in:

Username:  $email
Password:  $password

Please come back to [ad_parameter SystemURL]/register/ to log in with your new password.

Thanks,
[ad_system_name] Administration
"

db_release_unused_handles

ad_returnredirect "one.tcl?[export_url_vars user_id]"



