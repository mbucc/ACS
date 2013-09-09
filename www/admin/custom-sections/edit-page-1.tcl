# /www/admin/custom-sections/edit-page-1.tcl
ad_page_contract {
    Edit custom section page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @param content_file_id Id of the file in CONTENT_FILES being edited.
    @param section_id Content section this file belongs to.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date  12/30/99
    @cvs-id edit-page-1.tcl,v 3.2.2.8 2000/09/22 01:34:40 kevin Exp
} {
    content_file_id:integer,notnull
    section_id:integer,notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set exception_count 0
set exception_text ""

set found_count [db_0or1row "cs_get_found_count" "
select page_pretty_name, body, html_p, file_name 
 from content_files 
 where content_file_id = :content_file_id 
" ]

if { $found_count == 0 } {
    ad_scope_return_complaint 1 "<li>Page does not exits. Only existing pages can be edited."
    return
}

# we got 1 row back, now let's get data from it

if { $html_p=="t" } {
    set html_selected selected
    set plain_text_selected ""
} else {
    set html_selected ""
    set plain_text_selected selected
}

set page_title "Edit"

set section_pretty_name [db_string "cs_select_section_pretty_name" "
    select section_pretty_name 
    from content_sections 
    where section_id = :section_id" ]

db_release_unused_handles

# Build the HTML page
set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_vars section_id]" $section_pretty_name] [list "edit-page.tcl?[export_url_vars content_file_id section_id]" "$file_name Property"] $page_title]

<hr>
<br>

<blockquote>

<form method=post action=\"edit-page-2\">
[export_form_vars section_id content_file_id]

<b>Page Pretty Name</b>
[ad_space 8]
<input type=text 
       name=page_pretty_name 
       value=\"[philg_quote_double_quotes $page_pretty_name]\"
       size=20>
<br><br><br>

<b>Page Content</b>
<br>
<textarea name=body cols=60 rows=16 wrap=soft>
$body
</textarea>
<br><br><br>

Text above is
<select name=html_p>
<option value=f $plain_text_selected>Plain Text
<option value=t $html_selected>HTML
</select>

</blockquote>

<center>
<input type=submit value=\"Update\">
</center>

</form>

[ad_scope_admin_footer ]
"


doc_return  200 text/html $page_body






