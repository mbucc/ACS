# $Id: report-add.tcl,v 3.1.4.2 2000/04/28 15:11:10 carsten Exp $
# File: /www/intranet/projects/report-add.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: temporary file to redirect to general 
#  comments until we get structured project reports

set_the_usual_form_variables

# project_id, maybe return_url

set db [ns_db gethandle]

set item [database_to_tcl_string $db "select group_name from user_groups
where group_id = $group_id"]

if {![info exist return_url]} {
    set return_url "/intranet/projects/view.tcl?[export_url_vars group_id]"
}

ad_returnredirect "/general-comments/comment-add.tcl?on_which_table=im_projects&on_what_id=$group_id&item=Projects&module=intranet&[export_url_vars return_url item]&scope=group&group_id=$group_id"
