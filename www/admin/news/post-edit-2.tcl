#
# /www/admin/news/post-edit-2.tcl
#
# process the edit form for the news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-edit-2.tcl,v 3.1.2.2 2000/04/28 15:09:12 carsten Exp $

set_the_usual_form_variables 0

# maybe return_url, name
# news_item_id, title, body, html_p, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

set exception_count 0
set exception_text ""

set db [ns_db gethandle]

if [catch  {
    ns_dbformvalue [ns_conn form] release_date date release_date
    ns_dbformvalue [ns_conn form] expiration_date date expiration_date} errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {

    set expire_laterthan_future_p [database_to_tcl_string $db "select to_date('$expiration_date', 'yyyy-mm-dd')  - to_date('$release_date', 'yyyy-mm-dd')  from dual"]
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

if [catch { ns_ora clob_dml $db "update news_items
 set title='$QQtitle', body=empty_clob(),
 html_p='$html_p', release_date='$release_date', 
 expiration_date='$expiration_date' 
 where news_item_id = $news_item_id
 returning body into :one" $body } errmsg] {
    #  update failed
    ns_log Error "/admin/news/post-edit-2.tcl choked:  $errmsg"
    ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
" $db
   return
}

ad_returnredirect item.tcl?[export_url_vars news_item_id]
