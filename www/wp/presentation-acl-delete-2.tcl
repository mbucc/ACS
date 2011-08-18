# $Id: presentation-acl-delete-2.tcl,v 3.0.4.1 2000/04/28 15:11:40 carsten Exp $
# File:        presentation-acl-delete-2.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Removes a user's ACL.
# Inputs:      presentation_id, req_user_id

set_the_usual_form_variables

set db [ns_db gethandle]
set user_id [ad_maybe_redirect_for_registration]
wp_check_authorization $db $presentation_id $user_id "admin"

set selection [ns_db 1row $db "select * from wp_presentations where presentation_id = $presentation_id"]
set_variables_after_query

ns_db dml $db "delete from user_group_map where group_id = $group_id and user_id = [wp_check_numeric $req_user_id]"

ad_returnredirect "presentation-acl.tcl?presentation_id=$presentation_id"
