# action-choose.tcl,v 1.1.2.2 2000/02/03 09:50:01 ron Exp

set_the_usual_form_variables

# maybe user_class_id (to indicate a previousely-selected class of users)
# maybe a whole host of user criteria

set admin_user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

# we get a form that specifies a class of user

set users_description [ad_user_class_description [ns_conn form]]

ReturnHeaders 

ns_write "[ad_admin_header "Spam"]

<h2>Spam</h2>

[ad_context_bar_ws [list "../index.tcl" "Events Administration"] "Spam"]

<hr>

<P>

"

set db [ns_db gethandle]

set query [ad_user_class_query_count_only [ns_conn form]]
if [catch {set n_users [database_to_tcl_string $db $query]} errmsg] {
    ns_write  "The query
    <blockquote>
    $query 
    </blockquote>
    is invalid.
    [ad_footer]"
    return
}

if {$n_users == 0} {
    ns_write "There are no people to e-mail.[ad_footer]"
    return
}

set action_heading ""
if {$n_users == 1} {
    append action_heading "You are e-mailing $n_users person."
} else {
    append action_heading "You are e-mailing [util_commify_number $n_users] people."
}


# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select spam_id_sequence.nextval from dual"]

# Generate the SQL query from the user_class_id, if supplied, or else from the 
# pile of form vars as args to ad_user_class_query

set users_sql_query [ad_user_class_query [ns_getform]]
regsub {from users} $users_sql_query {from users_spammable users} users_sql_query

ns_write "

<form method=POST action=\"spam-confirm.tcl\">
[export_form_vars spam_id users_sql_query users_description]

From: <input name=from_address type=text size=30 value=\"[database_to_tcl_string $db "select email from users where user_id = $admin_user_id"]\">

<p>To: $action_heading
" 
if {$n_users > 0} {
    ns_write "
    <a href=\"spamees-view.tcl?[export_url_vars sql_post_select]\">
    View whom you're spamming</a>
    "
}
ns_write "
<p>Send Date:</th><td>[_ns_dateentrywidget "send_date"]<br>
Send Time:[_ns_timeentrywidget "send_date"]


<p>

Subject:  <input name=subject type=text size=50>

<p>

Message:

<p>

<textarea name=message rows=10 cols=80 wrap=soft></textarea>

<p>

<center>

<input type=submit value=\"Send Email\">

</center>

</form>
<p>


[ad_footer]
"
