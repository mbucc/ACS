# www/admin/spam/show-daily-spam.tcl

ad_page_contract {

   Show scheduled periodic spam configuration. Also shows spam dropzone directory contents.

    @author hqm@arsdigita.com
    @cvs-id show-daily-spam.tcl,v 3.8.2.5 2000/09/22 01:36:06 kevin Exp
} {}



append page_content "[ad_admin_header "List Daily Spam Files"]

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
<a href=/doc/spam>Documentation for the spam system is available here.</a>
<p>

"

set entries ""
set iter 0

db_foreach periodic_spam_messages "select file_prefix,
		    subject,
		    target_user_class_id,
		    user_class_description,
		    from_address,
		    template_p,
		    period,
		    day_of_week,
		    day_of_month,
		    day_of_year
               from daily_spam_files" {

	   append entries "
<table border=1 cellpadding=2>
<tr>
<th align=right>User Class</th><td><select name=user_class_id.$iter>
[db_html_select_value_options -select_option $target_user_class_id \
                               user_class_select_options \
                               "select user_class_id, name from user_classes order by name"]
</select></td>
<tr><th align=right>Subject </th>
<td><input name=subject.$iter type=text value=\"[ns_quotehtml $subject]\" size=40></td></tr>
<tr><th align=right>Filename </th>
<td><input name=file_prefix.$iter type=text size=24 value=\"[ns_quotehtml $file_prefix]\"></td></tr>
<tr><th align=right>From Address </th>
<td><input name=from_address.$iter type=text size=24 value=\"[ns_quotehtml $from_address]\"></td></tr>
"

  if {! [info exists period.$iter] || [empty_string_p [set period.$iter]] } {
      set period.$iter "weekly"
  }

  append entries "<tr><th align=right>Period </th>
<td><select name=period.$iter>
  [ad_generic_optionlist {Daily Weekly Monthly Yearly} {daily weekly monthly yearly} $period]
  </select>

Day of week <select name=day_of_week.$iter><option value=\"\"></option>[html_select_value_options {{1 Monday} {2 Tuesday} {3 Wednesday} {4 Thursday} {5 Friday} {6 Saturday} {7 Sunday}} $day_of_week 0 1] </select>

Day of month <select name=day_of_month.$iter><option value=\"\"></option>[ad_integer_optionlist 1 31 $day_of_month]</select>

</td></tr>"

  append entries "<tr><th align=right>Template?</th><td>"
  if {[string match $template_p "t"]} {
      append entries "<input type=checkbox name=template_p.$iter value=t checked>"
  } else {
      append entries "<input type=checkbox name=template_p.$iter value=t>"
  }
  append entries "</td></tr></table>"

  append entries "
  <p>
  "

  incr iter
}

append page_content "
<form action=modify-daily-spam method=post>

"

if {![empty_string_p $entries]} {
    append page_content "<h3>Periodic Email (Spam) Entries</h3><br>
    $entries
    <p>
    <input type=submit value=\"Modify Spam Entries\">"
}

append page_content "
<p>
<h3>Add New Periodic Email Entry</h3>
<table border=1 cellpadding=2>
<tr><th align=right>User Class</th><td>
<select name=user_class_id.$iter>
[db_html_select_value_options user_class_select_options "select user_class_id, name from user_classes order by name"]
</select></td></tr>
<tr><th align=right>Subject</th><td> <input name=subject.$iter type=text size=40></td></tr>
<tr><th align=right>Filename</th><td><input name=file_prefix.$iter type=text size=24></td></tr>
<tr><th align=right>From Address</th><td><input name=from_address.$iter type=text size=24></td></tr>
<tr><th align=right>Period</th><td><select name=period.$iter>
[ad_generic_optionlist {Daily Weekly Monthly Yearly} {daily weekly monthly yearly} ""]
</select>

Day of week <select name=day_of_week.$iter><option value=\"\"></option>[html_select_value_options {{1 Monday} {2 Tuesday} {3 Wednesday} {4 Thursday} {5 Friday} {6 Saturday} {7 Sunday}} "" 0 1] </select>

Day of month <select name=day_of_month.$iter><option value=\"\"></option>[ad_integer_optionlist 1 31]</select>

</td></tr>
<tr><th align=right>Template?</th><td><input type=checkbox name=template_p.$iter value=t></td></tr>
</table>

<p>
<input type=submit value=\"Add New Entry\">

</form>
"

append page_content "<h3>Contents of the dropzone directory <i>[spam_file_location ""]</i></h3>"

set file_items ""
# list the contents of the dropzone directory 
# it would be nice to sort on the reverse of the filenames
set files [lsort -ascii [glob -nocomplain [spam_file_location "*"]]]
foreach path $files {
    set file [file tail $path]
    append file_items "<tr><td align=left><tt><a href=view-spam-file?filename=[ns_urlencode $file]>$file</a></tt></td><td width=20></td><td><a href=delete-spam-file?filename=[ns_urlencode $file]><tt>delete</tt></a></td></tr>"
}

if {[empty_string_p $file_items]} {
    append page_content "<i>no files in drop zone</i><br>"
} else {
    append page_content "<table>$file_items</table>"
}

append page_content "
<p>
[ad_admin_footer]"


doc_return  200 text/html $page_content

