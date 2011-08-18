# $Id: philg-tree.tcl,v 3.0 2000/02/06 03:30:25 ron Exp $
set db [ns_db gethandle]

set selection [ns_db select $db "select page_id, url_stub, page_title, accept_comments_p, accept_links_p from static_pages order by url_stub"]

ReturnHeaders

set count 0
set whole_page ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr count
    if { [expr $count%100] == 0 } {
	append whole_page "$url_stub<br>"
    }
}

ns_write $whole_page

