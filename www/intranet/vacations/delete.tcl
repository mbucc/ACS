# $Id: delete.tcl,v 3.1.2.2 2000/04/28 15:11:12 carsten Exp $
# File: /www/intranet/vacations/delete.tcl
#
# created, jsalz@mit.edu, 28 Feb 2000
#
# Purpose: Deletes a vacation for a specified user
#

set_the_usual_form_variables

# vacation_id

set vacation_id [validate_integer vacation_id $vacation_id]

set my_user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

set user_id [database_to_tcl_string $db "
    select user_id
    from user_vacations 
    where vacation_id = $vacation_id
"]

if { $user_id == $my_user_id || [im_is_user_site_wide_or_intranet_admin $db $my_user_id] } {
    ns_db dml $db "delete from user_vacations where vacation_id = $vacation_id"
    ad_returnredirect "index.tcl"
}

ad_return_warning "Not authorized" "You are not authorized to perform this operation."
