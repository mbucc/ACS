# /www/admin/custom-sections/edit-index-page-1.tcl
ad_page_contract {
    Purpose:  edits custom section index page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date 12/30/99

    @param section_id

    @cvs-id edit-index-page-1.tcl,v 3.2.2.9 2000/09/22 01:34:40 kevin Exp
} {
    section_id:integer,notnull
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set exception_count 0
set exception_text ""

set return_count [db_0or1row "cs_select_body_html_p" "
select body, html_p 
 from content_sections 
 where section_id = :section_id 
" ]

if { $return_count == 0 } {
    set page_exists_p [db_string "select_page_exists_p" {
	select count (*) 
	from content_sections 
	where section_id = :section_id 
    } ]

    if { !$page_exists_p } {
	incr exception_count
	append exception_text "
	<li>Page does not exits. Only existing pages can be edited.
	"
	
	if { $exception_count > 0 } { 
	    ad_scope_return_complaint $exception_count $exception_text $db
	    return
	}
	
    } 

} else {
    # we got 1 row back, now let's get data from it
}

if { $html_p=="t" } {
    set html_selected selected
    set plain_text_selected ""
} else {
    set html_selected ""
    set plain_text_selected selected
}

set page_title "Edit Section Index Page"

set section_pretty_name [db_string "select_section_pretty_name" {
    select section_pretty_name 
    from content_sections 
    where section_id = :section_id }]

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_vars section_id]" $section_pretty_name] [list "edit-index-page.tcl?[export_url_vars section_id]" "Index Page Property"] Edit]

<hr>
<br>

<blockquote>
<h3>Edit index.html</h3>
<br>

<form method=post action=\"edit-index-page-2\">
[export_form_vars section_id]

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

[ad_scope_admin_footer]
"


doc_return  200 text/html $page_body



