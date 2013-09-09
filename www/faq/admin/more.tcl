# /faq/admin/more.tcl
#

ad_page_contract {
    Displays a given Q and A
    Gives the option to edit or delete

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id more.tcl,v 3.2.2.7 2000/09/22 01:37:46 kevin Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull
    entry_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id


db_1row faq_get "
select question, answer, faq_id 
from faq_q_and_a
where entry_id = :entry_id"

set faq_name [db_string faq_name_get "select faq_name 
              from faqs where faq_id = :faq_id"]
db_release_unused_handles


if {[info exists scope] && $scope == "group" } {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_vars] "FAQ Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    "One Question"]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_vars]" "FAQs"]\
	    [list "index?[export_url_vars]" "Admin"]\
	    [list "one?[export_url_vars faq_id]" $faq_name]\
	    "One Question"\
	    ]"
}

set header_content "
[ad_scope_admin_header "One Question"]
[ad_scope_admin_page_title "One Question"]
"


set page_content "
$header_content

$context_bar

<hr>

<b>Q:</b> $question
<P>
<b>A:</b> $answer
<p>
<a href=edit?[export_url_vars entry_id faq_id]>Edit</a> | <a href=delete?[export_url_vars entry_id faq_id]>Delete</a>
<p>
[ad_scope_admin_footer]
"



doc_return  200 text/html $page_content
