# /faq/admin/add.tcl
# 
# Purpose:  allows the user to add a new questions and answers
#
# dh@arsdigita.com created on 12/19/99
#
# $Id: add.tcl,v 3.0.4.2 2000/03/16 03:56:49 dh Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)
# faq_id 
# maybe: entry_id

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

if {[info exists entry_id] } {
    set last_entry_id $entry_id
} else {
    set last_entry_id "-1"
}

set new_entry_id [database_to_tcl_string $db "select faq_id_sequence.nextval from dual"]

# get the faq_name
set selection [ns_db 1row $db "
select f.faq_name
from faqs f
where   f.faq_id = $faq_id"]

set_variables_after_query

if {[info exists scope]&& $scope=="group"} {
    set context_bar "[ad_scope_admin_context_bar  \
	     [list index?[export_url_scope_vars] "FAQ Admin"]\
	      [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    "Add"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list ../index?[export_url_scope_vars] "FAQs"] \
	    [list "index?[export_url_scope_vars]" "Admin"] \
	    [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    "Add"]"
}


set header_content "
[ad_scope_admin_header "Add Q and A" $db]
[ad_scope_admin_page_title "Add a Question to $faq_name" $db]
"

ns_db releasehandle $db

# --serve the page -----------

ns_return 200 text/html "

$header_content

$context_bar

<hr>

Please enter the new Question and Answer for the FAQ:

<table>

<form action=add-2.tcl method=post>
[export_form_scope_vars last_entry_id new_entry_id faq_id]

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











