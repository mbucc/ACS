# $Id: add-link-2.tcl,v 3.0.4.1 2000/04/28 15:08:29 carsten Exp $
# File:     /admin/content-sections/add-link-2.tcl
# Date:     29/12/99
# Contact:  ahmeds@mit.edu
# Purpose:  Content Section add link target page 
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# from_section_id, to_section_id, section_link_id 

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none
ns_db dml $db "
insert into content_section_links
(section_link_id, from_section_id, to_section_id)
select $section_link_id, $from_section_id, $to_section_id
from dual
where not exists (select 1 
                  from content_section_links
                  where section_link_id = $section_link_id )
"

ad_returnredirect link.tcl?[export_url_scope_vars]

