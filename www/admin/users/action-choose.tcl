# /admin/users/action-choose.tcl
#
# Author: philg@mit.edu in late 1998
# Modified by: ron@arsdigita.com to confirm with ACS form conventions
# 
# Given a class of users, lets site admin pick something to do with
# them.
#
# $Id: action-choose.tcl,v 3.6.2.1 2000/04/28 15:09:35 carsten Exp $

set_the_usual_form_variables

# maybe user_class_id (to indicate a previousely-selected class of users)
# maybe a whole host of user criteria
# If description is specified, we display it instead of the results of ad_user_class_description
#   -- Passing description hides the sql query which can be good for normal, non-programming, users

set admin_user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# we get a form that specifies a class of user

set user_class_description [ad_user_class_description [ns_conn form]]

if { ![exists_and_not_null description] } {
    set user_description $user_class_description
    set description ""
} else {
    set user_description "Users who $description"
}


append whole_page "[ad_admin_header $user_description]

<h2>Users</h2>

[ad_admin_context_bar [list "index.tcl" "Users"] "One Class"]

<hr>

Class description:  $user_description.

<P>

"

set db [ns_db gethandle]


if { [ad_parameter NumberOfUsers] == "small" } {
    # we print out all the users
    append action_heading "<ul>"
    set query [ad_user_class_query [ns_conn form]]
    if [catch {set selection [ns_db select $db $query]} errmsg] {
	append  "The query
<blockquote>
$query 
</blockquote>
is invalid.
[ad_admin_footer]"
	return
    }
    set count 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	incr count
	append action_heading "<li><a href=\"one.tcl?user_id=$user_id\">$first_names $last_name</a> ($email)\n"
    }
    if { $count == 0 } {
	append action_heading "no users found meeting these criteria"
    }
    append action_heading "</ul>"
} else {
    # this is a large community; we just say how many users 
    # there are in this class
    set query [ad_user_class_query_count_only [ns_conn form]]
    if [catch {set n_users [database_to_tcl_string $db $query]} errmsg] {
	append whole_page  "The query
<blockquote>
$query 
</blockquote>
is invalid.
[ad_admin_footer]"
	return
    }
   
    append action_heading "There are [util_commify_number $n_users] users in this class."
}

set sql_description $user_class_description


if {![info exists user_class_id] || [empty_string_p $user_class_id]} {
    append title_text "<form action=user-class-add.tcl method=post>
[export_form_vars query sql_description]
Save this criteria as: <input type=text name=name>
<input type=submit value=\"Save\"> 
</form>"
} else {
    set selection [ns_db 1row $db "select name, description, sql_description, sql_post_select from user_classes where user_class_id = $user_class_id"]
    set_variables_after_query
    append title_text "
    <h3>User class: $name</h3>
<ul>    
<li>Description: $description
<li>SQL description: $sql_description"

if {[ad_parameter AllowAdminSQLQueries "" 0] == 1} {
    append title_text "<li> SQL: select users.* $sql_post_select"
}

append title_text "<br>
<a href=\"user-class-edit.tcl?[export_url_vars user_class_id]\">edit</a>
</ul>
<p>"
}


append whole_page "

$title_text

$action_heading

<h3>Pick an Action</h3>

<ul>
<li><a href=\"view.tcl?[export_entire_form_as_url_vars]\">View</a> 
<li><a href=\"view-verbose.tcl?[export_entire_form_as_url_vars]\">View (with address &amp; demographics)</a>
<li><a href=\"merge/one-class.tcl?[export_entire_form_as_url_vars]&order_by=email\">Look for merger candidates</a> 
<li><a href=\"view-csv.tcl?[export_entire_form_as_url_vars]\">Download
a comma-separated value file suitable for importing into a
spreadsheet</a> 
<br>(format is email, last name, first names)

</ul>

"

# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select spam_id_sequence.nextval from dual"]

# Generate the SQL query from the user_class_id, if supplied, or else from the 
# pile of form vars as args to ad_user_class_query

set users_sql_query [ad_user_class_query [ns_getform]]
regsub {from users} $users_sql_query {from users_spammable users} users_sql_query

if { [info exists user_class_id] && ![empty_string_p $user_class_id]} {
    set class_name [database_to_tcl_string $db "select name from user_classes where user_class_id = $user_class_id "]
    set sql_description [database_to_tcl_string $db "select sql_description from user_classes where user_class_id = $user_class_id "]
    set users_description "$class_name: $sql_description"
} else {
    set users_description  $user_description
}

append whole_page "

<h3>Spam Authorized Users in this Group</h3>

<blockquote>
Note, if you choose to use the Tcl template
option below, then for literal '\$', '\[' and '\]', 
you must use \\\$  (\\\$50 million dollars).  Otherwise,
our code will think you are trying to substitute a variable like
(\$first_names). 
</blockquote>

<p> <form method=POST action=\"/admin/spam/spam-confirm.tcl\">
[export_form_vars spam_id users_sql_query users_description]

<table>

<tr>
<td align=right>From:</td>
<td>
<input name=from_address type=text size=30
value=\"[database_to_tcl_string $db "select email from users where
user_id = $admin_user_id"]\"></td>
</tr>

<tr>
<td align=right>Send Date:</td>
<td>[_ns_dateentrywidget "send_date"]</td>
</tr>

<tr>
<td align=right>Send Time:</td>
<td>[_ns_timeentrywidget "send_date"]</td>
</tr>

<tr>
<td align=right>Subject:</td>
<td><input name=subject type=text size=50></td>
</tr>

<tr>
<td valign=top align=right>Message:</td>
<td>
<textarea name=message rows=10 cols=75 wrap=soft></textarea>
</td>
</tr>

<tr>
<td></td>
<td><input type=checkbox name=template_p value=t> This message is a
Tcl Template</td>
</tr>
</table>

<center>
<input type=submit value=\"Send Email\">
</center>
</form>

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $whole_page
