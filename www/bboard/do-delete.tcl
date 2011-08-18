# $Id: do-delete.tcl,v 3.0 2000/02/06 03:33:47 ron Exp $
#
# /bboard/do-delete.tcl
#
# deletes a msg (or set of messages) from a bulletin board
# and any associated attachments; used only by the administrator
#
# by philg@mit.edu in ancient times (1995) and ported
#

set_form_variables

# topic, topic_id, submit_button, explanation, explanation_from, explanation_to,
# deletion_list is the key

# user_charge is optional and, if it is present, we will charge the
# user after we're done with our deletions 

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

set QQtopic [DoubleApos $topic]

 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

ns_db dml $db "begin transaction"

if {[bboard_file_uploading_enabled_p]} {
    set list_of_files_to_delete [database_to_tcl_list $db "select filename_stub from bboard_uploaded_files where msg_id in ( '[join $deletion_list "','"]' )"]

    ns_db dml $db "delete from bboard_uploaded_files where msg_id in ( '[join $deletion_list "','"]' )"
    
    # ADD THE ACTUAL DELETION OF FILES
    if { [llength $list_of_files_to_delete] > 0 } {
	ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
    }
}

ns_db dml $db "delete from bboard_thread_email_alerts where thread_id in ( '[join $deletion_list "','"]' )"

set delete_sql "delete from bboard where msg_id in ( '[join $deletion_list "','"]' )"

if [catch { ns_db dml $db $delete_sql} errmsg] {

    ns_db dml $db "abort transaction"
    # something went a bit wrong during the delete
    ad_return_error "error deleting messages"  "Error deleting messages.  This should never have happened.  Here was the message:
<pre>

$errmsg

</pre>
" } else {

    ns_db dml $db "end transaction"

    ReturnHeaders
    ns_write "[ad_admin_header "Deletion Successful"]

<h2>Deletion successful.</h2>
<hr>

The thread you picked has been removed from the discussion.  You can 
<a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">return to the 
administration home page for \"$topic\"</a>"

   if { [string first "Email" $submit_button] != -1 } { 
       # we have to send some email
       ns_write "<p>... sending email to $explanation_to (from $explanation_from) ..."
       if [catch { ns_sendmail $explanation_to $explanation_from "your thread has been deleted" $explanation } errmsg] {
	   ns_write " failed sending mail:  <pre>\n$errmsg\n</pre>"
       } else {
	   # mail was sent
	   ns_write "... completed sending mail"
       }
   }

   if { [info exists user_charge] && ![empty_string_p $user_charge] } {
       ns_write "<p> ... adding a user charge:
<blockquote>
[mv_describe_user_charge $user_charge]
</blockquote>
... "
       mv_charge_user $db $user_charge
       ns_write "Done."
   }

   ns_write "

[ad_footer]
"

}
