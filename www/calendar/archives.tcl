# www/calendar/archives.tcl
ad_page_contract {
    Displays a list of expired calendar items
    
    Number of queries: 1
    
    @author Philip Greenspun (philg@mit.edu)
    @author Sarah Ahmed (ahmeds@arsdigita.com)
    @creation-date 1998-11-18
    @cvs-id archives.tcl,v 3.3.2.6 2000/09/22 01:37:04 kevin Exp
    @last-modified 2000-07-12
    @last-modified-by Michael Shurpik (mshurpik@arsdigita.com)
} {
    {scope public}
    {user_id ""}
    {group_id ""}
    {on_what_id ""}
    {on_which_group ""}
}

## Original Comments:

# archives.tcl,v 3.3.2.6 2000/09/22 01:37:04 kevin Exp
# File:     /calendar/archives.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

## Original set_form comments:

# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check


ad_scope_authorize $scope all group_member registered

set page_title "[ad_parameter SystemName calendar "Calendar"] Archives"



set page_content "
[ad_scope_header $page_title]
[ad_scope_page_title $page_title]
from [ad_site_home_link]

<hr>
[ad_scope_navbar]

<ul>
"

set query_old_calendars "
select c.title, c.calendar_id
from calendar c , calendar_categories cc
where sysdate > c.expiration_date
and c.approved_p = 't'
and c.category_id=cc.category_id
and [ad_scope_sql cc]
order by c.start_date, c.creation_date"

set counter 0
db_foreach old_calendars $query_old_calendars {
    
    incr counter
    append page_content "<li><a href=\"item?[export_url_scope_vars calendar_id]\">$title</a>\n"
}

append page_content "</ul>

[ad_scope_footer]
"

doc_return  200 text/html $page_content

## END FILE archives.tcl