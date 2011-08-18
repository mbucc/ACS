#
# /www/news/admin/post-new-2.tcl
#
# process the input form for the new news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-new-2.tcl,v 3.1.2.2 2000/04/28 15:09:12 carsten Exp $

set_the_usual_form_variables 0
# maybe return_url, name
# news_item_id, title, body, html_p, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

if { ![info exists return_url] } {
    set return_url "index.tcl"
}

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id $db]
set creation_ip_address [ns_conn peeraddr]

set exception_count 0
set exception_text ""


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


if { ![info exists title] || [empty_string_p $title]} {
    incr exception_count
    append exception_text "<li>Please enter a title."
}
if { ![info exists body] || [empty_string_p $body]} {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if {$exception_count > 0} { 
    ad_return_complaint $exception_count $exception_text
    return
}

if { ![exists_and_not_null scope] } {
    set scope "public"
}

set additional_clause ""
if { [string match $scope "group"] && ![empty_string_p $group_id] } {
    set additional_clause "and group_id = $group_id"
}

# Get the newsgroup_id for this board
set newsgroup_id [database_to_tcl_string_or_null $db "select newsgroup_id 
from newsgroups
where scope = '$scope' $additional_clause"]

# Check if there is no news group for this scope
if { [empty_string_p $newsgroup_id] } { 
    # Create the newsgroup for the group
    ns_db dml $db "insert into newsgroups (newsgroup_id, scope, group_id) values (newsgroup_id_sequence.nextval, '$scope', $group_id)"
}

# Let's use data pipeline here to handle the clob for body, and the double click situation
set form_setid [ns_getform]
ns_set put $form_setid dp.news_items.news_item_id $news_item_id
ns_set put $form_setid dp.news_items.newsgroup_id $newsgroup_id
ns_set put $form_setid dp.news_items.title $title
ns_set put $form_setid dp.news_items.body.clob $body
ns_set put $form_setid dp.news_items.html_p $html_p
ns_set put $form_setid dp.news_items.approval_state approved
ns_set put $form_setid dp.news_items.approval_date.expr sysdate
ns_set put $form_setid dp.news_items.approval_ip_address $creation_ip_address
ns_set put $form_setid dp.news_items.release_date $release_date
ns_set put $form_setid dp.news_items.expiration_date $expiration_date
ns_set put $form_setid dp.news_items.creation_date.expr sysdate
ns_set put $form_setid dp.news_items.creation_user $user_id
ns_set put $form_setid dp.news_items.creation_ip_address $creation_ip_address

if [catch { dp_process -db $db -where_clause "news_item_id=$news_item_id" } errmsg] {
    ns_log Error "/admin/news/post-edit-2.tcl choked:  $errmsg"
    ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
   return
}


# ad_dbclick_check_dml $db news news_id $news_id $return_url "
# insert into news
# (news_id, title, body, html_p, approved_p, release_date, expiration_date, creation_date, creation_user, creation_ip_address, scope) 
# values 
# ($news_id, '$QQtitle', '$QQbody', '$html_p', 't', '$release_date', '$expiration_date', sysdate, $user_id, '$creation_ip_address', 'public')
# "


ad_returnredirect "index.tcl"