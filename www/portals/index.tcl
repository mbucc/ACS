#
# /portals/index.tcl
#
# Entry to the point to the Caltech portals - needs to be edited for the next client or for generic ACS
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# Last modified: 10/8/1999
#
# $Id: index.tcl,v 3.2 2000/03/10 22:59:08 richardl Exp $
#

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

# Get generic display information
portal_display_info

# Get a list of portal groups that actually have content
set group_select "
    select distinct group_name, ug.group_id 
    from   user_groups ug, portal_pages pp
    where  group_type='portal_group'
    and    ug.group_id = pp.group_id
    and not group_name = 'Super Administrators'"
set selection [ns_db select $db $group_select]

set portal_extension [ad_parameter PortalExtension portals .ptl]

set portal_link_list ""
while { [ns_db getrow $db $selection ] } {
    set_variables_after_query
    # convert spaces to dashes and capitals to lowercase for the url
    regsub -all { } [string tolower $group_name] {-} group_name_in_link 
    append portal_link_list "<li><a href=$group_name_in_link-1$portal_extension>$group_name</a>\n"
}
ns_db releasehandle $db

if { [ad_parameter AllowUserLevelPortals portals] == 1 && $user_id != 0 } {
    append portal_link_list "<li> <a href=\"user$user_id-1$portal_extension\">Your personalized portal</a>\n"
}

# ---------------------------------------------------------
# serve the page

set page_content "[ad_header "$system_name"]

<h2>$system_name</h2>

[ad_context_bar_ws_or_index "Portals"]

<hr>

Choose a portal:

<ul>
$portal_link_list
</ul>

[ad_footer]
"
ns_return 200 text/html $page_content













