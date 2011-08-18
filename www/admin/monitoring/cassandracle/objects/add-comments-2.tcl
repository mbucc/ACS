# $Id: add-comments-2.tcl,v 3.0.4.1 2000/04/28 15:09:10 carsten Exp $
# we do not ReturnHeaders as we will either call
# ad_returnredirect or ad_return_complaint, either of which do headers
set_the_usual_form_variables


# verify user input --------------------------------------------------------
set exception_count 0
set exception_text ""
if { ![info exists object_name] || [empty_string_p $object_name] } {
    incr exception_count
    append exception_text "<li>The object_name (format: OWBER.TABLE_NAME) was left blank, but it is required.\n"
}
if { ![info exists table_comment] } {
    incr exception_count
    append exception_text "<li>The table_comment was missing, but it is required (but null is OK).\n"
}

# start processing --------------------------------------------------------

# it is not clear to me whey we have one object_name argument here
# of the format OWBER.TABLE_NAME that needs to be parsed, rather than 
# two seperate arguments?
set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]

# get two db handles
set db [ns_db gethandle]

# table ----------------------------------------------------------------------

# update table comment
set table_sql "
-- update table comment in a redirect page
-- /objects/add-comments-2.tcl
comment on table $owner.$object_name is '$QQtable_comment'
"
ns_db exec $db $table_sql


# columns ---------------------------------------------------------------------

# for columns, we need to 1) know how manty there are, 
# and 2) know their names. This allows us to loop as needed.
set get_column_info_sql "
-- get column name and id in preparation 
-- for comment updates in a redirect page
-- /objects/add-comments-2.tcl
select
     dtc.column_id,
     dtc.column_name
from
     dba_tab_columns dtc
where
     -- specify table to dtc
     dtc.owner='$owner'
and  dtc.table_name='$object_name'
order by 
     dtc.column_id
"

# run query (already have db handle) and output rows
set selection [ns_db select $db $get_column_info_sql]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    # I am using the set command as shown on Welch pp. 12 
    # when passed a single argument, the set command interprets
    # that argument as a variable name, and returns the value
    # of that variable. For example, for the first column,
    # the variable column_id will be equal to '1', so Tcl
    # intyerprets the argument as a (constructed) variable
    # name of QQcolumn_comment_1. This just happens to be one
    # of the form variables passed to this page, and so an
    # sql statement is prepared.
    #
    # I constrcut a Tcl array with one element per row
    # retrieved by the query. After the while loop, I
    # then execute each of these SQL statement array elements.
    set sql_array($column_id) "comment on column $owner.$object_name.$column_name is '[set QQcolumnComment_$column_id]'"
}

foreach index [array names sql_array] {
    ns_db exec $db $sql_array($index)
}


# done, ridirect back to tble page ------------------------------------------------------

# return to main table page
ad_returnredirect "describe-table.tcl?object_name=$owner.$object_name"

