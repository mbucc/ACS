# $Id: other-projects.tcl,v 3.1.4.2 2000/03/17 08:56:38 mbryzek Exp $
# File: /www/intranet/hours/other-projects.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Lets a user choose a project on which to log hours
# 

set_form_variables
# on_which_table julian_date

ad_maybe_redirect_for_registration

set page_title "Choose a project"
set context_bar [ad_context_bar [list "/" Home] [list "../index.tcl" Intranet] [list index.tcl?[export_url_vars on_which_table] Hours] [list ae.tcl?[export_url_vars on_which_table julian_date] "Add hours"] "Choose project"]

set db [ns_db gethandle]

set page_body "<ul>\n"
set counter 0
set selection [ns_db select $db \
	"select g.group_name, g.group_id 
           from user_groups g, im_projects p
          where g.group_id=p.group_id
       order by upper(group_name)"]

while {[ns_db getrow $db $selection]} {
    incr counter
    set_variables_after_query
    append page_body "<li><a href=ae.tcl?on_what_id=$group_id&[export_url_vars on_which_table julian_date]>$group_name</a>\n"
}

if { $counter == 0 } {
    append page_body "  <li> There are no projects.\n"
}

append page_body "</ul>\n"


ns_db releasehandle $db

ns_return 200 text/html [ad_partner_return_template]
