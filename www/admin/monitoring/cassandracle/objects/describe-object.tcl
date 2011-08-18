# $Id: describe-object.tcl,v 3.0 2000/02/06 03:25:22 ron Exp $
set_form_variables
set page_name "Description of $object_name"
set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]
ReturnHeaders
set db [cassandracle_gethandle]

set description_info [database_to_tcl_list_list_and_column_names $db "select column_name as 'Column Name', data_type || '(' || data_length || ') ' || DECODE(nullable, 'Y', '', 'N', 'NOT NULL', '?') as 'Data Type' from dba_tab_columns where owner='$owner' and table_name='$object_name'"]

set description_data [lindex $description_info 0]
set description_columns [lindex $description_info 1]
set column_html ""
foreach column_heading $description_columns {
    append column_html "<td>$column_heading</td>"
}

ns_write "
[ad_admin_header $page_name]
<table>
<tr>$column_html</tr>
"
if {[llength $description_data]==0} {
    ns_write "<tr><td>No data found</td></tr>"
} else {
    set column_data_html ""
    for {set i 0} {$i<[llength $desciption_columns]} {incr i} {
	append column_data_html "<td>\[lindex \$row $i\]</td>"
    }
    foreach row $description_data {
	ns_write "<tr>[subst $column_data_html]</tr>\n"
    }
}
ns_write "</table>\n
<p>
Here is the SQL responsible for this information: <p>
<kbd>describe $object_name</kbd>

[ad_admin_footer]
"
