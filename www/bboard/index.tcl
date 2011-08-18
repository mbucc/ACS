# $Id: index.tcl,v 3.2 2000/03/01 08:45:03 yon Exp $
set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

# we successfully opened the database

set user_id [ad_get_user_id]


append whole_page "[bboard_header "Welcome to [bboard_system_name]"]

[ad_decorate_top "<h2>Welcome to [bboard_system_name]</h2>

[ad_context_bar_ws_or_index [bboard_system_name]]
" [ad_parameter IndexPageDecoration bboard]]

<hr>

[ad_decorate_side]

<a href=\"sort-by-n-messages.tcl\">sort by activity</a>

<ul>
"

set moderation_policy_sort_key 1
foreach moderation_policy [bboard_moderation_policy_order] {
    append decode_internals "'[DoubleApos $moderation_policy]',$moderation_policy_sort_key,"
    incr moderation_policy_sort_key
}

if ![info exists decode_internals] {
    set order_by "upper(topic)"
} else {
    # add one last integer at the end
    set order_by "decode(moderation_policy,null,0,$decode_internals$moderation_policy_sort_key) asc, upper(topic)"
}

set selection [ns_db select $db "select moderation_policy, topic, topic_id, presentation_type
from bboard_topics
where (active_p = 't' or active_p is null)
and (bboard_topics.group_id is null
     or ad_group_member_p ( $user_id, bboard_topics.group_id ) = 't' )
order by $order_by"]

set last_moderation_policy ""
set first_iteration_p 1
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_moderation_policy != $moderation_policy } {
	if !$first_iteration_p {
	    append whole_page "\n\n</ul>\n\n"
	}
	append whole_page "<h3>[bboard_moderation_title $moderation_policy] </h3>\n\n<ul>\n\n"
        set last_moderation_policy $moderation_policy
    }
    set first_iteration_p 0
    append whole_page "<li>[bboard_complete_backlink $topic_id $topic $presentation_type]\n"
}

set n_groups [database_to_tcl_string $db "select count(group_id) from user_group_map where user_id = $user_id"]

if {$n_groups > 0 &&  [bboard_users_can_add_topics_p]} {
    append whole_page "<p>

<li><a href=\"add-new-topic.tcl\">Add New Topic</a> (i.e., add a new discussion board)
"
}

if { $first_iteration_p == 0 } {
    # moderation policy titles were used
    append whole_page "</ul>"
}

append whole_page "

</ul>

"


if { [bboard_pls_blade_installed_p] } {
    set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
    append whole_page "
You can search through all of the 
messages on all of the bulletin boards in this system.
<form method=GET action=\"$search_server/bboard/search-entire-system.tcl\" target=\"_top\">
Full Text Search:  <input type=text name=query_string size=40>
<input type=submit name=submit value=submit>
</form>
<p>
"

}

append whole_page "
[bboard_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $whole_page
