# $Id: primary-contact-delete.tcl,v 3.0.4.2 2000/04/28 15:11:05 carsten Exp $
# File: /www/intranet/customers/primary-contact-delete.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Removes customer's primary contact
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id, return_url

set db [ns_db gethandle]

ns_db dml $db \
	"update im_customers
            set primary_contact_id=null
          where group_id=$group_id"

ns_db releasehandle $db


ad_returnredirect $return_url