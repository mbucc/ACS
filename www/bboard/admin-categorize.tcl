# $Id: admin-categorize.tcl,v 3.0.4.1 2000/04/28 15:09:41 carsten Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic

if { ![bboard_check_cookie $topic 1] } {
    ad_returnredirect "admin-challenge.tcl?[export_url_vars topic topic_id]"
    return
}

# cookie checks out; user is authorized

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if [catch {set selection [ns_db 0or1row $db "select unique * from bboard_topics where topic_id=$topic_id"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

set raw_form_vars "<tr><td>Present Categorized?<td>
<input type=radio name=q_and_a_categorized_p value=t CHECKED> Yes
<input type=radio name=q_and_a_categorized_p value=f> No
</tr>
<tr><td>Days Considered New<td><input type=text name=q_and_a_new_days size=5 value=\"$q_and_a_new_days\"> (for how many days a question should show up as \"New\" rather than in its category)</tr>
<tr><td>Order in which to present new questions?<td>
<input type=radio name=q_and_a_sort_order value=asc CHECKED> Oldest on top
<input type=radio name=q_and_a_sort_order value=desc> Newest on top
</tr>
<tr><td>Ask User to Categorize?<td>
<input type=radio name=q_and_a_solicit_category_p value=t CHECKED> Yes
<input type=radio name=q_and_a_solicit_category_p value=f> No
</tr>
<tr><td>Allow Users to Add New Categories?<td>
<input type=radio name=q_and_a_categorization_user_extensible_p value=t> Yes
<input type=radio name=q_and_a_categorization_user_extensible_p value=f CHECKED> No
<tr><td>Use Interest Level System?<td>
<input type=radio name=q_and_a_use_interest_level_p value=t> Yes
<input type=radio name=q_and_a_use_interest_level_p value=f CHECKED> No
<tr><td>Policy Statement<td>
<textarea name=policy_statement rows=4 cols=50>
</textarea>
<tr><td>Users Can Initiate Threads?<td>
<input type=radio name=users_can_initiate_threads_p value=t CHECKED> Yes
<input type=radio name=users_can_initiate_threads_p value=f> No
(you only want to set this to No if you are using this software to collect categorized stories rather than true Q&A)

</tr>
"
set merged_form [bt_mergepiece $raw_form_vars $selection]

ReturnHeaders

ns_write "<html>
<head>
<title>Categorization for $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Categorization for \"$topic\"</h2>

a Q&A forum in <a href=\"index.tcl\">[bboard_system_name]</a>

<p>

\[ <a href=\"q-and-a.tcl?[export_url_vars topic topic_id]\">user page (Q&A)</a> |

<a href=\"admin-q-and-a.tcl?[export_url_vars topic topic_id]\">in-line Admin Q&A</a> \]

<hr>

<h3>Categorization Information about this Q&A Forum</h3>

<form method=post action=\"update-topic-categorization.tcl\">
<input type=hidden name=topic value=\"$topic\">

<table>
$merged_form
</table>

<input type=submit value=\"Update this Information in the Database\">

</form>

<hr>

<h3>Delete and Categorize Threads</h3>

"

# we only want the question

set categories [database_to_tcl_list $db "select distinct category, upper(category) from bboard_q_and_a_categories where topic_id = $topic_id order by 2"]

set selection [ns_db select $db "select msg_id, one_line, sort_key, category from bboard
where topic_id = $topic_id
and refers_to is null
order by sort_key desc"]

while {[ns_db getrow $db $selection]} {

    set_variables_after_query
    ns_write "<table><tr><td>
<a href=\"delete-msg.tcl?msg_id=$msg_id\" target=admin_sub>DELETE</a>
<td>
<a target=admin_sub href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a>\n"
    ns_write "<td><form target=admin_sub method=POST action=q-and-a-update-category.tcl><input type=hidden name=msg_id value=\"$msg_id\"><select name=category>"
    if { $category == "" } {
	ns_write "<option value=\"\" SELECTED>Uncategorized"
    } else {
	ns_write "<option value=\"\">Uncategorized"
    }
    foreach choice $categories {
	if { $category == $choice } {
	    ns_write "<option SELECTED>$choice"
	} else {
	    ns_write "<option>$choice"
	}
    }
    ns_write "</select><input type=submit value=\"Set Category\"></form>"
    ns_write "<td><form target=admin_sub method=POST action=q-and-a-update-category.tcl>
<input type=hidden name=msg_id value=\"$msg_id\">
<input type=hidden name=new_category_p value=t>
New: <input type=text name=category size=20>
</form>"

    ns_write "</tr></table>\n"
}

ns_write "</pre>
[bboard_footer]
"
