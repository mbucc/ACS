# www/portals/index.tcl

ad_page_contract {
    Entry to the point to the portals system

    @author Aurelius Prochazka (aure@arsdigita.com)
    @author David Hill (dh@arsdigita.com)
    @creation-date 10/8/1999
    @cvs-id index.tcl,v 3.4.2.10 2000/09/22 01:39:01 kevin Exp
} {
}

set user_id [ad_verify_and_get_user_id]

# Get generic display information
portal_display_info

# Get a list of portal groups that actually have content
set portal_extension [ad_parameter PortalExtension portals .ptl]
set portal_link_list ""

db_foreach portals_index_group_select "
    select distinct short_name, group_name, ug.group_id 
    from   user_groups ug, portal_pages pp
    where  group_type  = 'portal_group'
    and    ug.group_id = pp.group_id
    and not group_name = 'Super Administrators'" {

    set group_name_in_link [ad_urlencode [string tolower $short_name]]
    append portal_link_list "<li><a href=$group_name_in_link-1$portal_extension>$group_name</a>\n"
}
db_release_unused_handles

if { [ad_parameter AllowUserLevelPortals portals] == 1 && $user_id != 0 } {
    append portal_link_list "<li> <a href=\"user$user_id-1$portal_extension\">Your personalized portal</a>\n"
}

set page_content "[ad_header $system_name]

<h2>$system_name</h2>

[ad_context_bar_ws_or_index "Portals"]

<hr>
Choose a portal:

<ul>
$portal_link_list
</ul>

[ad_footer]
"

doc_return  200 text/html $page_content










