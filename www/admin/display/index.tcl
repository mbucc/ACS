# /www/admin/display/index.tcl

ad_page_contract {
    Display settings administration page.
    @param Note: if this page is accessed through /groups/admin pages then
    group_id, group_name, short_name and admin_email are already
    set up in the environment by the ug_serve_section.

    @author tarik@arsdigita.com
    @creation-date 12/27/1999

    @cvs-id index.tcl,v 3.2.2.7 2000/09/22 01:34:42 kevin Exp
} {
    return_url:optional
    scope:optional
    group_id:optional,integer
    user_id:optional,integer
}

ad_scope_error_check

append html "

<a href=\"edit-simple-css?[export_url_scope_vars return_url]\">
Cascaded Style Sheet Settings</a><br>

<a href=\"upload-logo?[export_url_scope_vars return_url]\">
Logo Settings</a>
"

set page_title "Display Settings"

doc_return  200 text/html "
[ad_scope_admin_header $page_title]
[ad_scope_admin_page_title $page_title]
[ad_scope_admin_context_bar "Display Settings"]

<hr>
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer]
"




