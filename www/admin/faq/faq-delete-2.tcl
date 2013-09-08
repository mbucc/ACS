# /www/admin/faq/faq-delete-2.tcl
#

ad_page_contract {
    deletes a FAQ (defined by faq_id) from the database

    @author dh@arsdigita.com
    @creation-date Dec 20, 1999
    @cvs-id faq-delete-2.tcl,v 3.2.2.7 2000/07/26 05:50:18 kevin Exp
} {
    faq_id:integer,notnull
}


db_transaction {
    # delete the contents of the FAQ (question and answers)
    db_dml faq_delete "delete from faq_q_and_a where faq_id = :faq_id"

    # delete the FAQ properties (name, associated group, scope)
    db_dml faq_delete "delete from faqs where faq_id = :faq_id"
}

db_release_unused_handles
ad_returnredirect index
