# /www/bboard/admin-bulk-delete-by-email-or-ip.tcl
ad_page_contract {
    page to do bulk delete of messages

    @param topic the name of the bboard topic to delete message from
    @param deletion_ids list of messages we are deleting
    @param email the email address of the person being deleted
    @param originating_ip the ip address of the messages being deleted

    @cvs-id admin-bulk-delete-by-email-or-ip.tcl,v 3.3.2.4 2000/09/22 01:36:42 kevin Exp
} {
    topic
    deletion_ids:multiple
    email:optional
    originating_ip:optional
}

# -----------------------------------------------------------------------------

bboard_get_topic_info

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

if {[bboard_admin_authorization] == -1} {
    return
}


# cookie checks out; user is authorized

page_validation {
    if { [info exists email] } {
	set class "same email address"
    } elseif { [info exists originating_ip] } {
	set class "same ip address"
    } else {
	error "neither email nor IP address specified; something wrong with your browser or my code"
    }
}

if { [llength $deletion_ids] == 0 } {
    doc_return  200 text/html "
[bboar_header "No messages selected"]

<h2>No messages selected</h2>

<hr>

Either there is a bug in my code or you didn't check any boxes for
messages to be deleted.

[bboard_footer]"
    return
    
}



append page_content "

[bboard_header "Deleting threads in $topic"]

<h2>Deleting Threads</h2>

with the $class in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic question and answer forum</a> 

<hr>

<ul>
"


foreach msg_id $deletion_ids {
    db_1row msg_info "
    select sort_key, 
    	   one_line, 
    	   topic as msg_topic, 
    	   email as msg_email, 
    	   originating_ip as msg_originating_ip
    from   bboard, users
    where  users.user_id = bboard.user_id 
    and msg_id = :msg_id"

    if { $topic != $msg_topic } {
	append page_content "<li>skipping $one_line because its topic ($msg_topic) does not match that of the bboard you're editing; this is probably a bug in my software\n"
    }

    if { [info exists email] && ( $msg_email != $email ) } {
	append page_content "<li>skipping $one_line because its email address ($msg_email) does not match that of the other messages you're supposedly deleting; this is probably a bug in my software\n"
    }

    if { [info exists originating_ip] && ( $msg_originating_ip != $originating_ip ) } {
	append page_content "<li>skipping $one_line because its originating IP address ($msg_originating_ip) does not match that of the other messages you're supposedly deleting; this is probably a bug in my software\n"
    }

    append page_content "<li>working on \"$one_line\" and its dependents... \n"
    set dependent_key_form [dependent_sort_key_form $sort_key]

    db_transaction {

	if {[bboard_file_uploading_enabled_p]} {
	    set list_of_files_to_delete [db_list files "
	    select filename_stub 
	    from   bboard_uploaded_files 
	    where  msg_id IN (select msg_id from bboard 
			      where msg_id=:msg_id 
			      or sort_key like :dependent_key_form)"]
    
	    db_dml files_delete "
	    delete from bboard_uploaded_files 
	    where msg_id IN (select msg_id from bboard 
			     where msg_id=:msg_id 
			     or sort_key like :dependent_key_form)"
    
	    # ADD THE ACTUAL DELETION OF FILES
	    if { [llength $list_of_files_to_delete] > 0 } {
		ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
	    }
	}
	    
	db_dml alerts_delete "
	delete from bboard_thread_email_alerts 
	where  thread_id = :msg_id"
    
	db_dml msg_delete "
	delete from bboard 
	where  msg_id = :msg_id 
	or     sort_key like :dependent_key_form"
    
	append page_content "success! (killed message plus [expr [db_resultrows] - 1] dependents)\n"
    } {
	append page_content "failed.  Database choked up \"$errmsg\"\n"
    }
}

append page_content "

</ul>

[bboard_footer]
"


doc_return 200 text/html $page_content