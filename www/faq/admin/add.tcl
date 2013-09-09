# /faq/admin/add.tcl
# 

ad_page_contract {
    Purpose:  allows the user to add a new questions and answers

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id add.tcl,v 3.4.2.9 2001/01/10 18:31:32 khy Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
    entry_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id

if {[info exists entry_id] } {
    set last_entry_id $entry_id
} else {
    set last_entry_id "-1"
}

set entry_id [db_string faq_id_get "select faq_id_sequence.nextval from dual"]


db_1row faq_name_get "
select f.faq_name from faqs f
where f.faq_id = :faq_id"

db_release_unused_handles


if { [info exists scope] && $scope == "group" } {
    set context_bar "[ad_scope_admin_context_bar  \
	     [list index?[export_url_vars] "FAQ Admin"]\
	      [list "one?[export_url_vars faq_id]" $faq_name]\
	    "Add"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list ../index?[export_url_vars] "FAQs"] \
	    [list "index?[export_url_vars]" "Admin"] \
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    "Add"]"
}

set header_content "
[ad_scope_admin_header "Add Q and A"]
[ad_scope_admin_page_title "Add a Question to $faq_name"]"


set page_content "
$header_content
$context_bar

<hr>

Please use HTML and enter the new Question and Answer for the FAQ.<br>

<table>

<form action=add-2 method=post>
[export_form_vars last_entry_id faq_id]
[export_form_vars -sign entry_id]

<tr>
 <td valign=top align=right><b>Question:</b></td>
 <td><textarea rows=3 cols=50 wrap name=\"question\"></textarea></td>
</tr>
<tr>
 <td valign=top align=right><b>Answer:</b></td>
 <td><textarea rows=10 cols=50 wrap name=\"answer\"></textarea></td>
</tr>
<tr>
 <td colspan=2 align=center><input type=submit value=\"Submit\"></td>
</tr>
</table>
</form>

<p>

[ad_scope_admin_footer]"



doc_return  200 text/html $page_content
