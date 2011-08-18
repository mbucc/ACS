# $Id: cert-delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:40 carsten Exp $
# cert-delete-2.tcl -- remove a certificate from glassroom_certificates
#

set_form_variables

# Expects cert_id

if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
	return
}



# snarf the host name

set db [ns_db gethandle]

set select_sql "
select hostname
  from glassroom_certificates
 where cert_id=$cert_id"

set hostname [database_to_tcl_string_or_null $db $select_sql]


# emit the page contents

ReturnHeaders

ns_write "[ad_header "Certificate for \"$hostname\" Deleted"]

<h2>Certificate \"$hostname\" Deleted</h2>
<hr>
"


#!!! what to do if delete fails...

ns_db dml $db "delete from glassroom_certificates where cert_id=$cert_id"

ns_db releasehandle $db


ns_write "
Deletion of certificate for hostname $hostname confirmed.

<p>


<a href=index.tcl>Return to the Glass Room</a>

[glassroom_footer]
"