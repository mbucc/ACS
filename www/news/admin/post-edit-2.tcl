# /www/news/admin/post-edit-2.tcl
#

ad_page_contract {
    process the edit form for the news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-edit-2.tcl,v 3.4.2.10 2000/08/16 20:50:33 luke Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    scope:optional
    public:optional
    group_id:integer,optional
    return_url:optional
    name:optional
    news_item_id:integer,notnull
    title:html,notnull
    body:html,notnull
    html_p:notnull
}


# also AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

ad_scope_error_check

set user_id [news_admin_authorize $news_item_id]

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
    ad_scope_return_complaint $exception_count $exception_text
    return
}

set update_sql "update news_items
   set title = :title, 
       body = empty_clob(), 
       html_p = :html_p,
       release_date= :release_date,
       approval_state = 'approved',
       approval_date = sysdate,
       approval_user = :user_id,
       approval_ip_address = '[DoubleApos [ns_conn peeraddr]]',
       expiration_date = :expiration_date
where news_item_id = :news_item_id 
returning body into :1"

if [catch { db_dml news_item_update $update_sql -clobs [list $body] } errmsg] {
    #  update failed
    ns_log Error "/news/admin/post-edit-2 choked:  $errmsg"
    ad_scope_return_error "Insert Failed" "The Database did not like what you typed.
    This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote"
    return
}

db_release_unused_handles
ad_returnredirect item?[export_url_vars news_item_id]
