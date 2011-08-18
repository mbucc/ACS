# admin/faq/faq-edit-2.tcl
#
#  Edits  faq in the database after checking the input
#
# by dh@arsdigita.com, Created on Dec 20, 1999
# 
# $Id: faq-edit-2.tcl,v 3.0.4.2 2000/04/28 15:08:59 carsten Exp $
#-----------------------------------

ad_page_variables {
    {faq_id}
    {faq_name "" qq}
    {group_id}
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

set db [ns_db gethandle]


if { [empty_string_p $group_id] } {
    set scope "public"
} else {
    set scope "group"
}

ns_db dml $db "
    update faqs
    set faq_name = '$QQfaq_name',
        group_id = '$group_id',
        scope    = '$scope'
    where faq_id = $faq_id
   "


ns_db releasehandle $db 

ad_returnredirect "one?faq_id=$faq_id"






