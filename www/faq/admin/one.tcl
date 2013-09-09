# /faq/admin/one.tcl
# 

ad_page_contract {
    Purpose:  displays Questions from a given  FAQ  (faq_id)
    allows for reordering and editing and deletion

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id one.tcl,v 3.2.2.7 2000/09/22 01:37:46 kevin Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull
    scope:optional
    group_id:optional
}


ad_scope_error_check

faq_admin_authorize $faq_id


set faq_name [db_string faq_name_get "
select faq_name from faqs
where faq_id = :faq_id"]

set total_question_count [db_string faq_count_get "
select count(*) from faq_q_and_a
where faq_id = :faq_id"]

# get the FAQ from the database
set sql "
select question, 
       answer,
       entry_id,
       sort_key
from  faq_q_and_a
where faq_id = :faq_id
order by sort_key"

set q_and_a_list ""
set question_number 0

db_foreach faq_get $sql {
    incr question_number
    append q_and_a_list "
<tr>
 <td>$question_number. <a href=more?[export_url_vars faq_id entry_id]>[expr {[string length $question]>40?"[string range $question 0 40] ... ":"$question"}]</a></td>
 <td> <font face=\"MS Sans Serif, arial,helvetica\"  size=\"1\"><a href=add?[export_url_vars entry_id faq_id]>insert after</a> [expr {$question_number < $total_question_count ?"| <a href=swap?[export_url_vars entry_id faq_id]>swap with next</a>":""}]</td>
</tr>"
}
db_release_unused_handles


if { [info exists scope] && $scope == "group" } {
    set context_bar "[ad_scope_admin_context_bar  \
	    [list index?[export_url_vars] "FAQ Admin"]\
	    "$faq_name FAQ"\
	    ]"
} else {
    set context_bar "[ad_scope_context_bar_ws \
	    [list "../index?[export_url_vars]" "FAQs"]\
	    [list index?[export_url_vars] "Admin"]\
	    "$faq_name FAQ"\
	    ]"
}

set page_content "
[ad_scope_admin_header "FAQ Admin"]
[ad_scope_admin_page_title "New FAQ Administration"]
$context_bar
<hr>
"


switch $scope {
    public {
	append html "
	<a href=\"/faq/one?[export_url_vars faq_id]\">$faq_name FAQ user page</a>
	"
    }
    group {
	append html "
	<a href=\"[ns_set get $group_vars_set group_public_url]/faq/one?[export_url_vars faq_id]\">$faq_name FAQ user page</a>
	"
    }
}

append html "
<table>
$q_and_a_list
</table>

<p>

<li><a href=add?[export_url_vars faq_id]>Add</a> a new question and answer.<br>
<li><a href=faq-edit?[export_url_vars faq_id]>Edit</a> the FAQ
<li><a href=faq-delete?[export_url_vars faq_id]>Delete</a> the FAQ
"

append page_content "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

    

doc_return  200 text/html $page_content
