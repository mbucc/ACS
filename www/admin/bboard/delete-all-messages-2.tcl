# /www/admin/bboard/delete-all-messages-2.tcl
ad_page_contract {
    Page to delete all messages in a bboard

    @param topic the name of the bboard

    @author ?
    @creation-date ?
    @cvs-id delete-all-messages-2.tcl,v 3.0.12.4 2000/09/22 01:34:21 kevin Exp
} {
    topic
}

# -----------------------------------------------------------------------------

if {![db_0or1row topic_info "
select bt.*,
       u.password as admin_password
from   bboard_topics bt, 
       users u
where  bt.topic= :topic
and    bt.primary_maintainer_id = u.user_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}

set n_messages [db_string n_messages "
select count(*) from bboard where topic_id = :topic_id"]


append page_content "
[ad_admin_header "Clearing Out $topic"]

<h2>Clearing Out \"$topic\"</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] [list "administer.tcl?[export_url_vars topic]" "One Bboard"] "Clearing Out"]

<hr>

We will now attempt to delete $n_messages messages from
this forum...  

"

db_transaction {

    set list_of_files_to_delete [db_list files "
    select buf.filename_stub 
    from   bboard_uploaded_files buf, bboard
    where  buf.msg_id = bboard.msg_id 
    and    bboard.topic_id = :topic_id"]

    db_dml files_delete "
    delete from bboard_uploaded_files 
    where msg_id in (select msg_id from bboard where topic_id = :topic_id)"

    # add the actual deletion of the files
    if { [llength $list_of_files_to_delete] > 0 } {
	ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
    }

    db_dml delete_alerts "
    delete from bboard_thread_email_alerts where thread_id in
    (select msg_id from bboard where topic_id = :topic_id)" 

    db_dml bboard_delete "
    delete from bboard where topic_id = :topic_id"

}

append page_content "Success!  You can now use the forum afresh.

[ad_admin_footer]
"


doc_return  200 text/html $page_content