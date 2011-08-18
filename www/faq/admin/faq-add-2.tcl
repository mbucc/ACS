# /faq/admin/faq-add-2.tcl
# 
#
# Purpose:  creates a new faq in the database after checking the input
#           use a catch around the insert so double-clicks wont give an error
#
# dh@arsdigita.com created on 12/19/99
#
# $Id: faq-add-2.tcl,v 3.0.4.3 2000/04/28 15:10:26 carsten Exp $#


# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (group_id)

ad_page_variables {
    {next_faq_id}
    {faq_name "" qq}
    {scope}
}

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

# -- form validation ------------------

set error_count 0
set error_text ""

if {![info exists faq_name] || [empty_string_p [string trim $faq_name] ] } {
    incr error_count
    append error_text "<li>You must supply a name for the new FAQ."
}

if {$error_count > 0 } {
    ad_scope_return_complaint $error_count $error_text $db
    return
}

#-------------------------------------

set err_msg ""

set sql "
insert into faqs
(faq_id, faq_name, [ad_scope_cols_sql])
values
($next_faq_id, '$QQfaq_name', [ad_scope_vals_sql])"

ns_db dml $db "begin transaction"

set double_click_p [database_to_tcl_string $db "
select count(*)
from faqs
where faq_id = $next_faq_id"]


if {$double_click_p == "0"} {
    # not a double click
    
    # make the new faq in the faqs table
    ns_db dml $db $sql

}


ns_db dml $db "end transaction"


ns_db releasehandle $db


ad_returnredirect "index?[export_url_scope_vars]"






