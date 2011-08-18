# $Id: show-daily-spam.tcl,v 3.4 2000/03/08 07:38:40 hqm Exp $
# show-daily-spam.tcl
#
# hqm@arsdigita.com
#
# Show list of daily spam file locations

ReturnHeaders

append pagebody "[ad_admin_header "List Daily Spam Files"]

<h2>Daily Spam File Locations</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "List Daily Spam Files"]

<hr>
<p>
Spam files to look for in drop-zone directory \"[spam_file_location ""]\".
<p>
To delete an entry, just enter an empty string for the filename and subject, and press the Modify button.
<p>
'From address' is optional; if left blank, the default spam system from-address will be used.

<p>
<a href=/doc/spam.html>Documentation for the spam system is available here.</a>
<p>

"

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]

set entries_header "
<tr><th>User Class</th>
<th>Subject</th>
<th>Filename</th>
<th>From address</th>
<th>Frequency</th>
<th>Template?</th>
</tr>

"
 
set entries ""

set selection [ns_db select $db "select * from daily_spam_files"]

set iter 0

while { [ns_db getrow $db $selection] } { 
    set_variables_after_query
    append entries "
<tr><td><select name=user_class_id_$iter>
[db_html_select_value_options $db_sub "select user_class_id, name from user_classes order by name" $target_user_class_id]
</select></td>
<td><input name=subject_$iter type=text value=\"[philg_quote_double_quotes $subject]\" size=40></td>
<td><input name=file_prefix_$iter type=text size=24 value=\"[philg_quote_double_quotes $file_prefix]\"></td>
<td><input name=from_address_$iter type=text size=24 value=\"[philg_quote_double_quotes $from_address]\"></td>
"


if {! [info exists frequency_$iter] } {
    set frequency_$iter "weekly"
}

append entries "<td><select name=frequency_$iter>
[ad_generic_optionlist {Daily Weekly Monthly Yearly} {daily weekly monthly yearly} frequency_$iter]
</select></td>"


append entries "<td>"
if {[string match $template_p "t"]} {
    append entries "<input type=checkbox name=template_p_$iter value=t checked>"
} else {
    append entries "<input type=checkbox name=template_p_$iter value=t>"
}
append entries "</td>"


append entries "
</tr>
"
    incr iter
}

append pagebody "
<form action=modify-daily-spam.tcl method=post>
<table>"

if {![empty_string_p $entries]} {
    append pagebody "$entries_header
    $entries"
}

append pagebody "
<tr><td colspan=3>Add new daily spam</tr>
$entries_header
<tr><td>
<select name=user_class_id_$iter>
[db_html_select_value_options $db_sub "select user_class_id, name from user_classes order by name"]
</select>
<td> <input name=subject_$iter type=text size=40></td>
<td><input name=file_prefix_$iter type=text size=24></td>
<td><input name=from_address_$iter type=text size=24></td>
<td><select name=frequency_$iter>
[ad_generic_optionlist {Daily Weekly Monthly Yearly} {daily weekly monthly yearly} ""]
</select>
</td>
<td><input type=checkbox name=template_p_$iter value=t></td>
</tr>
</table>

<input type=submit value=\"Modify Spam Entries\">
</form>
"

append pagebody "<h3>Contents of the dropzone directory <i>[spam_file_location ""]</i></h3>"

set file_items ""
# list the contents of the dropzone directory 
# it would be nice to sort on the reverse of the filenames
set files [lsort -ascii [glob -nocomplain [spam_file_location "*"]]]
foreach path $files {
    set file [file tail $path]
    append file_items "<tr><td align=left><tt><a href=view-spam-file.tcl?filename=[ns_urlencode $file]>$file</a></tt></td><td width=20></td><td><a href=delete-spam-file.tcl?filename=[ns_urlencode $file]><tt>delete</tt></a></td></tr>"
}

if {[empty_string_p $file_items]} {
    append pagebody "<i>no files in drop zone</i><br>"
} else {
    append pagebody "<table>$file_items</table>"
}



append pagebody "
<p>
[ad_admin_footer]"

ns_write $pagebody
