# /www/portrait/erase.tcl

ad_page_contract {
    @cvs-id erase.tcl,v 3.1.6.4 2000/09/22 01:39:12 kevin Exp
}

doc_return  200 text/html "
[ad_header "Erase Portrait"]

<h2>Erase Portrait</h2>

[ad_context_bar_ws [list "index" "Your Portrait"] "Erase"]

<hr>

Are you sure that you want to erase your portrait?

<center>
<form method=GET action=erase-2>
<input type=submit name=\"operation\" value=\"Yes, I'm sure\">
 &nbsp;
<input type=submit name=\"operation\" value=\"No, I want to cancel\">
</form>
</center>

[ad_footer]
"
