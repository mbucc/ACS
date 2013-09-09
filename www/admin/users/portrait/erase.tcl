ad_page_contract {
    ask user whether they're sure they want to erase their portrait

    @cvs-id erase.tcl,v 1.1.2.4 2000/09/22 01:36:30 kevin Exp
    @param user_id
} {
    user_id:naturalnum,notnull
}

doc_return 200 text/html "[ad_header "Erase Portrait"]

<h2>Erase Portrait</h2>

[ad_context_bar_ws [list "index.tcl" "Your Portrait"] "Erase"]

<hr>

Are you sure that you want to erase your portrait?

<center>
<form method=GET action=\"erase-2\">
[export_form_vars user_id]
<input type=submit value=\"Yes, I'm sure\">
</form>
</center>

[ad_footer]
"
