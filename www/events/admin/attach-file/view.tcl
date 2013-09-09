# view.tcl,v 1.2.2.1 2000/02/03 09:50:00 ron Exp
# View files based on table and ID

ad_page_contract {
    View files based on table and id.

    @param on_which_table the table to which the file is located
    @param on_what_id the table id to which the file is located

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id view.tcl,v 3.5.2.4 2000/09/22 01:37:41 kevin Exp
} {
    {on_which_table:notnull}
    {on_what_id:notnull}
}

set results ""

db_foreach evnt_sel_file "select file_id, file_title 
           from events_file_storage
          where on_which_table=:on_which_table
            and on_what_id=:on_what_id
       order by lower(file_title), creation_date desc" {
    append results "  <li> <a href=download?[export_url_vars file_id]>$file_title</a>\n"
}

db_release_unused_handles

set title "View file"

doc_return  200 text/html "
[ad_header $title]

<h2> $title </h2>

<hr>

<ul>
$results
</ul>

[ad_footer]
"
