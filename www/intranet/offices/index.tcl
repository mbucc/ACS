# $Id: index.tcl,v 3.2.2.1 2000/03/17 08:23:01 mbryzek Exp $
# File: /www/intranet/offices/index.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Lists all offices
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

# set selection [ns_db select $db \
# 	"select g.group_id, g.group_name
#            from user_groups g, im_offices o
#           where o.group_id=g.group_id
#        order by lower(g.group_name)"]

set selection [ns_db select $db \
	"select group_id, group_name 
           from user_groups
          where parent_group_id=[im_office_group_id]
          order by lower(group_name)"] 

set results ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append results "  <li> <a href=view.tcl?[export_url_vars group_id]>$group_name</a>\n"
}

if { [empty_string_p $results] } {
    set results "  <li><b> There are no offices </b>\n" 
}

ns_db releasehandle $db

set page_title "Offices"
set context_bar [ad_context_bar [list "/" Home] [list ../index.tcl "Intranet"] $page_title]

set page_body "
<ul>
$results
<p><li><a href=ae.tcl>Add an office</a>
</ul>
"
 
ns_return 200 text/html [ad_partner_return_template]
