# admin/faq/faq-delete-2.tcl
#
#   deletes a FAQ (defined by faq_id) from the database
#
# by dh@arsdigita.com,  Created on Dec 20, 1999
#
#
# $Id: faq-delete-2.tcl,v 3.0.4.1 2000/03/16 03:34:33 dh Exp $
#---------------------------------

ad_page_variables {faq_id}

set db [ns_db gethandle]

# get the faq_name 
set faq_name [database_to_tcl_string $db "select faq_name from faqs where faq_id = $faq_id"]

ns_db dml $db "begin transaction"

# delete the contents of the FAQ (question and answers)
ns_db dml $db "delete from faq_q_and_a where faq_id = $faq_id"

# delete the FAQ properties (name, associated group, scope)
ns_db dml $db "delete from faqs where faq_id = $faq_id"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ns_return 200 text/html "
[ad_admin_header "FAQ Deleted"]
<h2>FAQ Deleted</h2>
[ad_admin_context_bar [list "index" "FAQs"] "deleted"]
<hr>
The FAQ <b><i>$faq_name</i></b> has been deleted.
[ad_admin_footer]
"





