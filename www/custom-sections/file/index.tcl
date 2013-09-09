# /www/custom-sections/file/index.tcl
ad_page_contract {
    Purpose:  Serves the custom section index page (for loading download a file) 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @param content_file_id

    @author Contact:  ahmeds@arsdigita.com
    @creation-date    12/28/99

    @cvs-id index.tcl,v 3.1.2.6 2000/09/22 01:37:19 kevin Exp
} {
    content_file_id:integer
}

ad_scope_error_check
ad_scope_authorize $scope all all none

db_1row cs_select_page_info "
select page_pretty_name, body, html_p 
 from content_files 
 where content_file_id = :content_file_id 
" 


append html "
[ad_scope_header $page_pretty_name]
[ad_scope_page_title $page_pretty_name]
[ad_scope_context_bar_ws "$page_pretty_name"]
<hr>
[ad_scope_navbar]
"   
append html "
<br><br>
<blockquote>
<h2>$page_pretty_name</h2>
[util_maybe_convert_to_html $body $html_p]
</blockquote>
<p>
"



doc_return  200 text/html "
$html
[ad_scope_footer ]
"

