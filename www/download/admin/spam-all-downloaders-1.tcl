# $Id: spam-all-downloaders-1.tcl,v 3.0.6.3 2000/05/18 00:05:17 ron Exp $
# File:     /admin/download/spam-all-downloaders-1.tcl
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose: spams all users who downloaded this file 

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# download_id from_address subject message

ad_scope_error_check

set db [ns_db gethandle]

download_admin_authorize $db $download_id

set exception_count 0
set exception_text ""

if { [empty_string_p $subject] && [empty_string_p $message] } {
    incr exception_count
    append exception_text "
    <li>Both the subject and the body of the email can not be empty."
}

set selection [ns_db select $db "
select distinct u.email
from  download_versions dv, download_log dl, users u
where dl.version_id = dv.version_id
and dl.user_id = u.user_id
and dv.download_id = $download_id"]

set counter 0
set email_list [list]

#build up the email list of receivers
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    incr counter

    lappend email_list $email
}

if { $counter == 0 } {
    # no recipients
    incr exception_count
    append exception_text "
    <li>No recipients to receive this email" 
}
if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

ns_db releasehandle $db
ad_returnredirect view-versions-report.tcl?[export_url_scope_vars download_id]

ns_conn close

ns_log Notice "/download/admin/spam-all-downloaders.tcl:  sending spam"
foreach receiver_email $email_list {
    ns_sendmail  $receiver_email $from_address $subject $message
}
ns_log Notice "/download/admin/spam-all-downloaders.tcl:  sent spam"
