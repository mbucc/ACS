# $Id: primary-contact-2.tcl,v 3.1.4.2 2000/04/28 15:11:05 carsten Exp $
# File: /www/intranet/customers/primary-contact-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Writes customer's primary contact to the db
# 

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id, address_book_id

set db [ns_db gethandle]

ns_db dml $db \
	"update im_customers 
            set primary_contact_id=$address_book_id
          where group_id=$group_id"

ns_db releasehandle $db


ad_returnredirect view.tcl?[export_url_vars group_id]