#/www/dw/query-add-order-by.tcl

ad_page_contract {
    Add this column into order by list. Re-execute the query.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_id an unique id identifies a query
    @param column_name column to add to order by list
    @cvs-id query-add-order-by.tcl,v 1.1.2.1 2000/08/09 14:45:14 richardl Exp
} {
    {query_id:notnull,naturalnum}
    {column_name:notnull}
}

db_dml dw_add_order_by {insert into query_columns 
(query_id, column_name, what_to_do)
values
(:query_id, :column_name, 'order_by')}

db_release_unused_handles
ad_returnredirect "query-execute.tcl?query_id=$query_id"

