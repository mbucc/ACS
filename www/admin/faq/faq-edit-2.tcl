# admin/faq/faq-edit-2.tcl
#

ad_page_contract {
    Edits faq in the database after checking the input

    @author dh@arsdigita.com
    @creation-date Dec 20, 1999
    @cvs-id faq-edit-2.tcl,v 3.3.2.7 2000/07/21 22:45:03 paul Exp
} {
    faq_id:integer,notnull
    faq_name:optional
    group_id:integer,optional
}


# -- form validation ------------------
set error_count 0
set error_text ""

if {![info exists faq_name] || [empty_string_p $faq_name] } {
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

db_dml faq_edit "
    update faqs
    set faq_name = :faq_name,
        group_id = :group_id,
        scope    = :scope
    where faq_id = :faq_id"

db_release_unused_handles 

ad_returnredirect "one?faq_id=$faq_id"

