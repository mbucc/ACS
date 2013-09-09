# /www/glossary/term-edit.tcl

ad_page_contract {
    form for editing a term and its definition

    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id term-edit.tcl,v 3.3.2.7 2000/11/18 07:01:12 walter Exp
    @param term The term to edit
} {term}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]

set admin_only_p 0

page_validation {
    if { ![string equal -nocase "open" [ad_parameter ApprovalPolicy glossary]] } {
	if {![ad_administrator_p]} {
	    error "<li>Only the administrator may edit terms."
	}
    }
} {
    set sql "select author, definition
    from glossary
    where term = :term"

    if {![db_0or1row getterm $sql]} {
	error "<li>Term no longer exists.\n"
    }

    # check to see if ther user was the original author
    if {$user_id != $author } {
	if {![ad_administrator_p]} {
		error "<li>You can not edit this term because you did not author it.\n" 
	}
    }
}

db_release_unused_handles

set whole_page "[ad_header "Edit Definition" ]

<h2>Edit Definition</h2>
[ad_context_bar_ws_or_index [list "index" "Glossary"] Edit]
<hr>

<form action=term-edit-2 method=post>
Edit your definition for
<p>
<b>$term</b>:<br>
<textarea name=definition cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $definition]</textarea><br>

<p>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars term]
</form>

[ad_footer]
"

doc_return  200 text/html $whole_page
