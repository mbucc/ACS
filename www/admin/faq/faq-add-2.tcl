# admin/faq/faq-add-2.tcl
#

ad_page_contract {
    Creates a new faq in the database after checking the input
    use a catch around the insert so double-clicks wont give an error

    @author dh@arsdigita.com
    @creation-date Dec 20, 1999
    @cvs-id faq-add-2.tcl,v 3.3.2.7 2001/01/10 18:38:11 khy Exp
} {
    faq_id:integer,notnull,verify
    faq_name:optional
    group_id:integer,optional
}


# -- form validation ------------------
set error_count 0
set error_text ""

if {![info exists faq_name] || [empty_string_p [string trim $faq_name]] } {
    incr error_count
    append error_text "<li>You must supply a name for the new FAQ."
}

if {$error_count > 0 } {
    ad_return_complaint $error_count $error_text
    return
}


#-------------------------------------
if { [empty_string_p $group_id] } {
    set scope "public"
} else {
    set scope "group"
}

db_transaction {
    set double_click_p [db_string faq_count_get "
    select count(*)
    from faqs
    where faq_id = :faq_id"]

    if {$double_click_p == "0"} {
	# not a double click, make the new faq in the faqs table
	db_dml faq_name_insert "insert into faqs
	(faq_id, faq_name, [ad_scope_cols_sql])
	values
	(:faq_id, :faq_name, [ad_scope_vals_sql])"
    }
}

db_release_unused_handles

ad_returnredirect "one?[export_url_vars faq_id]"
