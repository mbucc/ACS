# picklist-row-delete.tcl

ad_page_contract {
    @param table_name
    @param rowid

    @author
    @creation-date
    @cvs-id picklist-row-delete.tcl,v 3.1.6.3 2000/07/21 03:56:58 ron Exp
} {
    table_name
    rowid
}



db_dml telere_from_picklist_table "delete from $table_name where rowid=:rowid"
db_release_unused_handles

ad_returnredirect picklists.tcl