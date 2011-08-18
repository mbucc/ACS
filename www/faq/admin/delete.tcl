# /faq/admin/delete.tcl
# 
# Delete verification page
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: delete.tcl,v 3.0.4.2 2000/03/16 03:57:23 dh Exp $
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables {entry_id faq_id}
set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

# get the faq_name and faq_id

set selection [ns_db 1row $db "
select f.faq_name, 
       f.faq_id
from faqs f, faq_q_and_a fqa
where fqa.entry_id = $entry_id
and   fqa.faq_id = f.faq_id "]

set_variables_after_query

if {[info exists scope]&& $scope=="group"} {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_scope_vars] "FAQ Admin"]\
	    [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    [list "more?[export_url_scope_vars faq_id entry_id]" "One Question"]\
	    "Delete"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_scope_vars]" "FAQs"]\
	    [list "index?[export_url_scope_vars]" "Admin"]\
	    [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    [list "more?[export_url_scope_vars faq_id entry_id]" "One Question"]\
	    "Delete"]"
}

set header_content "
[ad_scope_admin_header "Delete" $db]
[ad_scope_admin_page_title "Delete" $db] "

ns_db releasehandle $db 

# --serve the page ---------------------------
ns_return 200 text/html "

$header_content

$context_bar

<hr>

<form action=delete-2.tcl method=post>
[export_form_scope_vars entry_id faq_id]
Are you sure you want to delete this FAQ question and answer?<P>
<input type=submit value=\"Yes, Delete\">
</form>

[ad_scope_admin_footer]"








