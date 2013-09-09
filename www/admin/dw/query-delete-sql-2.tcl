#/www/dw/query-delete-2.tcl
ad_page_contract {
    Set hand edit query string to null

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_id an unique id identifies query
    @cvs-id query-delete-sql-2.tcl,v 1.1.2.1 2000/08/09 14:45:15 richardl Exp
} {
    {query_id:notnull,naturalnum}
}

db_dml dw_clear_hand_edit_query {update queries set query_sql = NULL where query_id = :query_id}

db_release_unused_handles
ad_returnredirect "query.tcl?[export_url_vars query_id]"
