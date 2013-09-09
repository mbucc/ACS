# /admin/links/links-all.tcl

ad_page_contract {
    List all related links

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id links-all.tcl,v 3.2.2.7 2000/09/22 01:35:30 kevin Exp
} {
}

set page_content "[ad_admin_header "All related links"]

<h2>All related links</h2>

in <a href=/admin/index>[ad_system_name]</a>

<hr>
 
Listing of all related links.

<ul>
"

set link_qry "select links.link_title, links.link_description, links.url, links.status,  to_char(posting_time,'Month dd, yyyy') as posted,
users.user_id, first_names || ' ' || last_name as name, links.page_id as page_id
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id
order by posting_time asc"

db_foreach select_related_links $link_qry {    
    append page_content "<li>$posted: <a href=\"$url\">$link_title</a> - $link_description (<font color=red>[string trim $status]</font>) posted by <a href=\"users/one?user_id=$user_id\">$name</a>   &nbsp; &nbsp; <a href=\"edit?[export_url_vars page_id url]\">edit</a> &nbsp; &nbsp;  <a href=\"delete?[export_url_vars page_id url]\">delete</a>"

}

db_release_unused_handles
 
append page_content "
</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
