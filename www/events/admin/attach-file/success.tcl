# success.tcl,v 1.1.2.1 2000/02/03 09:49:54 ron Exp

ad_page_contract {
    Displays confirmation message for successful file upload.

    @param on_which_table the table to which the file was uploaded
    @param on_what_id the table id to which the file was uploaded

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id success.tcl,v 3.3.6.3 2000/09/22 01:37:41 kevin Exp
} {
    {on_which_table:notnull}
    {on_what_id:notnull}
}

set title "File Uploaded"

doc_return  200 text/html "
[ad_header $title]

<h2> $title </h2>

<hr>

Your file was successfully uploaded. <a href=view?[export_url_vars on_which_table on_what_id]>View</a> it now.

[ad_footer] "
