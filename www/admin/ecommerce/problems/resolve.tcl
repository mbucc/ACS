# $Id: resolve.tcl,v 3.0 2000/02/06 03:19:41 ron Exp $
#
# jkoontz@arsdigita.com July 21, 1999
# modified by eveander@arsdigita.com July 23, 1999
#
# This page confirms that a problems in the problem log is resolved

set_form_variables
# problem_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from ec_problems_log where problem_id = $problem_id"]
set_variables_after_query

ns_return 200 text/html "[ad_admin_header "Confirm the Problem is Resolved"]

<h2>Confirm that Problem is Resolved</h2>

[ad_admin_context_bar [list "/admin/ecommerce/" Ecommerce] [list "index.tcl" "Potential Problems"] "Confirm Resolve Problem"]

<hr>

<form method=post action=\"resolve-2.tcl\">
[export_form_vars problem_id]
<blockquote>

<p>
<blockquote>
[util_AnsiDatetoPrettyDate $problem_date]
<p>
$problem_details
</blockquote>
<center>
<input type=submit value=\"Yes, it is resolved\">
</center>

</blockquote>
</form>

[ad_admin_footer]
"
