# $Id: term-edit.tcl,v 3.0.4.1 2000/04/28 15:09:07 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode [ns_conn url]]?term=$term 
}

set exception_count 0
set exception_text ""

set_the_usual_form_variables
# term

set db [ns_db gethandle]

if { ![info exists term] || [empty_string_p $QQterm] } {
    incr exception_count
    append exception_text "<li>No term to edit\n"
} else {
    set selection [ns_db 0or1row $db "select definition, author
    from glossary
    where term = '$QQterm'"]

    # In case of someone clicking on an old window
    if [empty_string_p $selection] {
	ns_db releasehandle $db
	ad_returnredirect index.tcl
	return
    }

    set_variables_after_query
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders

ns_write "[ad_admin_header "Edit Definition" ]

<h2>Edit Definition</h2>
[ad_admin_context_bar [list "index.tcl" "Glossary"] Edit]
<hr>

<form action=term-edit-2.tcl method=post>
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

[ad_admin_footer]
"
