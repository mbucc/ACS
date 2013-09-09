# /www/admin/custom-sections/edit-index-page.tcl
ad_page_contract {
    Shows custom section index page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param section_id

    @cvs-id edit-index-page.tcl,v 3.2.2.8 2000/09/22 01:34:40 kevin Exp
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
    set page_exists_p [db_string "cs_select_count_page_exists_p" "
    select count (*) 
 from content_sections 
 where section_id = :section_id 
" ]

    if { !$page_exists_p } {
	incr exception_count
	append exception_text "
	<li>Page does not exits. Only existing pages can be showed.
	"
	
	if { $exception_count > 0 } { 
	    ad_scope_return_complaint $exception_count $exception_text $db
	    return
	}
	
    } 

} else {
    # we got 1 row back, now let's get data from it
}

set page_title "Index Page"

set section_pretty_name [db_string "cs_select_pretty_name" "
    select section_pretty_name 
 from content_sections 
 where section_id = :section_id" ]

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index?[export_url_vars section_id]" $section_pretty_name] $page_title]

<hr>
<br>

<blockquote>

(<a href=edit-index-page-1?[export_url_vars section_id]>edit</a>)
<p>

<b>Page Content</b>
<p>
$body
<p>
Text above is [ad_decode $html_p t HTML "Plain Text"]
<p>

</blockquote>

[ad_scope_admin_footer]
"


doc_return  200 text/html $page_body

