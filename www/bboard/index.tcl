ad_page_contract {
    The index page for the bboard system, displays the active public bboards and/or
    bboards that user is a member. The display takes into account the moderation policy.

    @author bryzek 
    @css-id index.tcl,v 3.5.2.5 2000/08/06 17:55:09 kevin Exp
    @creation-date 12 Jul 2000
} {
}


set user_id [ad_get_user_id]

append page_content "[bboard_header "Welcome to [bboard_system_name]"]
[ad_decorate_top "<h2>Welcome to [bboard_system_name]</h2>
[ad_context_bar_ws_or_index [bboard_system_name]]
" [ad_parameter IndexPageDecoration bboard]]

<hr>
[ad_decorate_side]

<a href=\"sort-by-n-messages\">sort by activity</a>
<ul>
"
set moderation_policy_sort_key 1
foreach moderation_policy [bboard_moderation_policy_order] {
    set moderation_policy_${moderation_policy_sort_key} $moderation_policy
    append decode_internals ":moderation_policy_${moderation_policy_sort_key},$moderation_policy_sort_key,"
    incr moderation_policy_sort_key
}

if ![info exists decode_internals] {
    set order_by "upper(topic)"
} else {
    # add one last integer at the end
    set order_by "decode(moderation_policy,null,0,${decode_internals}$moderation_policy_sort_key) asc, upper(topic)"
}



set last_moderation_policy ""
set first_iteration_p 1
set sql_select "
select moderation_policy
, topic
, topic_id
, presentation_type
from bboard_topics
where (active_p = 't' or active_p is null)
and (bboard_topics.group_id is null
     or ad_group_member_p ($user_id, bboard_topics.group_id ) = 't' )
order by $order_by"


db_foreach bb_index_tcl_select $sql_select {
    if { $last_moderation_policy != $moderation_policy } {
	if !$first_iteration_p {
	    append page_content "\n\n</ul>\n\n"
	}
	append page_content "<h3>[bboard_moderation_title $moderation_policy] </h3>\n\n<ul>\n\n"
        set last_moderation_policy $moderation_policy
    }
    set first_iteration_p 0
    append page_content "<li>[bboard_complete_backlink $topic_id $topic $presentation_type]\n"
}

set n_groups [db_string n_groups "select count(group_id) from user_group_map where user_id = :user_id"]

if {$n_groups > 0 &&  [bboard_users_can_add_topics_p]} {
    append page_content "<p>

<li><a href=\"add-new-topic\">Add New Topic</a> (i.e., add a new discussion board)
"
}

if { $first_iteration_p == 0 } {
    # moderation policy titles were used
    append page_content "</ul>"
}

append page_content "
</ul>
"

# /search now uses scoping for security, so direct it over there (phong@arsdigita.com)
if { [bboard_pls_blade_installed_p] } {
    set search_server [ad_parameter BounceQueriesTo site-wide-search ""]
    append page_content "
    You can search through all of the 
    messages on all of the bulletin boards in this system.
    <form method=GET action=\"$search_server/search/search\" target=\"_top\">
    Full Text Search:  <input type=text name=query_string size=40>
    <input type=hidden name=sections value=bboard>
    <input type=submit name=submit value=submit>
    </form>
    <p>
    "

}

append page_content "
[bboard_footer]
"



doc_return  200 text/html $page_content















