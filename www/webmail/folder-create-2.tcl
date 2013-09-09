# /webmail/folder-create-2.tcl

ad_page_contract {
    Create a new mailbox and return to specified target, or index.tcl.
    Passes along mailbox_id to the target.

    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id folder-create-2.tcl,v 1.4.6.4 2000/08/13 20:04:25 mbryzek Exp
} {
    folder_name
    target
}

set user_id [ad_maybe_redirect_for_registration]

db_transaction {
    set mailbox_id [db_nextval wm_mailbox_id_sequence]
    db_dml folder_create "insert into wm_mailboxes (mailbox_id, name, creation_user, creation_date)
 values (:mailbox_id, :folder_name, :user_id, sysdate)"
} on_error {
    ad_return_error "Folder Creation Failed" "An error occured while trying to create your folder:
<pre>
$errmsg
</pre>
"
    return
}

if { [regexp {\?} $target] } {
    ad_returnredirect "$target&[export_url_vars mailbox_id]"
} else {
    ad_returnredirect "$target?[export_url_vars mailbox_id]"
}
