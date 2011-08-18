# $Id: ticket-edit.tcl,v 3.1.4.1 2000/03/17 08:23:13 mbryzek Exp $
#
# File: /www/intranet/projects/ticket-edit.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: sets up environment to edit a ticket tracker
#  project without being in the ticket admin group
#


set_form_variables

set form_setid [ns_getform]

set db [ns_db gethandle]
set selection [ns_db 1row $db \
	"select * from user_groups where group_id=$group_id"]
set_variables_after_query
ns_db releasehandle $db

ns_set put $form_setid target "[im_url_stub]/projects/ticket-edit-2.tcl"
ns_set put $form_setid owning_group_id $group_id
ns_set put $form_setid preset_title $group_name
ns_set put $form_setid preset_title_long $group_name
if { ![exists_and_not_null return_url] } {
    set return_url "[im_url]/projects/view.tcl?[export_url_vars group_id]"
}
ns_set put $form_setid return_url $return_url

source "[ns_info pageroot]/ticket/admin/project-edit.tcl"
