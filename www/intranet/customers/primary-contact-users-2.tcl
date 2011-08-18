# $Id: primary-contact-users-2.tcl,v 3.1.4.2 2000/04/28 15:11:05 carsten Exp $
#
# File: /www/intranet/customers/primary-contact-users-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Allows you to have a primary contact that references the
# users table. We don't use this yet, but it will indeed
# be good once all customers are in the users table


set user_id [ad_verify_and_get_user_id]

ad_maybe_redirect_for_registration

set_form_variables
# group_id, user_id_from_search

set db [ns_db gethandle]

ns_db dml $db \
	"update im_customers 
            set primary_contact_id=$user_id_from_search
          where group_id=$group_id"

ns_db releasehandle $db


ad_returnredirect view.tcl?[export_url_vars group_id]