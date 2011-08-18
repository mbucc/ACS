# $Id: delete-all-messages-2.tcl,v 3.0 2000/02/06 02:49:17 ron Exp $
set_the_usual_form_variables

# topic

set db [bboard_db_gethandle]
if [catch {set selection [ns_db 0or1row $db "select bt.*,u.password as admin_password
from bboard_topics bt, users u
where bt.topic='$QQtopic'
and bt.primary_maintainer_id = u.user_id"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

set n_messages [database_to_tcl_string $db "select count(*) from bboard where topic_id = $topic_id"]

ReturnHeaders 

ns_write "[ad_admin_header "Clearing Out $topic"]

<h2>Clearing Out \"$topic\"</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] [list "administer.tcl?[export_url_vars topic]" "One Bboard"] "Clearing Out"]

<hr>

We will now attempt to delete $n_messages messages from
this forum...  

"

ns_db dml $db "begin transaction"

set list_of_files_to_delete [database_to_tcl_list $db "
select buf.filename_stub 
from bboard_uploaded_files buf, bboard
where buf.msg_id = bboard.msg_id 
and bboard.topic_id = $topic_id"]

ns_db dml $db "delete from bboard_uploaded_files 
where msg_id in (select msg_id from bboard where topic_id = $topic_id)"

# add the actual deletion of the files
if { [llength $list_of_files_to_delete] > 0 } {
    ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
}

ns_db dml $db "delete from bboard_thread_email_alerts where thread_id in
(select msg_id from bboard where topic_id = $topic_id)" 

ns_db dml $db "delete from bboard where topic_id = $topic_id"

ns_db dml $db "end transaction"

ns_write "Success!  You can now use the forum afresh.

[ad_admin_footer]
"
