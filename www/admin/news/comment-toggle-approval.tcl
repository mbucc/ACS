# /www/admin/news/comment-toggle-approval.tcl
#

ad_page_contract {
    news item comment approval page for site-wide admin

    @author ashah@arsdigita.com
    @creation-date May 30, 2000
    @cvs-id comment-toggle-approval.tcl,v 3.1.2.5 2000/07/21 03:57:45 ron Exp
} {
    news_item_id:integer,notnull
    comment_id:integer,notnull
}


# no security check because we are under /admin

db_dml news_gc_update "update general_comments set approved_p = logical_negation(approved_p) where comment_id = :comment_id"

ad_returnredirect "item?[export_url_vars news_item_id]"
