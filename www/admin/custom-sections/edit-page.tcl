# /www/admin/custom-sections/edit-page.tcl
ad_page_contract {
    Summarizes custom section page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date 12/30/99
    @cvs-id edit-page.tcl,v 3.2.2.7 2000/09/22 01:34:40 kevin Exp

    @param content_file_id
    @param section_id
} {
    content_file_id:integer,notnull
    section_id:integer
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set return_count [db_0or1row "cs_select_page_pretty_name" "
select page_pretty_name, body, html_p, file_name
 from content_files 
 where content_file_id = :content_file_id 
" ]

if { $return_count == 0 } {
    ad_scope_return_complaint 1 "<li>Page does not exits. Only existing pages can be edited."
    return
}
 
# we got 1 row back, now let's get data from it

set page_title "$file_name"

set section_pretty_name [db_string "cs_select_pretty_name" "
    select section_pretty_name 
 from content_sections 
 where section_id = :section_id" ]

db_release_unused_handles

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index.tcl?[export_url_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>

<blockquote>

(<a href=edit-page-1?[export_url_vars content_file_id section_id]>edit</a> |
<a href=delete-file?[export_url_vars content_file_id section_id]>delete</a>)

<p>
<b>Page Pretty Name</b>
[ad_space 3] $page_pretty_name
<p>

<b>Page Content</b>
<p>
$body
<p>

<b>Text Type</b>[ad_space 3] [ad_decode $html_p t HTML  "Plain Text"]

</blockquote>

[ad_scope_admin_footer ]
"

doc_return  200 text/html $page_body

