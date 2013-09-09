# /homepage/update-display-3.tcl

ad_page_contract {
    Delete all display customization related to the filesystem_node.

    @param filesystem_node The top directory displayed (passed argument).

    @author mobin@mit.edu
    @cvs-id update-display-3.tcl,v 3.2.2.4 2000/07/21 04:00:47 ron Exp
} {
    filesystem_node:notnull,naturalnum
}

set user_id [ad_maybe_redirect_for_registration]

set vars_list [list bgcolor textcolor unvisited_link visited_link maint_bgcolor maint_textcolor maint_unvisited_link maint_visited_link font_type link_text_decoration link_font_weight maint_font_type maint_link_text_decoration maint_link_font_weight]

set sql_update_set [list]

foreach var $vars_list {
    set $var [db_null]
    lappend sql_update_set "$var = :$var"
}


set sql_update "
update users_homepages
set [join $sql_update_set ",\n"]
where user_id=:user_id
"

set bind_vars [ad_tcl_vars_list_to_ns_set [concat $vars_list [list user_id]]]

db_dml display_erase $sql_update -bind $bind_vars

db_release_unused_handles

ad_returnredirect "index.tcl?filesystem_node=$filesystem_node"

