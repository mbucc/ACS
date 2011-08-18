# /webmail/folder-create.tcl
# by jsc@arsdigita.com (2000-02-23)

# Create a new mailbox and return to specified target, or index.tcl.
# Passes along mailbox_id to the target.

ad_page_variables {folder_name target}

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode "/webmail/"]"
    return
}

set db [ns_db gethandle]

with_transaction $db {
    set mailbox_id [database_to_tcl_string $db "select wm_mailbox_id_sequence.nextval from dual"]
    ns_db dml $db "insert into wm_mailboxes (mailbox_id, name, creation_user, creation_date)
 values ($mailbox_id, '$QQfolder_name', $user_id, sysdate)"
} {
    ad_return_error "Folder Creation Failed" "An error occured while trying to create your folder:
<pre>
$errmsg
</pre>
"
}

if { [regexp {\?} $target] } {
    ad_returnredirect "$target&[export_url_vars mailbox_id]"
} else {
    ad_returnredirect "$target?[export_url_vars mailbox_id]"
}
