# $Id: entry-comment-3.tcl,v 3.0.4.2 2000/04/28 15:10:42 carsten Exp $
# entry-comment-3.tcl -- add a comment to the general_comments table

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set_the_usual_form_variables

# expects comment_id, content, htmp_p, procedure_name, entry_id

# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}



# user has input something, so continue on

# assign necessary data for insert
set user_id [ad_verify_and_get_user_id]
set originating_ip [ns_conn peeraddr]

#if { [ad_parameter CommentApprovalPolicy calendar] == "open"} {
     set approved_p "t"
#} else {
#    set approved_p "f"
#}


set db [ns_db gethandle]

set one_line_item_desc " "

if [catch { ns_ora clob_dml $db "insert into general_comments
(comment_id,on_what_id, user_id, on_which_table ,content, ip_address,comment_date, approved_p, html_p, one_line_item_desc)
values ($comment_id, $entry_id, $user_id, 'glassroom_logbook', empty_clob(), '$originating_ip', sysdate, '$approved_p', '$html_p', '$one_line_item_desc') 
returning content into :1" "$content"} errmsg] {
    # Oracle choked on the insert
     if { [database_to_tcl_string $db "select count(*) from general_comments where comment_id = $comment_id"] == 0 } {
	# there was an error with comment insert other than a duplication
	ad_return_error "Error in inserting comment" "We were unable to insert your comment in the database.  Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
        return
     }
}

# either we were successful in doing the insert or the user hit submit
# twice and we don't really care

ad_returnredirect "logbook-view.tcl?procedure_name=[ns_urlencode $procedure_name]"
