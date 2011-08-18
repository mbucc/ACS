# success.tcl,v 1.1.2.1 2000/02/03 09:49:54 ron Exp
set title "File Uploaded"

ReturnHeaders

ns_write "
[ad_header $title]

<h2> $title </h2>

<hr>

Your file was successfully uploaded. <a href=view.tcl?[export_ns_set_vars url]>View</a> it now.

[ad_footer] "
