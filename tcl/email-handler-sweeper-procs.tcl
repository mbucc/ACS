# /tcl/email-handler-sweeper-procs.tcl

ad_library {

    procs to process incoming emails

    @author  teadams@mit.edu
    @created Dec 4, 1999
    @cvs-id  email-handler-sweeper-procs.tcl,v 3.29.2.8 2000/09/14 07:36:30 ron Exp
}

proc_doc email_logging_process {message} "Takes an incoming message and inserts a message into the bboard.  The username of the email address will be the message category.  The subject of the email address will be the bboard subject.  The body of the email will be the body of the message. The message will be posted by the from address." {

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
    if {![regexp {([^ <;,]+)@intranet.arsdigita.com} "$to_header $reply_to $message" match category]} { 


	# BEGIN ARSDIGITA-SPECIFIC
	
	# special case for our mail-forwarding aliases, because I can't
	# figure out how to get post.office mail forwarding to insert
	# the Delivered-to header.
	regexp {(webmaster|sales|biz-jobs|tech-jobs|info|bootcamp|toolkit|free-services)@arsdigita.com} \
		"$to_header $cc_header $reply_to " match category

	# END ARSDIGITA-SPECIFIC

        # if we dont find it use the to_addr we found instead
        if {[empty_string_p $category] && ![empty_string_p $to_addr]} {
            regexp -nocase {(.*)@} $to_addr match category
        }
    }

    # We try to look up a user, based on their email address

    set user_id [db_string unused "select user_id from users where lower(email) = '[string tolower $from_addr]'" -default ""]

    # We need to have some default user_id we can use as the author of a ticket
    # if we can't guess the user id from the email message.  
    # Here we try to find a "system" user:
    if {[empty_string_p $user_id]} {
	set user_id [db_string unused "select system_user_id from dual"]
	ns_log Notice "Could not find registered user $from_addr, using user_id=$user_id"
    }

    set category [string trim $category]
    set subject [string trim $subject]
    if { [empty_string_p $subject] } {
	# We can't have empty subjects! There's a not null constraint on 
	# one_line and triggers depend on it being there
	set subject "$category email"
	if { ![empty_string_p $from_addr] } {
	    append subject " from $from_addr"
	}
    }
    
    # If the intranet is enabled, we offer added functionality to email logging:
    #  1. log email as a corresepondance
    #  2. optionally send email to people working on the group
    if { [im_enabled_p] && [ad_parameter LogEmailToGroupsP intranet 0] } {
	# We have some special cases to email the message to either all employees,
	# all customers, or everyone
	if { [regsub {\-employees$} $category "" category] } {
	    set email_who "employees"
	} elseif { [regsub {\-customers$} $category "" category] } {
	    set email_who "customers"
	} elseif { [regsub {\-all$} $category "" category] } {
	    set email_who "all"
	} else {
	    set category $category
	    set email_who ""
	}
	
	set on_what_id [db_string unused \
		"select max(ug.group_id)
             	   from user_groups ug
                  where upper(trim(ug.short_name))=upper(trim(:category))" -default ""]
	if { ![empty_string_p $on_what_id] } {
	    # This means the email was sent to the address of a 
	    # group we recognize. log that message as a correspondance
	    # to that group. Note that we continue to log the message
	    # to the Emails bboard forum
	    set comment_id [db_string unused \
		    "select general_comment_id_sequence.nextVal from dual"]
	    set one_line_item_desc "Email sent to $category group"
	    set ip "0.0.0.0"
	    set approved_p "t"
	    set html_p "f"
	    ad_general_comment_add $comment_id user_groups $on_what_id $one_line_item_desc $msgtext $user_id $ip $approved_p $html_p $subject
	    if { ![empty_string_p $email_who] } {
		im_email_people_in_group $on_what_id $email_who $from_addr $subject $msgtext
	    }
	}
    }

    if {[regexp -nocase {recruiting-([0-9]+)$} $category match recruitee_user_id]} {
        set exists_p [db_string unused \
                "select count(*) from users where user_id = :recruitee_user_id"]
        if { $exists_p == 1 } {
	    set comment_id [db_string unused \
		    "select general_comment_id_sequence.nextVal from dual"]
	    set one_line_item_desc "Email sent to $category"
	    ad_general_comment_add $comment_id im_employee_pipeline $recruitee_user_id $one_line_item_desc $msgtext $user_id "0.0.0.0" "t" "f" $subject
            ##Note that we bail out and don't log it to the bboard here!
            return
        }
    }

    set topic_id ""

    # BEGIN ARSDIGITA-SPECIFIC
    # For emails to webmaster, see if there is a separate discussion group set up
    if { [string compare [string tolower $category] "webmaster"] == 0 } {
	set topic_id [db_string unused "select max(topic_id) from bboard_topics
	where upper(trim(topic))=upper(trim(:category))" -default ""]
    }
    # END ARSDIGITA-SPECIFIC

    if {[empty_string_p $topic_id]} {
	# put it in the generic "Emails" topic
	set topic_id [db_string unused "select max(topic_id) from bboard_topics where topic = 'Emails'"]
	set category_compare "and category = '$category'"
    } else {
	set category ""
	set category_compare ""
    }

    # See if this message is part of an existing thread
    if { [regsub -nocase {^(Re:| )+} $subject "" subject_without_re] } {
	set nrows [db_0or1row unused "select max(msg_id) from bboard
                                where topic_id = :topic_id
				      $category_compare
				      and refers_to is null
				      and one_line = :subject_without_re
                                order by posting_time desc"]

	if { $nrows > 0} {
	    set final_refers_to $msg_id
	    set sort_key $final_refers_to
	    set subject "Response to $subject_without_re"
	}
    }

    db_transaction {
    
    set last_id [db_string unused "select last_msg_id from msg_id_generator for update of last_msg_id"] 
    set new_id [increment_six_char_digits $last_id]
    
    db_dml unused "update msg_id_generator set last_msg_id = :new_id"

    if {![info exists final_refers_to]} {
	set final_refers_to [db_null]
	set sort_key $new_id
    }
    
    set originating_ip "000.000.000.000"

    db_dml unused "insert into bboard (msg_id,refers_to,topic_id,originating_ip,user_id,one_line,message,html_p,sort_key,posting_time, category)
    values (:new_id,:final_refers_to,:topic_id,:originating_ip,:user_id,:subject,empty_clob(),'t',:sort_key,sysdate, :category)
    returning message into :1" -clobs [list $msgtext]
    
    }
}
