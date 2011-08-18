# $Id: audit-table.tcl,v 3.0 2000/02/06 03:16:47 ron Exp $
# Jesse 7/18
# Returns the audit trails of a table and its audit table for entry that
# exists between the start date and end date.

set_form_variables
# expects table_names_and_id_column start_date end_date
# start_date can be blank

set main_table_name [lindex $table_names_and_id_column 0]
set audit_table_name [lindex $table_names_and_id_column 1]
set id_column [lindex $table_names_and_id_column 2]

set form [ns_getform]

# ns_dbformvalue $form start_date date start_date will give an error
# message if the day of the month is 08 or 09 (this octal number problem
# we've had in other places).  So I'll have to trim the leading zeros
# from ColValue.start%5fdate.day and stick the new value into the $form
# ns_set.
    
set "ColValue.start%5fdate.day" [string trimleft [set ColValue.start%5fdate.day] "0"]
ns_set update $form "ColValue.start%5fdate.day" [set ColValue.start%5fdate.day]


set "ColValue.end%5fdate.day" [string trimleft [set ColValue.end%5fdate.day] "0"]
ns_set update $form "ColValue.end%5fdate.day" [set ColValue.end%5fdate.day]

set exception_count 0
set exception_text ""

# check that either all elements are blank 
# date and time value is formated correctly for ns_dbformvalue
if { [empty_string_p [set ColValue.start%5fdate.day]] && 
     [empty_string_p [set ColValue.start%5fdate.year]] && 
     [empty_string_p [set ColValue.start%5fdate.month]] && 
     [empty_string_p [set ColValue.start%5fdate.time]] } {
    # Blank date means that all the table history should be displayed
    set start_date ""
} elseif { [catch  { ns_dbformvalue $form start_date datetime start_date} errmsg ] } {
    incr exception_count
    append exception_text "<li>The date or time was specified in the wrong format.  The date should be in the format Month DD YYYY.  The time should be in the format HH:MI:SS (seconds are optional), where HH is 01-12, MI is 00-59 and SS is 00-59.\n"
} elseif { ![empty_string_p [set ColValue.start%5fdate.year]] && [string length [set ColValue.start%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
}

if [catch  { ns_dbformvalue $form end_date datetime end_date} errmsg ] {
    incr exception_count
    append exception_text "<li>The date or time was specified in the wrong format.  The date should be in the format Month DD YYYY.  The time should be in the format HH:MI:SS (seconds are optional), where HH is 01-12, MI is 00-59 and SS is 00-59.\n"
} elseif { ![empty_string_p [set ColValue.end%5fdate.year]] && [string length [set ColValue.end%5fdate.year]] != 4 } {
    incr exception_count
    append exception_text "<li>The year needs to contain 4 digits.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

ReturnHeaders
ns_write "
[ad_admin_header "[ec_system_name] Audit Table"]

<h2>[ec_system_name] Audit for $main_table_name</h2>

[ad_admin_context_bar [list "index.tcl" Ecommerce] [list "audit-tables.tcl" "Audit Table"] "Audit $main_table_name"]

<hr>

<form method=post action=\"audit-table.tcl\">
[export_form_vars table_names_and_id_column]
<table>
<tr>
  <td>From:</td>
  <td>[ad_dateentrywidget start_date [lindex [split $start_date " "] 0]][ec_timeentrywidget start_date $start_date]</td>
</tr>
<tr>
  <td>To:</td>
  <td>[ad_dateentrywidget end_date [lindex [split $end_date " "] 0]][ec_timeentrywidget end_date $end_date]</td>
</tr>
<tr>
<td></td>
<td><input type=submit value=\"Alter Date Range\"></td>
</tr>
</table>
</form>

<h3>$main_table_name</h3>
"

ns_write "
    <blockquote>
[ad_audit_trail_for_table $db $main_table_name $audit_table_name $id_column $start_date $end_date "audit-one-id.tcl" ""]
    </blockquote>

[ad_admin_footer]
"