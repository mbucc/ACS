#/www/dw/query-add-column-3.tcl
ad_page_contract {

    Add new column along with its information in to persistent storage.

    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?

    @param query_id an unique id identifies a query
    @param column_name name of the new column
    @param what_to_do property of this column
    @param pretty_name more descriptive name for this column
    @param value1 
    @param value2 
    @cvs-id query-add-column-3.tcl,v 1.1.2.1 2000/08/09 14:45:13 richardl Exp
} {
    {query_id:notnull,naturalnum}
    {column_name:sql_identifier,notnull}
    {what_to_do:notnull}
    {pretty_name:optional}
    {value1:optional}
    {value2:optional}
}

set target_columns [list query_id column_name what_to_do]
set target_values [list ":query_id" ":column_name" ":what_to_do"]

if { [info exists pretty_name] && ![empty_string_p $pretty_name] } {
    lappend target_columns pretty_name
    lappend target_values ":pretty_name"
}

if { [info exists value1] && ![empty_string_p $value1] } {
    lappend target_columns value1
    lappend target_values ":value1"
}

if { [info exists value2] && ![empty_string_p $value2] } {
    lappend target_columns value2
    lappend target_values ":value2"
}



db_dml dw_add_new_column "insert into query_columns ([join $target_columns ", "]) 
values 
([join $target_values ", "])"

db_release_unused_handles
ad_returnredirect "query.tcl?query_id=$query_id"
