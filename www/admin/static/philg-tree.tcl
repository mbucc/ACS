# /www/admin/static/philg-tree.tcl

ad_page_contract {
    Prints out every 100th url stub

    @author philg@mit.edu
    @creation-date Jul 8 2000

    @cvs-id philg-tree.tcl,v 3.0.12.4 2000/09/22 01:36:09 kevin Exp
} {

}

set sql_query "select page_id, url_stub, page_title, accept_comments_p, accept_links_p from static_pages order by url_stub"

set count 0
set whole_page ""
db_foreach url_stub_loop $sql_query {
    incr count
    if { [expr $count%100] == 0 } {
	append whole_page "$url_stub<br>"
    }
}

doc_return  200 text/html $whole_page
