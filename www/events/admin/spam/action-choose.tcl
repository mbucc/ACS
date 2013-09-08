# action-choose.tcl,v 1.1.2.2 2000/02/03 09:50:01 ron Exp
# events/admin/action-choose.tcl
# Owner: bryanche@arsdigita.com
# Purpose: A page allowing admins to spam users and providing
#          info on who spam will be sent to.
#####

# maybe  user_class_id (to indicate a previousely-selected class of users)
# maybe a whole host of user criteria
# maybe msg_text, maybe create_comment_p and event_id.  If these variables exists, then a comment will be created for all the registrants of this event

ad_page_contract {
    A page allowing admins to spam users and providing
    info on who spam will be sent to.  Note that the interface 
    and code for this page comes mainly from the spam module

    @param sql_post_select a sql query describing which users to select
    @param msg_text optional default email text
    @param create_comment_p should this email also be saved as comments for event registrants
    @param event_id (optional) the event for which this spam is creating a comment

    @param spam_selected_events flag indicating that this page should handle processing of /events/admin/spam-selected-events.tcl
    @param event array of event_id's indicating which events to spam
    @param reg_state which registration state to spam for the events

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id action-choose.tcl,v 3.15.2.5 2000/09/22 01:37:41 kevin Exp
} {
    {sql_post_select:optional}
    {msg_text:html,trim,optional}
    {create_comment_p:html,optional}
    {event_id:integer,optional}

    {spam_selected_events:optional}
    {event:array,optional}
    {reg_state:optional}
}

set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

page_validation {
    set error_msg ""

    #if this page should insert a comment, then it needs to know
    #for what event these users are being spammed.  
    if {[exists_and_not_null create_comment_p]} {
	if {$create_comment_p != 0 && ![exists_and_not_null event_id]} {
	    append error_msg "<li>This page came in without an event_id"
	}
    }

    if {![empty_string_p $error_msg]} {
	error $error_msg
    }
}

#############################################

#BEGIN PROCESS CODE FROM SPAM-SELECTED-EVENTS

#Unfortunately, Netscape and IE seem to have limits to how long
#a URL they can parse.  So, we'll move the code from spam-selected-events-2
#to this page so that it won't have to redirect to this page
#using a long url.  It's ugly, but we can't get around it...



if {[exists_and_not_null spam_selected_events]} {

    page_validation {
	if {![exists_and_not_null reg_state]} {
	    error "<li>You did not select which types of registrants
	    you wish to spam"
	}
    }

    set events_list [list]

    # see which events to spam
    db_foreach evnt_sel_spam_events "
    select e.event_id
    from events_activities a, events_events e, 
    user_groups ug, user_group_map ugm
    where a.activity_id = e.activity_id
    and a.group_id = ugm.group_id
    and ugm.group_id = ug.group_id
    and ugm.user_id = :admin_user_id
    union
    select e.event_id
    from events_activities a, events_events e
    where a.activity_id = e.activity_id
    and a.group_id is null
    " {
	set event_var "event($event_id)"

	if {[info exists $event_var]} {
	    lappend events_list $event_id
	}
    }

    if {[llength $events_list] == 0} {
	ad_return_warning "No Events Selected" "You didn't select any events to spam"
	return
    }

    switch $reg_state {
	"shipped" {set reg_state_sql "and r.reg_state = 'shipped'"}
	"pending" {set reg_state_sql "and r.reg_state = 'pending'"}
	"waiting" {set reg_state_sql "and r.reg_state = 'waiting'"}
	"all" {set reg_state_sql ""}
	default {set reg_state_sql ""}
    }

    set sql_post_select "select distinct
    users.user_id, users.email, users.email_type
    from users_spammable users, events_reg_not_canceled r, events_prices p
    where users.user_id = r.user_id
    and p.price_id = r.price_id
    $reg_state_sql
    and (
    "

    set first_flag 1
    foreach event_id $events_list {
	if {$first_flag} {
	    set first_flag 0
	    append sql_post_select " p.event_id = $event_id\n"
	} else {
	    append sql_post_select " or p.event_id = $event_id\n"
	}
    }

    append sql_post_select ")\norder by users.user_id"
}

#END PROCESS CODE FROM SPAM-SELECTED-EVENTS

#############################################


# we get a form that specifies a class of user

#set users_description [ad_user_class_description [ns_conn form]]
set users_description "users returned by $sql_post_select"

#text we want to already show up in the email body
if {![exists_and_not_null msg_text]} {
    set msg_text ""
}

## We store the page in whole_page as we go.

set whole_page ""
append whole_page "
  [ad_admin_header "Spam"]
<h2>Spam</h2>

[ad_context_bar_ws [list "../index.tcl" "Events Administration"] "Spam"]
<hr>

<p>
"

#

#regsub {from users} $sql_post_select {from users_spammable users} sql_post_select

#set query [ad_user_class_query_count_only [ns_conn form]]
set query "select count(count_view.email) 
from ($sql_post_select) count_view"
if [catch {set n_users [db_string evnt_spam_count_users $query]} errmsg] {

    db_release_unused_handles
    ns_warning "invalid query" "The query \n <blockquote>\n $query \n</blockquote>"
    return
}


#ad_return_error "query" "<pre>$query</pre>"
#return

if {$n_users == 0} {
    ad_return_error "No people to e-mail" "There are no people to e-mail."
    return
}
set action_heading ""

if {$n_users == 1} {
    append action_heading "You are e-mailing $n_users person."
} else {
    append action_heading "You are e-mailing [util_commify_number $n_users] people."
}

# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [db_string evnt_spam_spam_id_seq "select spam_id_sequence.nextval from dual"]

# Generate the SQL query from the user_class_id, if supplied, or else from the 
# pile of form vars as args to ad_user_class_query

#set users_sql_query [ad_user_class_query [ns_getform]]
set users_sql_query $sql_post_select

append whole_page "
<table>
<tr>
 <td align=top>To: $action_heading</td>"

if {$n_users > 0} {
#    append whole_page "
#    <a href=\"spamees-view?[export_url_vars sql_post_select]\">
#    View whom you're spamming</a>
#    "

    #this is ugly, but netscape/ie can't handle long url's
    #as of 6/2000.  So, we have to send sql_post_select
    #using a form post
    append whole_page "
    <td align=top>
    <form method=post action=\"spamees-view\">
    [export_form_vars sql_post_select]
    <input type=submit value=\"View\">
    </form>
    </td>
    "
}

append whole_page "
</tr></table>
    <form method=POST action=\"spam-confirm\">
[export_form_vars spam_id users_sql_query users_description create_comment_p event_id]

From: <input name=from_address type=text size=30 value=\"[db_string evnt_spam_from_email "select email from users where user_id = $admin_user_id"]\">
<p>
" 


append whole_page "
<p>Send Date:</th><td>[_ns_dateentrywidget "send_date"]
<br>Send Time:[_ns_timeentrywidget "send_date"]

<p>
Subject:  <input name=subject type=text size=50>
<p>
Message:
<p>
<textarea name=message rows=10 cols=80 wrap=soft>$msg_text</textarea>
<p>
<center> <input type=submit value=\"Continue\"> </center>
</form>
<p>

[ad_footer]
"

## clean up, return the page.



doc_return  200 text/html $whole_page

##### EOF
