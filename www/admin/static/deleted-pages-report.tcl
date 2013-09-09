# /www/admin/static/deleted-pages-report.tcl

ad_page_contract {

    Helps you clean up the static_pages table when it's full of junk

    @author luke@arsdigita.com
    @creation-date Jul 6 2000

    @cvs-id deleted-pages-report.tcl,v 3.1.2.3 2000/09/22 01:36:08 kevin Exp
} {
}


set page_body "<html>
<head>
<title>Pages at [ns_conn location] that are missing from the filesystem</title>
</head>
<body bgcolor=white text=black>
<h2>Searching for Deleted Pages</h2>

[ad_admin_context_bar [list "index" "Static Content"] "Deleted Page Report"]
<hr>
"


set pages [db_list_of_lists get_pages "select page_id, url_stub from static_pages where obsolete_p != 't'"]

db_release_unused_handles

set pageroot [ns_info pageroot]

append page_body "
These pages were at one time part of the static content of this site, but now
they are no longer present in the filesystem.  If they are obsolete pages and
you want to maintain the comments and links associated with them, you should
mark them as obsolete.  Or if they are just superfluous files that were accidentally 
added by the page crawler, you probably want to try to delete them.

<ul>
"

set missing_count 0

foreach page $pages {
    set page_id [lindex $page 0]
    set url [lindex $page 1]
    set file "${pageroot}$url"
    if { ![file exists $file] } {
	incr missing_count
	append page_body "<li>$url \[<a target=static-admin-window href=delete-page?[export_url_vars page_id]>delete</a> | 
	<a target=static-admin-window href=mark-page-obsolete?[export_url_vars page_id]>mark obsolete</a>\]
	"
    }
}

if { $missing_count == 0 } {
    append page_body "<li><i>Congratulations, none of your static pages are missing from the filesystem</i>"
} 

doc_return 200 text/html "
$page_body
</ul>
[ad_footer]
"

