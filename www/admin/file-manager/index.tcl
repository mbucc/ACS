# /www/admin/file-manager/index.tcl

ad_page_contract {

    index page for file manager

    @author  Ron Henderson (ron@arsdigita.com)
    @created Tue May 30 22:15:57 2000
    @cvs-id  index.tcl,v 1.2.2.4 2000/09/22 01:35:12 kevin Exp
} {
}

if {[ad_parameter EnabledP file-manager 0] != 0} {
    doc_return  200 text/html "
    <html>
    <head>
    <title>File Manager</title>
    </head>
    <frameset cols=\"20%,*\">
    <frame name=tree src=file-tree>
    <frame name=list src=file-list>
    </frameset>
    </html>
    "
} else {
    set page_title "File Manager"
    doc_return 200 text/html "
    [ad_header $page_title]
    <h2>$page_title</h2>
    [ad_admin_context_bar]
    <hr>
    <p>File Manager is currently disabled.</p>
    [ad_admin_footer]
    "
}
