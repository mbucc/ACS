# /www/news/admin/post-new-2.tcl
#

ad_page_contract {
    process the input form for the new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new-2.tcl,v 3.5.2.13 2001/01/09 21:58:00 khy Exp

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
    on_which_group:integer,optional
    on_what_id:integer,optional
    {return_url "index" }
    name:optional
    news_item_id:verify,integer,notnull
    title:html,notnull
    body:html,notnull
    html_p:notnull
    release_date:array,date
    expiration_date:array,date
} -validate {
    expires_after_release -requires {release_date expiration_date} {
	if {[string compare $release_date(date) $expiration_date(date)] >= 0} {
	    ad_complain "Please make sure the expiration date is later than the release date"
	}
    }
}

ad_scope_error_check

set user_id [ad_scope_authorize $scope admin group_admin none]

set creation_ip_address [ns_conn peeraddr]

if { [info exists scope] && [string match $scope "group"] } {
    set approval_policy [ad_parameter GroupScopeApprovalPolicy news [ad_parameter ApprovalPolicy news]]
}  else {
    set approval_policy [ad_parameter ApprovalPolicy news]
}

if { $approval_policy == "open" } {
    set approval_state "approved"
} else {
    set approval_state "disapproved"
}

if { ![exists_and_not_null scope] } {
    set scope "public"
}

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
db_release_unused_handles


# Let's use data pipeline here to handle the clob for body, and the double click situation
set form_setid [ns_set create]
ns_set put $form_setid dp.news_items.news_item_id.int $news_item_id
ns_set put $form_setid dp.news_items.newsgroup_id.int $newsgroup_id
ns_set put $form_setid dp.news_items.title $title
ns_set put $form_setid dp.news_items.body.clob $body
ns_set put $form_setid dp.news_items.html_p $html_p
ns_set put $form_setid dp.news_items.approval_state $approval_state
ns_set put $form_setid dp.news_items.approval_date.expr sysdate
ns_set put $form_setid dp.news_items.approval_ip_address $creation_ip_address
ns_set put $form_setid dp.news_items.release_date $release_date(date)
ns_set put $form_setid dp.news_items.expiration_date $expiration_date(date)
ns_set put $form_setid dp.news_items.creation_date.expr sysdate
ns_set put $form_setid dp.news_items.creation_user.int $user_id
ns_set put $form_setid dp.news_items.creation_ip_address $creation_ip_address

if [catch { dp_process -set_id $form_setid -where_clause "news_item_id=:news_item_id" } errmsg] {
    db_release_unused_handles
    ns_log Error "/news/admin/post-edit-2 choked:  $errmsg"
    ad_scope_return_error "Insert Failed" "The Database did not like what you typed.
    This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

db_release_unused_handles

ad_returnredirect $return_url

