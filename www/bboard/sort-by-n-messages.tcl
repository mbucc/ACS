# /www/bboard/sort-by-n-messages.tcl
ad_page_contract {
    Displays the bboard topics sorted by number of messages
    
    @cvs-id sort-by-n-messages.tcl,v 3.5.2.4 2000/09/22 01:36:55 kevin Exp
} {}

# -----------------------------------------------------------------------------

proc bboard_active_discussions_items {} {
    set user_id [ad_verify_and_get_user_id]
    set items ""
    set active_threshold [ad_parameter "ActiveLevelThreshold" bboard 30]
    
    db_foreach messages "
    select bt.topic,
    	   bt.topic_id, 
    	   bt.presentation_type, 
    	   count(msg_id) as n_messages, 
    	   max(posting_time) as latest_posting
    from   bboard_topics bt, 
           bboard b
    where  bt.topic_id = b.topic_id
    and    (bt.group_id is null or 
              ad_group_member_p ( :user_id, bt.group_id ) = 't' )
    group by bt.topic,bt.topic_id, bt.presentation_type
    having count(msg_id) > :active_threshold
    order by count(msg_id) desc" {

	append items "<li>[bboard_complete_backlink $topic_id $topic $presentation_type] ($n_messages; latest on [util_AnsiDatetoPrettyDate $latest_posting])\n"
    }
    db_release_unused_handles
    return $items
}

proc bboard_n_new_messages {} {
    set items ""
    
    set n_new [db_string n_new "
    select count(*)
    from   bboard 
    where  posting_time + 1 > sysdate"]

    db_release_unused_handles
    return $n_new
}

# -----------------------------------------------------------------------------


append page_content "
[bboard_header "Active Discussions in [bboard_system_name]"]

[ad_decorate_top "<h2>Active Discussions</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [bboard_system_name]] "Active Discussions"]
" [ad_parameter ActivePageDecoration bboard]]

<hr>

Total messages posted in last 24 hours:   
[util_memoize bboard_n_new_messages 3600]

<ul>
[bboard_active_discussions_items]
</ul>

"

# Can't memoize this right now because some topics are private!
# [util_memoize bboard_active_discussions_items 3600]

if { [bboard_pls_blade_installed_p] } {

	append page_content "You can search through all of the 
messages on all of the bulletin boards in this system.
<form method=GET action=search-entire-system target=\"_top\">
Full Text Search:  <input type=text name=query_string size=40>
</form>

<p>

Note: this does not search through discussions that are private and protected
by a user password.
"

}

append page_content [bboard_footer]

doc_return  200 text/html $page_content