# index.tcl,v 1.1.2.1 2000/02/03 09:49:53 ron Exp
# This script allows a user to upload a file with a title
# and attach that file to another table/id in acs

set_form_variables 0
# on_which_table on_what_id return_url

set title "Upload a file"

ReturnHeaders

ns_write "
[ad_header $title]

<h2> $title </h2>

<hr>

<form method=POST action=upload.tcl>
[export_form_vars return_url]
1. Attach File to what table?
  <br><dd><input type=text size=30 name=on_which_table [export_form_value on_which_table]>

<p>
2. Attach File to what ID?
  <br><dd><input type=text size=30 name=on_what_id [export_form_value on_what_id]>

<p>
<input type=submit>
</form>

[ad_footer]
"

