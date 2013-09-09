# /faq/admin/edit-2.tcl
#
ad_page_contract {
    Records a FAQ edit in the database

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id edit-2.tcl,v 3.3.2.7 2000/09/11 00:38:11 kevin Exp

} {
    question:allhtml
    answer:allhtml
    entry_id:integer,notnull
    faq_id:integer,notnull
    scope:optional
    group_id:optional
}

ad_scope_error_check

faq_admin_authorize $faq_id

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
    ad_scope_return_complaint $error_count $error_text
    return
}


# ------------------------------------

db_dml faq_update "update faq_q_and_a
set question = :question,
    answer   = :answer
where entry_id = :entry_id"

db_release_unused_handles

ad_returnredirect "one?[export_url_vars faq_id]"

