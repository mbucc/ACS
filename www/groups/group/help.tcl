# $Id: help.tcl,v 3.0 2000/02/06 03:46:23 ron Exp $
# File: /groups/group/help.tcl
# Date: 01/24/2000
# Contact: tarik@arsdigita.com
# Purpose: displays help files
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

# this page has same functionality as /help/for-one-page.tcl, so we can 
# simply use source command
source [ns_info pageroot]/help/for-one-page.tcl

