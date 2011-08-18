# $Id: clear.tcl,v 3.0 2000/02/06 03:21:24 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Clear Sales Tax Settings"]

<h2>Clear Sales Tax Settings</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Sales Tax"] "Clear Settings"]

<hr>

Please confirm that you wish to clear all your sales tax settings.

<form method=post action=clear-2.tcl>
<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"