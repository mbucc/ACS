# /faq/admin/add-2.tcl
# 

ad_page_contract {
    Records new question/answers into the faq table

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id add-2.tcl,v 3.3.2.11 2001/01/10 18:33:43 khy Exp

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} { 
    question:html,trim,notnull,string_length(max|4000)
    answer:html,trim,notnull,string_length(max|4000)
    entry_id:integer,notnull,verify
    last_entry_id:integer,notnull
    faq_id:integer,notnull
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

faq_admin_authorize $faq_id

# -- form validation -----------------
set error_count 0
set error_text ""
if {![info exists question] || [empty_string_p $question] } {
    incr error_count
    append error_text "<li>You must supply a question"
}

if {![info exists answer] || [empty_string_p $answer] } {
    incr error_count
    append error_text "<li>You must supply an answer"
}

if {$error_count >0 } {
    ad_scope_return_complaint $error_count $error_text
    return
}



db_transaction {
    # check if this is a double click
    set double_click_p [db_string faq_count_get "
    select count(*) from faq_q_and_a
    where entry_id = :entry_id"]

    if {$double_click_p == "0" } {
	# this isn't a double click
	# go ahead and do the inserts.

	if {$last_entry_id != "-1"} {
	    # this q+a being added after an existing question
	    # make room - then do the insert 
    
	    set old_sort_key [db_string faq_sortkey_get "select sort_key 
	    from faq_q_and_a
	    where entry_id = :last_entry_id"]

	    set sql_update_q_and_a "
	    update faq_q_and_a
	    set sort_key = sort_key + 1
	    where sort_key > :old_sort_key"

	    db_dml faq_update $sql_update_q_and_a
    
	    set sql_insert_q_and_a "
	    insert into faq_q_and_a
	    (entry_id, question, answer, sort_key, faq_id)
	    values
	    (:entry_id, :question, :answer, :old_sort_key+1, :faq_id)"

	    db_dml faq_insert $sql_insert_q_and_a
	} else {
	    # this q+a being added at the end of the FAQ
    
	    set max_sort_key [db_string faq_maxkey_get "select NVL(max(sort_key),1)
	    from faq_q_and_a"]

	    set sql_update_q_and_a "
	    insert into faq_q_and_a 
	    (entry_id, question, answer, sort_key, faq_id)
	    values
	    (:entry_id, :question, :answer, :max_sort_key+1, :faq_id)"

	    db_dml faq_new_insert $sql_update_q_and_a
	}

    }
}

db_release_unused_handles
ad_returnredirect "one?[export_url_vars faq_id]"

