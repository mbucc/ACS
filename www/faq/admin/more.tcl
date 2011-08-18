# /faq/admin/more.tcl
#
# Displays a given Q and A
# Gives the option to edit or delete
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: more.tcl,v 3.0.4.2 2000/03/16 04:21:57 dh Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables {faq_id entry_id}

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

set selection [ns_db 1row $db "
select question, answer, faq_id 
from faq_q_and_a
where entry_id = $entry_id"]
set_variables_after_query

set faq_name [database_to_tcl_string $db "select faq_name 
from faqs 
where faq_id = $faq_id"]

if {[info exists scope]&& $scope=="group"} {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_scope_vars] "FAQ Admin"]\
	    [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    "One Question"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_scope_vars]" "FAQs"]\
	    [list "index?[export_url_scope_vars]" "Admin"]\
	    [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    "One Question"\
	    ]"
}

set header_content "
[ad_scope_admin_header "One Question" $db]
[ad_scope_admin_page_title "One Question" $db] "

ns_db releasehandle $db

# --serve the page ---------------

ns_return 200 text/html "

$header_content

$context_bar

<hr>

<b>Q:</b> $question
<P>
<b>A:</b> $answer
<p>
<a href=edit?[export_url_scope_vars entry_id faq_id]>Edit</a> | <a href=delete?[export_url_scope_vars entry_id faq_id]>Delete</a>
<p>
[ad_scope_admin_footer]
"





