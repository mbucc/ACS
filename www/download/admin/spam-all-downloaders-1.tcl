# /www/download/admin/spam-all-downloaders-1.tcl
ad_page_contract {
    spams all users who downloaded this file 

    @param download_id the file we are spamming about
    @param from_address the return address for the spam
    @param subject the subject line for the spam
    @param message the spam
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id spam-all-downloaders-1.tcl,v 3.7.2.5 2000/09/24 22:37:17 kevin Exp
} {
    download_id:integer
    from_address
    subject
    message
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_admin_authorize $download_id

set exception_count 0
set exception_text ""

if { [empty_string_p $subject] && [empty_string_p $message] } {
    incr exception_count
    append exception_text "
    <li>Both the subject and the body of the email can not be empty."
}

set email_list [list]

db_foreach emails "
select distinct u.email
from  download_versions dv, download_log dl, users u
where dl.version_id = dv.version_id
and dl.user_id = u.user_id
and dv.download_id = :download_id" {

    lappend email_list $email

} if_no_rows {

    # no recipients
    incr exception_count
    append exception_text "
    <li>No recipients to receive this email" 
}

if { $exception_count > 0 } {
    ad_scope_return_complaint $exception_count $exception_text
    return
}

db_release_unused_handles

ad_returnredirect view-versions-report?[export_url_scope_vars download_id]

ns_conn close

ns_log Notice "/download/admin/spam-all-downloaders:  sending spam"
foreach receiver_email $email_list {
    ns_sendmail  $receiver_email $from_address $subject $message
}
ns_log Notice "/download/admin/spam-all-downloaders:  sent spam"
