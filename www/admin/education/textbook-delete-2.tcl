#
# /www/admin/education/textbook-delete.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows admin to select books to delete from the system.
#

ad_page_variables {
    textbook_id
}

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

ns_db dml $db "delete from edu_classes_to_textbooks_map where textbook_id=$textbook_id"

ns_db dml $db "delete from edu_textbooks where textbook_id=$textbook_id"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect ""

