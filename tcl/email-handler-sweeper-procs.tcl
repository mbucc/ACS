# teadams@mit.edu on Dec 4, 1999
# procs to process incoming emails


proc_doc email_logging_process {db message} "Takes an incoming message and inserts a message into the bboard.  The username of the email address will be the message category.  The subject of the email address will be the bboard subject.  The body of the email will be the body of the message. The message will be posted by the from address." {

    # extract the headers 
    set from_addr ""
    set date ""
    set subject ""
    set msgtext ""
    set msg_id ""
    set reply_to ""

    # We want to grab headers for 
    # Date: Thu, 11 Mar 1999 01:42:24 -0500
    # From: Henry Minsky <hqm@ai.mit.edu>
    # Subject: Re: test message

    set parsed_msg [parse_email_message $message]

    set msgbody        [ns_set iget $parsed_msg "message_body"]
    set from_header    [ns_set iget $parsed_msg "from"]
    set subject [ns_set iget $parsed_msg "subject"]
    set date_header    [ns_set iget $parsed_msg "date"]
    set reply_to       [ns_set iget $parsed_msg "reply-to"]
    set to_header       [ns_set iget $parsed_msg "to"]
    set cc_header       [ns_set iget $parsed_msg "cc"]

    # look for address of form "From: foo@bar.com
    if {![regexp -nocase  "(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $from_header from_line from_addr]} {
	regexp -nocase  "(\[^<\]*)<(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $from_header from_line from_name from_addr
    }

    if {[empty_string_p $from_addr]} {
	ns_log Notice "process_ticket_message could not parse from_addr from incoming message header: |$from_header| message=|$message|"
	return
    }

    # Make a cleaner looking mail message, just reconstruct a couple of the headers
    append msgtext "From: <strong>[ns_quotehtml $from_header]</strong><br>"
    if {![empty_string_p $reply_to]} {
	append msgtext "Reply-to: <strong>[ns_quotehtml $reply_to]</strong><br>"
    }
    if {![empty_string_p $to_header]} {
	append msgtext "To: <strong>[ns_quotehtml $to_header]</strong><br>"
        if {[empty_string_p $subject]} { 
            set subject "To: [ns_quotehtml $to_header]"
        }
    }
    if {![empty_string_p $cc_header]} {
	append msgtext "CC: <strong>[ns_quotehtml $cc_header]</strong><br>"
    }
    if {![empty_string_p $date_header]} {
	append msgtext "Date: [ns_quotehtml $date_header]<br>"
    }

    append msgtext "<pre>$msgbody</pre>"
    
    # take the username and make it the category of the message

    set to_addr ""

    # look for address of form "To: foo@bar.com
    if {![regexp -nocase  "(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $to_header to_line to_addr]} {
	regexp -nocase  "(\[^<\]*)<(\[A-Za-z0-9._/%&!-\]+@\[A-Za-z0-9.-\]+)" $to_header to_line to_name to_addr
    }

    # find the "blah@intranet.arsdigita.com" thing and use that as the category
    set category {}
    if {![regexp {([^ <]+)@intranet.arsdigita.com} "$to_header $reply_to $message" match category]} { 
        # if we dont find it use the to_addr we found instead
        if {[empty_string_p $category] && ![empty_string_p $to_addr]} {
            regexp -nocase {(.*)@} $to_addr match category
        }
    }

    # We try to look up a user, based on their email address

    set user_id [database_to_tcl_string_or_null $db "select user_id from users where lower(email) = '[string tolower $from_addr]'"]

    # We need to have some default user_id we can use as the author of a ticket
    # if we can't guess the user id from the email message.  
    # Here we try to find a "system" user:
    if {[empty_string_p $user_id]} {
	set user_id [database_to_tcl_string $db "select system_user_id from dual"]
	ns_log Notice "Could not find registered user $from_addr, using user_id=$user_id"
    }

    set topic_id [database_to_tcl_string $db "select max(topic_id) from bboard_topics where topic = 'Emails'"]

    ns_db dml $db "begin transaction"
    
    set last_id [database_to_tcl_string $db "select last_msg_id from msg_id_generator for update of last_msg_id"] 
    set new_id [increment_six_char_digits $last_id]
    
    ns_db dml $db "update msg_id_generator set last_msg_id = '$new_id'"
    set sort_key $new_id
    
    set final_refers_to "NULL"
    set originating_ip "000.000.000.000"

    ns_ora clob_dml $db "insert into bboard (msg_id,refers_to,topic_id,originating_ip,user_id,one_line,message,html_p,sort_key,posting_time, category)
    values ('$new_id',$final_refers_to,$topic_id,'$originating_ip',$user_id,'[DoubleApos $subject]',empty_clob(),'f','$sort_key',sysdate, '$category')
    returning message into :1" $msgtext
    
    ns_db dml $db "end transaction"
}