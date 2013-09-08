# /faq/admin/faq-add-2.tcl
# 

ad_page_contract {
    Purpose:  creates a new faq in the database after checking the input
    use a catch around the insert so double-clicks wont give an error

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id faq-add-2.tcl,v 3.3.2.7 2001/01/10 18:28:21 khy Exp#

    Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
    the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
    group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    faq_id:integer,notnull,verify
    faq_name:optional
    scope:optional
    group_id:integer,optional
}


ad_scope_error_check

ad_scope_authorize $scope admin group_admin none

# -- form validation ------------------

set error_count 0
set error_text ""

if {![info exists faq_name] || [empty_string_p [string trim $faq_name] ] } {
    incr error_count
    append error_text "<li>You must supply a name for the new FAQ."
}

if {$error_count > 0 } {
    ad_scope_return_complaint $error_count $error_text
    return
}

#-------------------------------------

set err_msg ""

set sql "
insert into faqs
(faq_id, faq_name, [ad_scope_cols_sql])
values
(:faq_id, :faq_name, [ad_scope_vals_sql])"

db_transaction {
    set double_click_p [db_string faq_count_get "
    select count(*) from faqs
    where faq_id = :faq_id"]

    if {$double_click_p == "0"} {
	# not a double click

	# make the new faq in the faqs table
	db_dml faq_insert $sql
    }
}

db_release_unused_handles

ad_returnredirect "index?[export_url_vars]"

