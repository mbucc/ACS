# $Id: erase.tcl,v 3.0 2000/02/06 03:53:45 ron Exp $
ns_return 200 text/html "[ad_header "Erase Portrait"]

<h2>Erase Portrait</h2>

[ad_context_bar_ws [list "index.tcl" "Your Portrait"] "Erase"]

<hr>

Are you sure that you want to erase your portrait?

<center>
<form method=GET action=\"erase-2.tcl\">
<input type=submit value=\"Yes, I'm sure\">
</center>

[ad_footer]
"
