# $Id: sort-by-n-messages.tcl,v 3.3 2000/03/01 08:45:04 yon Exp $
proc bboard_active_discussions_items {} {
    set user_id [ad_get_user_id]
    set items ""
    set db [ns_db gethandle]
    set selection [ns_db select $db "select bt.topic,bt.topic_id, bt.presentation_type, count(msg_id) as n_messages, max(posting_time) as latest_posting
from bboard_topics bt, bboard b
where bt.topic_id = b.topic_id
and (bt.group_id is null or ad_group_member_p ( $user_id, bt.group_id ) = 't' )
group by bt.topic,bt.topic_id, bt.presentation_type
having count(msg_id) > 30
order by count(msg_id) desc"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	append items "<li>[bboard_complete_backlink $topic_id $topic $presentation_type] ($n_messages; latest on [util_AnsiDatetoPrettyDate $latest_posting])\n"
    }
    ns_db releasehandle $db
    return $items
}

proc bboard_n_new_messages {} {
    set items ""
    set db [ns_db gethandle]
    set n_new [database_to_tcl_string $db "select count(*)
from bboard 
where posting_time + 1 > sysdate"]
    ns_db releasehandle $db
    return $n_new
}

ReturnHeaders

ns_write "[bboard_header "Active Discussions in [bboard_system_name]"]

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

	ns_write "You can search through all of the 
messages on all of the bulletin boards in this system.
<form method=GET action=search-entire-system.tcl target=\"_top\">
Full Text Search:  <input type=text name=query_string size=40>
</form>

<p>

Note: this does not search through discussions that are private and protected
by a user password.
"

}

ns_write [bboard_footer]
