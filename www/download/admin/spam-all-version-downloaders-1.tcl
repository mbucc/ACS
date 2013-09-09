# /www/download/admin/spam-all-version-downloaders-1.tcl
ad_page_contract {
    spams all users who downloaded this version

    @param version_id version we are spamming about
    @param from_address the return address for the spam
    @param subject the subject of the spam
    @param message the spam
    @param scope
    @param group_id
    
    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id spam-all-version-downloaders-1.tcl,v 3.7.2.5 2000/09/24 22:37:17 kevin Exp
} {
    version_id:integer,notnull
    from_address:trim,notnull
    subject:trim,notnull
    message:trim,notnull
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_version_admin_authorize $version_id

set exception_count 0
set exception_text ""

set email_list [list]

db_foreach emails "
select distinct u.email
from  download_versions dv, download_log dl, users u
where dl.version_id = dv.version_id
and dl.user_id = u.user_id
and dv.version_id = :version_id" {

    lappend email_list $email

} if_no_rows {

    ad_scope_return_complaint 1 "<li>No recipients to receive this email"
    return
}


db_release_unused_handles
ad_returnredirect view-one-version-report?[export_url_scope_vars version_id]

ns_conn close

ns_log Notice "/download/admin/spam-all-version-downloaders-1:  sending spam"
foreach receiver_email $email_list {
    ns_sendmail  $receiver_email $from_address $subject $message
    ns_log Notice "$receiver_email $from_address $subject $message"
}
ns_log Notice "/download/admin/spam-all-version-downloaders-1:  sent spam"
