# /faq/admin/faq-add.tcl
#

ad_page_contract {
    A form for creating a new faq (just the name and associated group)

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id faq-add.tcl,v 3.3.2.8 2001/01/10 18:27:58 khy Exp#

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

set faq_id [db_string faq_id_get "select faq_id_sequence.nextval from dual"]
db_release_unused_handles


if { [info exists scope] && $scope == "group" } {
    set context_bar "[ad_scope_admin_context_bar  \
	     [list index?[export_url_vars] "FAQ Admin"]\
	     "Create a FAQ"\
	    ]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_vars]" "FAQs"]\
	    [list index?[export_url_vars] "Admin"]\
	    "Create a FAQ"\
	    ]"
}

set header_content "
[ad_scope_admin_header "Create a FAQ"]
[ad_scope_admin_page_title "Create a FAQ"]
"


set page_content "

$header_content

$context_bar

<hr>

<form action=faq-add-2  method=post>
[export_form_vars -sign faq_id]
<table>
<tr>
 <td><b>FAQ Name</b>:</td>
 <td><input type=text name=faq_name></td>
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



doc_return  200 text/html $page_content
