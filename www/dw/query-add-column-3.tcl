# $Id: query-add-column-3.tcl,v 3.0.4.1 2000/04/28 15:09:58 carsten Exp $
set_the_usual_form_variables

# query_id, column_name, what_to_do, maybe pretty_name, value1, value2

set target_columns [list query_id column_name what_to_do]
set target_values [list $query_id "'$QQcolumn_name'" "'$QQwhat_to_do'"]

if { [info exists pretty_name] && ![empty_string_p $pretty_name] } {
    lappend target_columns pretty_name
    lappend target_values "'$QQpretty_name'"
}

if { [info exists value1] && ![empty_string_p $value1] } {
    lappend target_columns value1
    lappend target_values "'$QQvalue1'"
}

if { [info exists value2] && ![empty_string_p $value2] } {
    lappend target_columns value2
    lappend target_values "'$QQvalue2'"
}

set db [ns_db gethandle]

ns_db dml $db "insert into query_columns ([join $target_columns ", "]) 
values 
([join $target_values ", "])"

ad_returnredirect "query.tcl?query_id=$query_id"
