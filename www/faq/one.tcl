# /faq/one.tcl
# 
ad_page_contract {
    @author dh@arsdigita.com
    @creation-date December 1999
    @cvs-id one.tcl,v 3.3.2.9 2000/09/22 01:37:42 kevin Exp
 
    displays the FAQ

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


# check that this user can see the faq --------------
faq_authorize $faq_id


# check if the user can maintain this faq and generate appropriate maintainers url --------
if { [faq_maintaner_p $faq_id] } {

    if { $scope == "public" } {
	set admin_url "/faq/admin"
    } else {
	set short_name [db_string faq_groupname_get "select short_name
                                          from user_groups
                                          where group_id = :group_id"]
	set admin_url "/[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]/[ad_urlencode $short_name]/faq"
    }
   
    append helper_args [list "$admin_url/one?[export_url_vars faq_id]" "Maintain this FAQ"]
} else {
    # user is not authorized to mantain this faq
    set helper_args ""
}

# get the faq_name ----------------------------------
set faq_name [db_string faq_faqname_get "select faq_name
                                from faqs
                                where faq_id = :faq_id"]

# get the faq from the database
set sql "
select question, 
       answer,
       entry_id,
       sort_key
from   faq_q_and_a 
where  faq_id = :faq_id
order by sort_key"

set q_and_a_list ""
set q_list ""
set question_number 0
db_foreach faq_get $sql {
    incr question_number
    append q_list "<li><a href=#$question_number>$question</a>\n"
    append q_and_a_list "
   <li><a name=$question_number></a>
       <b>Q: </b><i>$question</i><p>
       <b>A: </b>$answer<p><br><p>"
}
db_release_unused_handles


set page_content "
[ad_scope_header $faq_name]
[ad_scope_page_title $faq_name]
[ad_scope_context_bar_ws_or_index [list "index?[export_url_vars]" "FAQs"] "One FAQ"]

<hr>
[help_upper_right_menu $helper_args]
[ad_scope_navbar]
<p>
"

if {![empty_string_p $q_list] } {
    append page_content "
    Frequently Asked Questions:
    <ol>
    $q_list
    </ol>
    <hr>
    "
    if {![empty_string_p $q_and_a_list] } {
	append page_content "
	Questions and Answers:
	<ol>
	$q_and_a_list
	</ol>
	<p>
	"
    }
} else {
    append page_content "
    <p>
    No Questions/Answers available
    <p>" 
}

append page_content "
[ad_scope_footer]"



doc_return  200 text/html $page_content
