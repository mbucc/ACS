# admin/faq/faq-delete.tcl
#

ad_page_contract {
    asks are you sure you want to delete this FAQ?

    @author dh@arsdigita.com
    @creation-date Dec 20, 1999
    @cvs-id faq-delete.tcl,v 3.4.2.7 2000/09/22 01:35:08 kevin Exp
} {
    faq_id:integer,notnull
}


set faq_name [db_string faq_name_get "select faq_name from faqs where faq_id = :faq_id"]
db_release_unused_handles 


set page_content "
[ad_admin_header "Delete a FAQ"]

<h2>Delete a FAQ</h2>

[ad_admin_context_bar [list index "FAQs"] [list "one?faq_id=$faq_id" "$faq_name"] "Delete FAQ"]

<hr>

<P>
<form action=faq-delete-2 method=post>
[export_form_vars faq_id]
Are you sure you want to delete the FAQ <i><b>$faq_name?</b></i><p>
<center><input type=submit value=\"Yes, Delete\"></center>
</form>

<P>

[ad_admin_footer]"


 
doc_return  200 text/html $page_content
