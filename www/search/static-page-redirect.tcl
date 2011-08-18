# $Id: static-page-redirect.tcl,v 3.0.4.1 2000/04/28 15:11:27 carsten Exp $
ad_page_variables {page_id}

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select url_stub from static_pages where page_id = $page_id"]

if { $selection == "" } {
    ad_return_error "Invalid page id given"
    return
}

set_variables_after_query

ad_returnredirect $url_stub

