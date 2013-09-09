# /faq/admin/delete.tcl
# 

ad_page_contract {
    Delete verification page

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id delete.tcl,v 3.3.2.7 2000/09/22 01:37:44 kevin Exp

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

# get the faq_name and faq_id

db_1row faq_name_get "
select f.faq_name, 
       f.faq_id
from faqs f, faq_q_and_a fqa
where fqa.entry_id = :entry_id
and   fqa.faq_id = f.faq_id"
db_release_unused_handles 


if { [info exists scope] && $scope == "group" } {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_vars] "FAQ Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    [list "more?[export_url_vars faq_id entry_id]" "One Question"]\
	    "Delete"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_vars]" "FAQs"]\
	    [list "index?[export_url_vars]" "Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    [list "more?[export_url_vars faq_id entry_id]" "One Question"]\
	    "Delete"]"
}

set header_content "
[ad_scope_admin_header "Delete"]
[ad_scope_admin_page_title "Delete"]
"


set page_content "

$header_content

$context_bar

<hr>

<form action=delete-2 method=post>
[export_form_vars entry_id faq_id]
Are you sure you want to delete this FAQ question and answer?<P>
<input type=submit value=\"Yes, Delete\">
</form>

[ad_scope_admin_footer]"
 
doc_return  200 text/html $page_content
