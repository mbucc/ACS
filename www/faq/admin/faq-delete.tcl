# /faq/admin/faq-delete.tcl
#

ad_page_contract {
    Asks are you sure you want to delete this FAQ?

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id faq-delete.tcl,v 3.4.2.7 2000/09/22 01:37:46 kevin Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id

set faq_name [db_string faq_name_get "select faq_name from faqs where faq_id = :faq_id"]
db_release_unused_handles


if {[info exists scope]&& $scope=="group"} {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_vars] "FAQ Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    "Delete a FAQ "\
	    ]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_vars]" "FAQs"]\
	    [list index?[export_url_vars] "Admin"]\
	    [list "one?faq_id=$faq_id" "$faq_name"]\
	    "Delete a FAQ"\
	    ]"
}

set header_content "
[ad_scope_admin_header "Delete a FAQ"]
[ad_scope_admin_page_title "Delete a FAQ"]
"


set page_content "

$header_content

$context_bar

<hr>

<P>
<form action=faq-delete-2 method=post>
[export_form_vars faq_id]
Are you sure you want to delete the FAQ <i><b>$faq_name?</b></i><p>
<center><input type=submit value=\"Yes, Delete\"></center>
</form>

<P>

[ad_scope_admin_footer]"



doc_return  200 text/html $page_content
