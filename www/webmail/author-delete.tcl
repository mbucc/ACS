# /webmail/author-delete.tcl

ad_page_contract {
    Mark as deleted all messages by given author.    
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-28
    @cvs-id author-delete.tcl,v 1.4.6.5 2000/08/13 20:04:24 mbryzek Exp
} {
    author:multiple,allhtml
    last_n_days:integer
}

if { [llength $author] == 0 } {
    ad_return_error "No authors marked for deletion" "You must specify at least one author to delete by."
    return
}

set user_id [ad_verify_and_get_user_id]
set mailbox_id [ad_get_client_property -browser t "webmail" "mailbox_id"]

# Check to see if this user actually owns this mailbox.
set mailbox_access_allowed_p [db_string mbox_count "select count(*)
from wm_mailboxes
where mailbox_id = :mailbox_id
  and creation_user = :user_id"]

if { !$mailbox_access_allowed_p } {
    ad_return_error "Permission Denied" "You do not have permission to access this mailbox."
    ns_log Notice "WEBMAIL WARNING: user $user_id attempted to access mailbox $mailbox_id"
    return
}

set author_clause [list]
foreach a $author {
    lappend author_clause "'[DoubleApos $a]'"
}

ns_log Notice "\#\# $author"

db_dml deleted_update "update wm_message_mailbox_map
set deleted_p = 't'
 where msg_id in (select msg_id
                  from wm_headers
                  where lower_name = 'from'
                    and value in ([join $author_clause ", "]))
   and mailbox_id = :mailbox_id"

ad_returnredirect "summary?[export_url_vars last_n_days]"
