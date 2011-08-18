# /faq/admin/add-2.tcl
# 
# Records new question/answers into the faq table
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: add-2.tcl,v 3.0.4.2 2000/04/28 15:10:25 carsten Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables { 
    { question -- QQ } 
    { answer -- QQ } 
    new_entry_id 
    last_entry_id
    faq_id }

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check
set db [ns_db gethandle]
faq_admin_authorize $db $faq_id

# -- form validation -----------------
set error_count 0
set error_text ""
if {![info exists question] || [empty_string_p [string trim $question] ] } {
    incr error_count
    append error_text "<li>You must supply a question"
}

if {![info exists answer] || [empty_string_p [string trim $answer] ] } {
    incr error_count
    append error_text "<li>You must supply an answer"
}

if {$error_count >0 } {
    ad_scope_return_complaint $error_count $error_text $db
    return
}

# ------------------------------------

ns_db dml $db "begin transaction"

# check if this is a double click
set double_click_p [database_to_tcl_string  $db "
select count(*) 
from faq_q_and_a
where entry_id = $new_entry_id"]

if {$double_click_p == "0" } {
    # this isn't a double click
    # go ahead and do the inserts.

    if {$last_entry_id != "-1"} {
	# this q+a being added after an existing question
	# make room - then do the insert 
    
        set old_sort_key [database_to_tcl_string $db "select sort_key 
	from faq_q_and_a
	where entry_id = $last_entry_id"]

	set sql_update_q_and_a "
	update faq_q_and_a
	set sort_key = sort_key + 1
	where sort_key > $old_sort_key"

	ns_db dml $db $sql_update_q_and_a
    
	set sql_insert_q_and_a "
	insert into faq_q_and_a
	(entry_id, question, answer, sort_key, faq_id)
	values
	($new_entry_id,'$QQquestion','$QQanswer',$old_sort_key+1, $faq_id) "
	
	ns_db dml $db $sql_insert_q_and_a
		
    } else {
	# this q+a being added at the end of the FAQ
    
	set max_sort_key [database_to_tcl_string $db "select max(sort_key) 
	from faq_q_and_a "]

	set sql_update_q_and_a "
	insert into faq_q_and_a 
	(entry_id, question, answer, sort_key, faq_id)
	values
	($new_entry_id, '$QQquestion','$QQanswer',$max_sort_key+1, $faq_id) "
	
	ns_db dml $db $sql_update_q_and_a
    }

}
ns_db dml $db "end transaction"

ad_returnredirect "one?[export_url_scope_vars faq_id]"










