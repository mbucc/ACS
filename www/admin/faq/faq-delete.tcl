
# admin/faq/faq-delete.tcl
#
#  asks are you sure you want to delete this FAQ?
#
# by dh@arsdigita.com, Created on Dec 20, 1999
#
# $Id: faq-delete.tcl,v 3.0.4.1 2000/03/16 03:18:00 dh Exp $
#-----------------------------------------------

ad_page_variables {faq_id}

set db [ns_db gethandle]

set faq_name [database_to_tcl_string $db "select faq_name from faqs where faq_id = $faq_id"]

ns_db releasehandle $db 

# --serve the page ------------------------------

ns_return 200 text/html "
[ad_admin_header "Delete a FAQ"]

<h2>Delete a FAQ</h2>

[ad_admin_context_bar [list index "FAQs"] [list "one?faq_id=$faq_id" "$faq_name"] "Delete FAQ"]

<hr>

<P>
<form action=faq-delete-2.tcl method=post>
[export_form_vars faq_id]
Are you sure you want to delete the FAQ <i><b>$faq_name?</b></i><p>
<input type=submit value=\"Yes, Delete\">
</form>

<P>

[ad_admin_footer]"






