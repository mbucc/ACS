# admin/faq/faq-add-2.tcl
#
#  Creates a new faq in the database after checking the input
#  use a catch around the insert so double-clicks wont give an error
#
# by dh@arsdigita.com, Created on Dec 20, 1999
#
# $Id: faq-add-2.tcl,v 3.0.4.3 2000/04/28 15:08:59 carsten Exp $
#-----------------------------------

ad_page_variables {
    {next_faq_id}
    {faq_name "" qq}
    {group_id}
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

set db [ns_db gethandle]


if { [empty_string_p $group_id] } {
    set scope "public"
} else {
    set scope "group"
}

ns_db dml $db "begin transaction"

set double_click_p [database_to_tcl_string $db "
select count(*)
from faqs
where faq_id = $next_faq_id"]


if {$double_click_p == "0"} {
    # not a double click, make the new faq in the faqs table
    ns_db dml $db "insert into faqs 
    (faq_id, faq_name, [ad_scope_cols_sql])
    values
    ($next_faq_id, '$QQfaq_name', [ad_scope_vals_sql])"
}

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect "one?faq_id=$next_faq_id"










