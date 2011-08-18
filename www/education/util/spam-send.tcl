#
# /www/education/class/admin/spam-send.tcl
#
# heavily taken from /groups/group/spam-send.tcl
#
# modified by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this actually sends the spam
#


ad_page_variables {
    subject
    who_to_spam
    header
    spam_roles
    spam_id
    message
    from_address
    n_recipients
    group_id
}


set db [ns_db gethandle]


set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    if {[string compare $group_pretty_type class] == 0} {
	set id_list [edu_user_security_check $db]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}

set sender_id [lindex $id_list 0]
set actual_group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]



# now, lets make sure that the user has permission to view this spam
set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $sender_id $group_id]

if {!$spam_permission_p} {
    set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $sender_id $actual_group_id]
    if {!$spam_permission_p} {
	# are they a member of the group the spam was sent to?
	# if not, tell them they are not allowed to view the spam
	if {[database_to_tcl_string $db "select count(user_id) from user_group_map where group_id = $group_id and user_id = $sender_id"] == 0} {
	    ad_return_complaint 1 "<li>You do not currently have permission to spam the group you are trying to spam."
	    return
	}
    }
}


if [catch { ns_ora clob_dml $db "insert into group_spam_history
(spam_id, group_id, send_to_roles, from_address, subject, body, send_date, sender_id, sender_ip_address, approved_p, n_receivers_intended, creation_date)
values
($spam_id, $group_id, [ns_dbquotevalue $who_to_spam], [ns_dbquotevalue $from_address], [ns_dbquotevalue $subject], empty_clob(), sysdate, $sender_id, '[DoubleApos [ns_conn peeraddr]]', 't', [ns_dbquotevalue $n_recipients], sysdate)
returning body into :1" $message } errmsg] {
    # choked; let's see if it is because 
    if { [database_to_tcl_string $db "select count(*) from spam_history where spam_id = $spam_id"] > 0 } {
	ns_return 200 text/html "[ad_header "Double Click?"]

<h2>Double Click?</h2>

<hr>

This spam has already been sent.  Perhaps you double clicked?  In any 
case, you can check the progress of this spam on
<a href=\"old.tcl?[export_url_vars spam_id]\">the history page</a>.

[ad_footer]"
    } else {
	ad_return_error "Ouch!" "The database choked on your insert:
<blockquote>
$errmsg
</blockquote>
"
    }
    return
}


set email_list [database_to_tcl_list $db "
    select distinct email
    from user_group_map ug, users_spammable u
	where ug.group_id = $group_id
        and lower(ug.role) in ([join $spam_roles ","])
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = $group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  $sender_id)"]


set short_name [database_to_tcl_string $db "select short_name from user_groups where group_id=$group_id"]


append message "

--------------------------------------------------------- \n
You've gotten this spam because you are a registered member of $group_name.\n\n

To stop receiving any future spam from the $group_name mailing list:\n
click <a href=[ad_url]/groups/$short_name/edit-preference.tcl?dont_spam_me_p=t>here</a>
\n\n
---------------------------------------------------------\n
To stop receiving any future email from this specific sender:\n
click <a href=[ad_url]/user-user-bozo-filter.tcl?[export_url_vars sender_id ]>here</a>
"



if {[lsearch [ns_conn urlv] admin] == -1} {
    set nav_bar "[ad_context_bar_ws_or_index [list "one.tcl" "$group_name Home"] "Sending Spam"]"
} else {
    set nav_bar "[ad_context_bar_ws_or_index [list "../one.tcl" "$group_name Home"] [list "" "Administration"] "Sending Spam"]"
}


ReturnHeaders

ns_write "
[ad_header "$group_name Spam @ [ad_system_name]"]

<h2>Spam $header</h2>

$nav_bar

<hr>
<blockquote>

Sending Spam to $header

<P>
Sending email to...
<ul>
"


foreach email $email_list {
    with_catch errmsg {
	ns_sendmail $email $from_address $subject $message
	# we succeeding sending this particular piece of mail
	ns_write "$email ... <br>"
	ns_db dml $db "update group_spam_history set n_receivers_actual = n_receivers_actual + 1 where spam_id = $spam_id"
    } {
	# email failed, let's see if it is because mail 
	# service is completely wedged on this box
	if { [string first "timed out" errmsg] != -1 } {
	    # looks like we couldn't even talk to mail server
	    # let's just give up and return so that this thread
	    # doesn't have around for 10 minutes 
	    ns_log Notice "timed out sending email; giving up on email alerts.  Here's what ns_sendmail returned:\n$errmsg"
	    ns_write "</ul>
	    
	    Something is horribly wrong with the email handler on this computer so
	    we're giving up on sending any email notifications.  Your posting
	    will be enshrined in the database, of course.
	    
	    [ad_footer]"
	    return
	} else {
	    ns_write  "Something is horribly wrong with 
	    the email handler on this computer so
	    we're giving up on sending any email notifications.  Your posting
	    will be enshrined in the database, of course.
	    
	    
	    <p>
	    <blockquote>
	    <pre>
	    $errmsg
	    </pre>
	    </blockquote>"
	    return
	}
    }
}

ns_db releasehandle $db
    
# we're done processing the email queue
ns_write "
</ul>
<p>

We're all done with the email notifications now.  If any of these
folks typed in a bogus/misspelled/obsolete email address, you may get a
bounced message in your inbox.
</blockquote>
[ad_footer]
"


