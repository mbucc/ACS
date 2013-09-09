# /www/admin/custom-sections/delete-file.tcl
ad_page_contract {
    Purpose:  deletes custom section page

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  ahmeds@arsdigita.com
    @creation-date  12/30/99

    @param content_file_id
    @param section_id

    @cvs-id delete-file.tcl,v 3.1.6.8 2000/09/22 01:34:40 kevin Exp
} {
    content_file_id:integer
    section_id:integer
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

set exception_count 0
set exception_text ""

set page_title "Delete Page Confirmation"

set section_pretty_name [db_string custom_sections_select_section_pname "
    select section_pretty_name 
 from content_sections 
 where section_id = :section_id" ]

set page_body "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar [list "index?[export_url_vars section_id]" $section_pretty_name] [list "edit-page?[export_url_vars content_file_id section_id]" "Page Property"] $page_title]

<hr>
<br>

<blockquote>
<h3>Confirm Page Deletion</h3>
<br>

<b>Warning:</b> Are you sure you want to delete this page 

<br><br>Are you sure you want to proceed ?

<form method=get action=\"delete-file-2\">
[export_form_vars  content_file_id section_id]
<input name=confirm_deletion value=yes type=submit>
[ad_space 5]<input name=confirm_deletion value=no type=submit>
</form>

</blockquote>

[ad_scope_admin_footer]
"


doc_return  200 text/html $page_body



