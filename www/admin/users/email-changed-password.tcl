# $Id: email-changed-password.tcl,v 3.0.4.1 2000/04/28 15:09:37 carsten Exp $
# email-changed-password.tcl
#
# hqm@arsdigita.com
#
# form vars: user_id, password
#
# emails the user their new password


set_the_usual_form_variables

set db [ns_db gethandle]

set selection [ns_db 1row $db  "select email, password from users where user_id = $user_id"]

set_variables_after_query

ns_sendmail  "$email" "[ad_parameter NewRegistrationEmailAddress]" "Your password for [ad_system_name] has been changed" "Your password for [ad_system_name] ([ad_parameter SystemURL]) has been changed. Your new password is $password."

ad_returnredirect "one.tcl?[export_url_vars user_id]"
