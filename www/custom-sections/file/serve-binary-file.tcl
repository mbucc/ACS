# /www/custom-sections/file/serve-binary-file.tcl
ad_page_contract {
    Purpose:  this serves a custom section image 

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date    12/28/99

    @param content_file_id

    @cvs-id serve-binary-file.tcl,v 3.1.2.7 2000/09/22 01:37:20 kevin Exp
} {
    content_file_id:integer
}

ad_scope_error_check
ad_scope_authorize $scope all all none

set page_title "View Image"

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_page_title $page_title]
[ad_scope_context_bar_ws "$page_title"]

<hr>
[ad_scope_navbar]
"

set file_name [db_string cs_select_file_name "
select file_name 
 from content_files 
 where content_file_id = :content_file_id"]

append html "

<center>
<h3>$file_name</h3>
<img src=\"/custom-sections/file/get-binary-file.tcl?[export_url_vars content_file_id]\" ALT=$file_name border=1>
</center>
"

db_release_unused_handles

append page_body "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"

doc_return  200 text/html $page_body

