# index.tcl,v 1.1.2.1 2000/02/03 09:49:53 ron Exp
# This script allows a user to upload a file with a title
# and attach that file to another table/id in acs

ad_page_contract {
    This script allows a user to upload a file with a title
    and attach that file to another table/id in acs

    @param on_which_table load file to which table
    @param on_what_id load file to what table id
    @param return_url where to return when done

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id index.tcl,v 3.3.6.3 2000/09/22 01:37:41 kevin Exp
} {
    {on_which_table:optional}
    {on_what_id:optional}
    {return_url:optional}
}

set title "Upload a file"

doc_return  200 text/html "
[ad_header $title]

<h2> $title </h2>

<hr>

<form method=POST action=upload>
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

