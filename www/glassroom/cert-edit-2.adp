<%
# cert-edit-2.adp -- commit changes made to a certificates in the 
#                    glassroom_certificates table
#                    (this is an ADP instead of a Tcl file to be consistent
#                    with cert-edi.adp)

set_the_usual_form_variables

# Expects hostname, issuer, encoded_email, expires, ns_db magic vars that
#         can be stitched together to form expires


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
	return
}




# check for bad input

# set happy_p [glassroom_check_cert_args $certname $ip_address $further_docs_url]

set happy_p 1

#!!! need to error check this

if [catch { ns_dbformvalue [ns_conn form] expires date expires } errmsg] {
    jwernjwenrjwenrjwenrjn
}

if $happy_p {

    set update_sql "
    update glassroom_certificates
    set 
        hostname='$QQhostname',
        issuer='$QQissuer',
        encoded_email='$QQencoded_email',
        expires=to_date('$expires', 'YYYY-MM-DD')
    where cert_id=$cert_id"

    set db [ns_db gethandle]
    ns_db dml $db $update_sql
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new certificate
    
    ad_returnredirect "cert-view.tcl?[export_url_vars cert_id]"
}
%>
