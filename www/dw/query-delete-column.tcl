# $Id: query-delete-column.tcl,v 3.0.4.1 2000/04/28 15:09:58 carsten Exp $
set_the_usual_form_variables

# query_id, rowid
# we use rowid rather than column_name because the same column could be spec'd
# in a query twice for different reasons (or maybe even for the same reason)

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from query_columns where query_id = $query_id and rowid = '$QQrowid'"] == 0 } {
    ad_return_error "Could not find column" "Could not find a column for this query; either the column was already deleted, something is wrong with your browser, or something is wrong with our programming."
    return
}

ns_db dml $db "delete from query_columns where query_id = $query_id and rowid = '$QQrowid'"

ad_returnredirect "query.tcl?query_id=$query_id"
