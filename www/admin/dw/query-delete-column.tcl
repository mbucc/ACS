#/www/dw/query-delete-column.tcl

ad_page_contract {
    Delete column from this query.
    We use rowid rather than column_name because the same column could be spec'd
    in a query twice for a different reasons (or maybe even for the same reason).

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @param query_id an unique id identifies a query
    @param row_id id of a column to be delete
    @cvs-id query-delete-column.tcl,v 1.1.2.1 2000/08/09 14:45:15 richardl Exp
} {
    {query_id:notnull,naturalnum}
    {row_id:notnull}
}

#I changed variable name from rowid to row_id because when using :rowid Oracle will give a bind/host error. - David D.
    
set selection [db_0or1row dw_check_if_column_exists {select count(*) from query_columns where query_id=:query_id and rowid=:row_id}]
if {$selection == 0} {
    ad_return_error "Could not find column" "Could not find a column for this query; either the column was already deleted, something is wrong with your browser, or something is wrong with our programming."
    return
}

db_dml dw_delete_column {delete from query_columns where query_id = :query_id and rowid=:row_id}

db_release_unused_handles
ad_returnredirect "query.tcl?query_id=$query_id"

