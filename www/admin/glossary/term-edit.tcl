# /www/admin/glossary/term-edit.tcl

ad_page_contract {
    form for editing a term and its definition
    
    @author unknown modified by walter@arsdigita.com, 2000-07-03
    @cvs-id term-edit.tcl,v 3.3.2.7 2000/11/18 06:13:18 walter Exp
    @param term The term we are going to edit.
} {
    {term:notnull,trim}
}
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]


page_validation {
    set sql "select definition, author
    from glossary
    where term = :term"

    if {![db_0or1row getterm $sql]} {
	ad_returnredirect index
	return
    }
} 

db_release_unused_handles

set whole_page "[ad_admin_header "Edit Definition" ]

<h2>Edit Definition</h2>
[ad_admin_context_bar [list "index" "Glossary"] Edit]
<hr>

<form action=term-edit-2 method=post>
Edit the definition for
<p>
<b>$term</b>:<br>
<textarea name=definition cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $definition]</textarea><br>

<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars term]
</form>

[ad_admin_footer]
"
doc_return  200 text/html $whole_page

