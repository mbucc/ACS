#/www/dw/query-edit-sql-2.tcl

ad_page_contract {
    Update hand edit SQL query into table
    
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_id an unique id identifies query
    @param query_sql the new sql statement
    @cvs-id query-edit-sql-2.tcl,v 1.1.2.1 2000/08/09 14:45:16 richardl Exp
} {
    {query_id:naturalnum,notnull}
    {query_sql:notnull}
}

db_dml dw_update_hand_edit_query {update queries set query_sql = :query_sql where query_id = :query_id}

db_release_unused_handles
ad_returnredirect "query.tcl?[export_url_vars query_id]"

