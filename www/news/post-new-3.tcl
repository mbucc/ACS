# /www/news/post-new-3.tcl
#

ad_page_contract {
    process the input form for the new news item

    @author jkoontz@arsdigita.com
    @creation-date March 8, 2000
    @cvs-id post-new-3.tcl,v 3.6.2.13 2001/01/09 21:53:10 khy Exp

    Note: if page is accessed through /groups pages then group_id and 
    group_vars_set are already set up in the environment by the 
    ug_serve_section. group_vars_set contains group related variables
    (group_id, group_name, group_short_name, group_admin_email, 
    group_public_url, group_admin_url, group_public_root_url,
    group_admin_root_url, group_type_url_p, group_context_bar_list and
    group_navbar_list)
} {
    scope:optional
    user_id:integer,optional
    group_id:integer,optional
    on_which_group:integer,optional
    on_what_id:integer,optional
    {return_url "?[export_url_vars]"}
    name:optional
    {html_p "f"}
    news_item_id:verify,integer,notnull
    title:html,notnull
    body:html,notnull
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# also AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

ad_scope_error_check


set user_id [ad_scope_authorize $scope all all all]

if { $user_id == 0 } {
    ad_returnredirect "/register/?[export_url_vars]"
    return
}

set creation_ip_address [ns_conn peeraddr]

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

if { ![info exists title] || [empty_string_p $title]} {
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

if { [info exists scope] && [string match $scope "group"] } {
    set approval_policy [ad_parameter GroupScopeApprovalPolicy news [ad_parameter ApprovalPolicy news]]
}  else {
    set approval_policy [ad_parameter ApprovalPolicy news]
}

if { $approval_policy == "open" } {
    set approval_state "approved"
} elseif { $approval_policy == "wait"} {
    set approval_state "disapproved"
}

if { ![exists_and_not_null scope] } {
    set scope "public"
}

set additional_clause ""
if { [string match $scope "group"] && ![empty_string_p $group_id] } {
    set additional_clause "and group_id = :group_id"
}

# Get the newsgroup_id for this board
set newsgroup_id [db_string news_id_get "select newsgroup_id 
    from newsgroups where scope = :scope $additional_clause" -default "" ]

# Check if there is no news group for this scope
if { [empty_string_p $newsgroup_id] } { 
    # Create the newsgroup for the group
    db_dml news_id_insert "insert into newsgroups (newsgroup_id, scope, group_id) 
                   values (newsgroup_id_sequence.nextval, :scope, :group_id)"

    set newsgroup_id [db_string news_id_insert "select newsgroup_id 
        from newsgroups where scope = :scope $additional_clause" -default "" ]
}
db_release_unused_handles


# Let's use data pipeline here to handle the clob for body, and the double click situation
set form_setid [ns_set create]
ns_set put $form_setid dp.news_items.news_item_id.int $news_item_id
ns_set put $form_setid dp.news_items.newsgroup_id.int $newsgroup_id
ns_set put $form_setid dp.news_items.title $title
ns_set put $form_setid dp.news_items.body $body
ns_set put $form_setid dp.news_items.html_p $html_p
ns_set put $form_setid dp.news_items.approval_state $approval_state
ns_set put $form_setid dp.news_items.approval_date.expr sysdate
ns_set put $form_setid dp.news_items.release_date $release_date
ns_set put $form_setid dp.news_items.expiration_date $expiration_date
ns_set put $form_setid dp.news_items.creation_date.expr sysdate
ns_set put $form_setid dp.news_items.creation_user.int $user_id
ns_set put $form_setid dp.news_items.creation_ip_address $creation_ip_address

if [catch { dp_process -set_id $form_setid -where_clause "news_item_id=:news_item_id" } errmsg] {
    ns_log Error "/news/post-new-3 choked:  $errmsg"
    ad_scope_return_error "Insert Failed" "The Database did not like what you typed.
    This is probably a bug in our code.  Here's what the database said:
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}


if { [ad_parameter GroupScopeApprovalPolicy news [ad_parameter ApprovalPolicy news]] == "open"} {
    ad_returnredirect $return_url
} else {
    set page_content "
    [ad_scope_header "Thank you"]
    <h2>Thank you</h2>
    for your submission to [ad_site_home_link]
    <hr>
    Your submission will be reviewed by 
    [ad_parameter SystemOwner news [ad_system_owner]].
    [ad_scope_footer]
    "

    
    doc_return  200 text/html $page_content
}

