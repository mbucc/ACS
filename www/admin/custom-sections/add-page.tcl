# /www/admin/custom-sections/add-page.tcl
ad_page_contract {
    Add a page to a custom section.
    
    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date 12/30/99

    @param section_id

    @cvs-id add-page.tcl,v 3.2.2.8 2001/01/10 17:11:13 khy Exp
} {
    section_id:integer
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set exception_count 0
set exception_text ""

set page_title "Add Page"
set section_pretty_name [db_string "select_pretty_name" "
    select section_pretty_name 
 from content_sections 
 where section_id = :section_id" ]

set content_file_id [db_string "cs_get_content_file_id" "select content_file_id_sequence.nextval from dual"]

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>

<blockquote>
<h3>Add Page</h3>
<br>

<form method=post action=\"add-page-2\">

[export_form_vars section_id]
[export_form_vars -sign content_file_id]

<b>File Name</b>
[ad_space 8]
<input type=text name=file_name size=20>
<br><br><br>

<b>Page Pretty Name</b>
[ad_space 8]
<input type=text name=page_pretty_name size=20>
<br><br><br>

<b>Page Content</b>
<br>
<textarea name=body cols=60 rows=16 wrap=soft></textarea>
<br><br><br>

Text above is
<select name=html_p>
<option value=f selected>Plain Text
<option value=t>HTML
</select>

<center>
<input type=submit value=\"Add\">
</center>

</form>
</blockquote>

[ad_scope_admin_footer]
"



doc_return  200 text/html $page_body



