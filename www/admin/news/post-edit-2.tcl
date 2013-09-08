# /www/admin/news/post-edit-2.tcl
#

ad_page_contract {
    process the edit form for the news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-edit-2.tcl,v 3.5.2.6 2000/07/24 20:37:34 luke Exp
} {
    return_url:optional
    name:optional
    news_item_id:integer,notnull
    title:html,optional
    body:html,optional
    html_p:notnull
}


# also AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

set exception_count 0
set exception_text ""


if [catch  {
    ns_dbformvalue [ns_conn form] release_date date release_date
    ns_dbformvalue [ns_conn form] expiration_date date expiration_date} errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {

    set expire_laterthan_future_p [db_string news_expire_get "select to_date(:expiration_date, 'yyyy-mm-dd') - to_date(:release_date, 'yyyy-mm-dd') from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the expiration date is later than the release date."
    }
}

# now release_date and expiration_date are set

if { ![info exists title] || [empty_string_p $title] } {
    incr exception_count
    append exception_text "<li>Please enter a title."
}

if { ![info exists body] || [empty_string_p $body] } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

if [catch { db_dml news_item_update "update news_items
set title = :title, body=empty_clob(),
html_p = :html_p, release_date = :release_date,
expiration_date = :expiration_date
where news_item_id = :news_item_id
returning body into :1" -clobs [list $body] } errmsg] {
    #  update failed
    ns_log Error "/admin/news/post-edit-2 choked:  $errmsg"
    ad_return_error "Insert Failed" "The Database did not like what you typed.
    This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

ad_returnredirect item?[export_url_vars news_item_id]
