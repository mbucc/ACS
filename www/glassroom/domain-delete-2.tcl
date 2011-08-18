# $Id: domain-delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:41 carsten Exp $
# domain-delete-2.tcl -- remove a domain from glassroom_domains
#

set_form_variables

# Expects domain_name

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


# emit the page contents

ReturnHeaders

ns_write "[ad_header "\"$domain_name\" Deleted"]

<h2>\"$domain_name\" Deleted</h2>
<hr>
"


#!!! what to do if delete fails...

set db [ns_db gethandle]

ns_db dml $db "delete from glassroom_domains where domain_name='$domain_name'"

ns_db releasehandle $db


ns_write "
Deletion of domain for domain_name $domain_name confirmed.

<p>


<a href=index.tcl>Return to the Glass Room</a>

[glassroom_footer]
"