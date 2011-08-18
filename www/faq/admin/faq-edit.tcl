# /faq/admin/faq-edit.tcl
# 
# Asks are you sure you want to delete this FAQ?
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: faq-edit.tcl,v 3.0.4.2 2000/03/16 04:20:18 dh Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

set faq_name [database_to_tcl_string $db "
select faq_name 
from faqs
where faq_id = $faq_id"] 

if {[info exists scope]&& $scope=="group"} {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_scope_vars] "FAQ Admin"]\
	    [list "one?[export_url_scope_vars faq_id]" $faq_name]\
	    "Edit FAQ $faq_name"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_scope_vars]" "FAQs"] \
	    [list index?[export_url_scope_vars] "Admin"] \
	    [list "one?faq_id=$faq_id" "$faq_name"]\
	    "Edit FAQ $faq_name "\
	    ]"
}

set header_content "
[ad_scope_admin_header "Edit FAQ $faq_name" $db]
[ad_scope_admin_page_title "Edit FAQ $faq_name" $db] "

ns_db releasehandle $db

# -- serve the page -------------------------------



ns_return 200 text/html "

$header_content

$context_bar
<hr>

<form action=faq-edit-2.tcl  method=post>
[export_form_scope_vars faq_id]
<table>
<tr>
 <td><b>FAQ Name</b>:</td>
 <td><input type=text name=faq_name value=\"[philg_quote_double_quotes $faq_name]\"></td>
</tr>

 <td></td>
<tr>
</tr>
<tr>
 <td></td>
 <td><input type=submit value=\"Submit\"></td>
</tr>
</table>


[ad_scope_admin_footer]"













