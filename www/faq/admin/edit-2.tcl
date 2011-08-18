# /faq/admin/edit-2.tcl
#
# Records a FAQ edit in the database
#
# by dh@arsdigita.com, created on 12/19/99
#
# $Id: edit-2.tcl,v 3.0.4.2 2000/04/28 15:10:26 carsten Exp $
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

ad_page_variables { 
    { question "" QQ}
    { answer "" QQ}
    entry_id 
    faq_id }


set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)
# entry_id

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

if {![info exists answer] || [empty_string_p [string trim $answer ] ] } {
    incr error_count
    append error_text "<li>You must supply an answer"
}

if {$error_count >0 } {
    ad_scope_return_complaint $error_count $error_text $db
    return
}

# ------------------------------------


ns_db dml $db "update faq_q_and_a
set question = '$QQquestion',
    answer   = '$QQanswer'
where entry_id = $entry_id"

ns_db releasehandle $db

ad_returnredirect "one?[export_url_scope_vars faq_id]"







