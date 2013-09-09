# /www/bboard/admin-categorize.tcl
ad_page_contract {
    
    @cvs-id admin-categorize.tcl,v 3.3.2.4 2000/09/22 01:36:43 kevin Exp
} {
    topic_id:integer,notnull
    topic
}

# -----------------------------------------------------------------------------

if { ![bboard_check_cookie $topic 1] } {
    ad_returnredirect "admin-challenge.tcl?[export_url_vars topic topic_id]"
    return
}

# cookie checks out; user is authorized

set topics [ns_set create]

if {![db_0or1row topic_info "
select unique * 
from   bboard_topics 
where  topic_id = :topic_id" -column_set topics]} {
    [bboard_return_cannot_find_topic_page]
    return
}

set raw_form_vars "
<tr>
 <td>Present Categorized?</td>
 <td>
  <input type=radio name=q_and_a_categorized_p value=t CHECKED> Yes
  <input type=radio name=q_and_a_categorized_p value=f> No
 </td>
</tr>
<tr>
 <td>Days Considered New</td>
 <td><input type=text name=q_and_a_new_days size=5 value=\"$q_and_a_new_days\"> (for how many days a question should show up as \"New\" rather than in its category)</td>
</tr>
<tr>
 <td>Order in which to present new questions?</td>
 <td>
  <input type=radio name=q_and_a_sort_order value=asc CHECKED> Oldest on top
  <input type=radio name=q_and_a_sort_order value=desc> Newest on top
 </td>
</tr>
<tr>
 <td>Ask User to Categorize?</td>
 <td>
  <input type=radio name=q_and_a_solicit_category_p value=t CHECKED> Yes
  <input type=radio name=q_and_a_solicit_category_p value=f> No
 </td>
</tr>
<tr>
 <td>Allow Users to Add New Categories?</td>
 <td>
  <input type=radio name=q_and_a_categorization_user_extensible_p value=t> Yes
  <input type=radio name=q_and_a_categorization_user_extensible_p value=f CHECKED> No
 </td>
</tr>
<tr>
 <td>Use Interest Level System?</td>
 <td>
  <input type=radio name=q_and_a_use_interest_level_p value=t> Yes
  <input type=radio name=q_and_a_use_interest_level_p value=f CHECKED> No
 </td>
</tr>
<tr>
 <td>Policy Statement</td>
 <td>
  <textarea name=policy_statement rows=4 cols=50></textarea>
 </td>
</tr>
<tr>
 <td>Users Can Initiate Threads?</td>
 <td>
  <input type=radio name=users_can_initiate_threads_p value=t CHECKED> Yes
  <input type=radio name=users_can_initiate_threads_p value=f> No
  (you only want to set this to No if you are using this software 
   to collect categorized stories rather than true Q&A)
 </td>
</tr>
"
set merged_form [bt_mergepiece $raw_form_vars $topics]

append page_content "
[bboard_header "Categorization for $topic"]

<h2>Categorization for \"$topic\"</h2>

a Q&A forum in <a href=\"index\">[bboard_system_name]</a>

<p>

\[ <a href=\"q-and-a?[export_url_vars topic topic_id]\">user page (Q&A)</a> |

<a href=\"admin-q-and-a?[export_url_vars topic topic_id]\">in-line Admin Q&A</a> \]

<hr>

<h3>Categorization Information about this Q&A Forum</h3>

<form method=post action=\"update-topic-categorization\">
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

set categories [db_list categories "
select distinct category, 
       upper(category) 
from   bboard_q_and_a_categories 
where  topic_id = :topic_id 
order by 2"]

db_foreach messages "
select msg_id, 
       one_line, 
       sort_key,
       category 
from   bboard
where  topic_id = :topic_id
and    refers_to is null
order by sort_key desc" {

    append page_content "<table><tr><td>
<a href=\"delete-msg?msg_id=$msg_id\" target=admin_sub>DELETE</a>
<td>
<a target=admin_sub href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a>\n"
    append page_content "<td><form target=admin_sub method=POST action=q-and-a-update-category><input type=hidden name=msg_id value=\"$msg_id\"><select name=category>"
    if { $category == "" } {
	append page_content "<option value=\"\" SELECTED>Uncategorized"
    } else {
	append page_content "<option value=\"\">Uncategorized"
    }
    foreach choice $categories {
	if { $category == $choice } {
	    append page_content "<option SELECTED>$choice"
	} else {
	    append page_content "<option>$choice"
	}
    }
    append page_content "</select><input type=submit value=\"Set Category\"></form>"
    append page_content "<td><form target=admin_sub method=POST action=q-and-a-update-category>
<input type=hidden name=msg_id value=\"$msg_id\">
<input type=hidden name=new_category_p value=t>
New: <input type=text name=category size=20>
</form>"

    append page_content "</tr></table>\n"
}

append page_content "</pre>
[bboard_footer]
"


doc_return  200 text/html $page_content