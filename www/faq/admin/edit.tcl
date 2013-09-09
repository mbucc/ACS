# /faq/admin/edit.tcl
#

ad_page_contract {
    Edits a FAQ entry

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id edit.tcl,v 3.3.2.7 2000/09/22 01:37:44 kevin Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    entry_id:integer,notnull
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id


db_1row faq_entry_get "
select question, answer 
from faq_q_and_a 
where entry_id = :entry_id"

set faq_name [db_string faq_name_get "
select faq_name from faqs where faq_id = :faq_id"]
db_release_unused_handles


if { [info exists scope] && $scope == "group" } {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_vars] "FAQ Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    [list "more?[export_url_vars faq_id entry_id]" "One Question"]\
	    "Edit"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_vars]" "FAQs"] \
	    [list "index?[export_url_vars]" "Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    [list "more?[export_url_vars faq_id entry_id]" "One Question"]\
	    "Edit"]"
}

set header_content "
[ad_scope_admin_header "Edit Q and A"]
[ad_scope_admin_page_title "Edit a Question"]
"


set page_content "

$header_content

$context_bar

<hr>

Please edit the Question and Answer for the FAQ $faq_name:

<table>
<form action=edit-2 method=post>
[export_form_vars entry_id faq_id]

<tr>
 <td valign=top align=right><b>Question:</b></td>
 <td><textarea rows=3 cols=50 wrap name=\"question\">[ns_quotehtml $question]</textarea></td>
</tr>
<tr>
 <td valign=top align=right><b>Answer:</b></td>
 <td><textarea rows=10 cols=50 wrap name=\"answer\">[ns_quotehtml $answer]</textarea></td>
</tr>
<tr>
 <td></td>
 <td><input type=submit value=\"Submit\"></td>
</tr>
</table>

</form>

[ad_scope_admin_footer]"



doc_return  200 text/html $page_content
