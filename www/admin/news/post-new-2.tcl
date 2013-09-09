# /www/admin/news/post-new-2.tcl
#

ad_page_contract {
    process the input form for the new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new-2.tcl,v 3.5.2.15 2001/01/09 22:02:59 khy Exp
} {
    {return_url ""}
    news_item_id:verify,integer,notnull
    title:html,notnull
    body:html,notnull
    html_p:notnull
    {scope "public"}
    {group_id:integer ""}
    release_date:array,date
    expiration_date:array,date
} -validate {
    expire_after_release -requires {release_date expiration_date} {
	if {[string compare $release_date(date) $expiration_date(date)] >= 0} {
	    ad_complain "Please make sure the expiration date is later than the release date."
	}
    }
}


set user_id [ad_verify_and_get_user_id]
set creation_ip_address [ns_conn peeraddr]


set additional_clause ""
if { [string match $scope "group"] && ![empty_string_p $group_id] } {
    set additional_clause "and group_id = :group_id"
}


# Check if there is no news group for this scope
if { ![db_0or1row news_id_get "select newsgroup_id 
from newsgroups where scope = :scope $additional_clause"]} {
    # Create the newsgroup for the group
    set newsgroup_id [db_nextval newsgroup_id_sequence]
    db_dml news_id_insert "insert into newsgroups (newsgroup_id, scope, group_id) values (:newsgroup_id, :scope, :group_id)"
}

# Let's use data pipeline here to handle the clob for body, and the double click situation
set form_setid [ns_set create]
ns_set put $form_setid dp.news_items.news_item_id.int $news_item_id
ns_set put $form_setid dp.news_items.newsgroup_id.int $newsgroup_id
ns_set put $form_setid dp.news_items.title $title
ns_set put $form_setid dp.news_items.body.clob $body
ns_set put $form_setid dp.news_items.html_p $html_p
ns_set put $form_setid dp.news_items.approval_state approved
ns_set put $form_setid dp.news_items.approval_date.expr sysdate
ns_set put $form_setid dp.news_items.approval_ip_address $creation_ip_address
ns_set put $form_setid dp.news_items.release_date $release_date(date)
ns_set put $form_setid dp.news_items.expiration_date $expiration_date(date)
ns_set put $form_setid dp.news_items.creation_date.expr sysdate
ns_set put $form_setid dp.news_items.creation_user.int $user_id
ns_set put $form_setid dp.news_items.creation_ip_address $creation_ip_address


if [catch { dp_process -set_id $form_setid -where_clause "news_item_id=:news_item_id" } errmsg] {
    ns_log Error "/admin/news/post-edit-2 choked:  $errmsg"
    ad_return_error "Insert Failed" "The Database did not like what you typed.
    This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

db_release_unused_handles

ad_returnredirect $return_url
