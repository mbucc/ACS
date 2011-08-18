# $Id: view.tcl,v 3.4.2.2 2000/04/28 15:11:11 carsten Exp $
# File: /www/intranet/users/view.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: View everything about a user. We redirect right 
#  now to community-member.tcl but leave this file here to:
#    1. default to the current cookied user
#    2. have a secure place later for more detailed employee
#       info w/out breaking links


set_form_variables 0 
# user_id

if { ![exists_and_not_null user_id] } {
    set user_id [ad_get_user_id]
}

ad_returnredirect /shared/community-member.tcl?[export_url_vars user_id]
