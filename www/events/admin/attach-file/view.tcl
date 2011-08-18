# view.tcl,v 1.2.2.1 2000/02/03 09:50:00 ron Exp
# View a file based on table and ID

set_the_usual_form_variables 0
# on_which_table on_what_id

if { ![exists_and_not_null on_which_table] || \
	![exists_and_not_null on_what_id] } {
    ad_return_error "Missing Information" "You must specify both the table and id for which to display files"
    return
}




set db [ns_db gethandle]
set selection [ns_db select $db \
	"select file_id, file_title 
           from events_file_storage
          where on_which_table='$QQon_which_table'
            and on_what_id='$QQon_what_id'
       order by lower(file_title), creation_date desc"]

set results ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "  <li> <a href=download.tcl?[export_url_vars file_id]>$file_title</a>\n"
}

ns_db releasehandle $db


set title "View file"

ReturnHeaders

ns_write "
[ad_header $title]

<h2> $title </h2>

<hr>

<ul>
$results
</ul>

[ad_footer]
"
