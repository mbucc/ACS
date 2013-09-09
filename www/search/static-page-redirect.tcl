# /www/search/static-page-redirect.tcl
ad_page_contract {
    @cvs-id static-page-redirect.tcl,v 3.2.2.4 2000/07/21 04:04:03 ron Exp
} {
page_id:naturalnum,notnull
}

db_0or1row url_stub_select "select url_stub from static_pages where page_id = :page_id"

db_release_unused_handles
if { [empty_string_p url_stub] } {
    ad_return_error "Bad ID" "Invalid page id given"
    return
}

ad_returnredirect $url_stub

