ad_page_contract {
    Given a class of users, lets site admin pick something to do with them.

    # maybe a whole host of user criteria

    @author Philip Greenspun (philg@mit.edu)
    @author Ron Henderson (ron@arsdigita.com)
    @cvs-id action-choose.tcl,v 3.11.2.5.2.3 2000/09/22 01:36:16 kevin Exp

    @param user_class_id (optional) a previously-selected class of users
    @param description (optional) if given, used instead of the results of ad_user_class_description. Passing description hides the sql query which can be good for normal, non-programming, users
} {
    registration_after_date:optional
    category_id:optional
    curriculum_elements_completed:optional
    expensive:optional
    include_accumulated_charges_p:optional
    group_id:optional,integer
    special:optional
    user_state:optional
    registration_during_month:optional
    last_login_equals_days:optional
    crm_state:optional
    country_code:optional
    usps_abbrev:optional
    sex:optional
    age_above_years:optional
    age_below_years:optional
    registration_before_days:optional
    registration_after_days:optional
    last_login_before_days:optional
    last_login_after_days:optional
    number_visits_below:optional
    number_visits_above:optional
    last_name_starts_with:optional
    email_starts_with:optional
    combine_method:optional
    sql_post_select:optional
    {user_class_id:integer ""}
    description:optional
}

set admin_user_id [ad_maybe_redirect_for_registration]

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



if { [ad_parameter NumberOfUsers] == "small" } {
    # we print out all the users
    append action_heading "<ul>"
    set query [ad_user_class_query [ns_conn form]]
    db_foreach user_class_query $query {
	append action_heading "<li><a href=\"one?user_id=$user_id\">$first_names $last_name</a> ($email)\n"
    } if_no_rows {
	append action_heading "no users found meeting these criteria"
    }
    append action_heading "</ul>"
} else {
    # this is a large community; we just say how many users 
    # there are in this class
    set query [ad_user_class_query_count_only [ns_conn form]]
    if [catch {set n_users [db_string user_class_query $query]} errmsg] {
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

if {[empty_string_p $user_class_id]} {
    append title_text "<form action=user-class-add method=post>
[export_form_vars query sql_description]
Save this criteria as: <input type=text name=name>
<input type=submit value=\"Save\"> 
</form>"
} else {
    if { ![db_0or1row user_classes_query "select name, description, sql_description, sql_post_select from user_classes where user_class_id = $user_class_id"] } {
	ad_return_error "User Class Not Found" "User class #user_class_id does not exist"
	return
    }
    append title_text "
    <h3>User class: $name</h3>
<ul>    
<li>Description: $description
<li>SQL description: $sql_description"

if {[ad_parameter AllowAdminSQLQueries "" 0] == 1} {
    append title_text "<li> SQL: select users.* $sql_post_select"
}

append title_text "<br>
\[ <a href=\"user-class-edit?[export_url_vars user_class_id]\">edit</a> |
<a href=\"javascript:if(confirm('Are you sure you want to delete this user class?'))location.href='user-class-delete?[export_url_vars user_class_id]'\">delete</a> \]
</ul>
<p>"
}

append whole_page "

$title_text

$action_heading

<h3>Pick an Action</h3>

<ul>
<li><a href=\"view?[export_entire_form_as_url_vars]\">View</a> 
<li><a href=\"view-verbose?[export_entire_form_as_url_vars]\">View (with address &amp; demographics)</a>
<li><a href=\"merge/one-class?[export_entire_form_as_url_vars]&order_by=email\">Look for merger candidates</a> 
<li><a href=\"view-csv?[export_entire_form_as_url_vars]\">Download
a comma-separated value file suitable for importing into a
spreadsheet</a> 
<br>(format is email, last name, first names)

</ul>

"

# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [db_string new_spam_id "select spam_id_sequence.nextval from dual"]

# Generate the SQL query from the user_class_id, if supplied, or else from the 
# pile of form vars as args to ad_user_class_query

set users_sql_query [ad_user_class_query [ns_getform]]

if { [info exists user_class_id] && ![empty_string_p $user_class_id]} {
    set class_name [db_string user_class_query "select name from user_classes where user_class_id = $user_class_id "]
    set sql_description [db_string sql_desc_query "select sql_description from user_classes where user_class_id = $user_class_id "]
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

<p> <form method=POST action=\"/admin/spam/spam-confirm\">
[export_form_vars spam_id users_sql_query users_description]

<table>

<tr>
<td align=right>From:</td>
<td>
<input name=from_address type=text size=30
value=\"[db_string user_email "select email from users where
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


doc_return  200 text/html $whole_page
