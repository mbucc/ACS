# $Id: index.tcl,v 3.0 2000/02/06 03:18:42 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Mailing Lists"]

<h2>Mailing Lists</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Mailing Lists"]

<hr>

<h3>Mailing Lists with Users</h3>
"

set db [ns_db gethandle]

ns_write "[ec_mailing_list_widget $db "f"]

<h3>All Mailing Lists</h3>

<blockquote>
<form method=post action=one.tcl>

[ec_category_widget $db]
<input type=submit value=\"Go\">
</form>

</blockquote>

[ad_admin_footer]
"
