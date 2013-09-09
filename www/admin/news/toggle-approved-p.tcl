# /www/admin/news/toggle-approved-p.tcl
#

ad_page_contract {
    toggles approval status for one news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id toggle-approved-p.tcl,v 3.4.2.5 2000/07/21 03:57:46 ron Exp
} {
    return_url:optional
    name:optional
    news_item_id:integer,notnull
}


set user_id [ad_get_user_id]

db_dml news_item_update "update news_items set approval_state = decode(approval_state, 'approved', 'disapproved', 'approved'), approval_user = :user_id, approval_date = sysdate, approval_ip_address = '[DoubleApos [ns_conn peeraddr]]' where news_item_id = :news_item_id"

ad_returnredirect "item?[export_url_vars news_item_id]"

