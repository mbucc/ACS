# /www/admin/static/mark-page-obsolete.tcl

ad_page_contract {
    Deletes a row from the static_pages table

    @author luke@arsdigita.com
    @creation-date Jul 6 2000

    @cvs-id mark-page-obsolete.tcl,v 3.1.2.5 2000/09/22 01:36:08 kevin Exp
} {
    page_id:notnull
}


db_dml set_page_to_obsolete "update static_pages set obsolete_p='t' where page_id=:page_id"

doc_return  200 text/html "The page has been marked obsolete.  It will no longer appear in the deleted pages report."


