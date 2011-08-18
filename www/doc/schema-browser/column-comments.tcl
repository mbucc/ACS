set_the_usual_form_variables

#
# expected: table_name, column_name
#

set error_count 0
set error_message ""

if { ![info exists table_name] || $table_name == "" } {
    incr error_count
    append error_message "<li>variable table_name not found"
}

if { ![info exists column_name] || $column_name == "" } {
    incr error_count
    append error_message "<li>variable column_name not found"
}

if { $error_count > 0 } {
    ad_return_complaint $error_count $error_message
}


set db [ns_db gethandle]


set comments [database_to_tcl_string_or_null $db "
    select comments from user_col_comments where table_name = '[string toupper $table_name]' and column_name = '[string toupper $column_name]'"
]

ns_write "
<h2>ArsDigita Schema Browser</h2>
<hr>
<a href=\"index.tcl?[export_url_vars table_name]\">Tables</a> : Column Comment
<p>
<b>Enter or revise the comment on $table_name.$column_name:</b>
<form method=post action=\"column-comments-2.tcl\">
[export_form_vars table_name column_name]
<textarea name=\"comments\" rows=\"4\" cols=\"40\" wrap=soft>$comments</textarea>
<p>
<input type=submit value=\"Save comment\">
</form>
<hr>
"
