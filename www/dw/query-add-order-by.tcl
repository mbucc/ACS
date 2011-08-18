# $Id: query-add-order-by.tcl,v 3.0.4.1 2000/04/28 15:09:58 carsten Exp $
# we get called from a query execution, so we add the order by and
# redirect

set_the_usual_form_variables

# query_id, column_name

set db [ns_db gethandle]

ns_db dml $db "insert into query_columns 
(query_id, column_name, what_to_do)
values
($query_id, '$QQcolumn_name', 'order_by')"

ad_returnredirect "query-execute.tcl?query_id=$query_id"

