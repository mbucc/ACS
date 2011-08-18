<%
# domain-edit-2.adp -- commit changes made to a domains in the 
#                    glassroom_domains table
#                    (this is an ADP instead of a Tcl file to be consistent
#                    with domain-edi.adp)

set_the_usual_form_variables

# Expects old_domain_name, domain_name, by_whom_paid; 
#         last_paid, epires, ns_db magic vars that
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

# set happy_p [glassroom_check_domain_args $domainname $ip_address $further_docs_url]

if [catch { ns_dbformvalue [ns_conn form] expires date expires } errmsg] {
    ad_return_complaint 1 "<li> The expiration date wasn't well-formed"
    ns_adp_abort
}

if [catch { ns_dbformvalue [ns_conn form] last_paid date last_paid } errmsg] {
    ad_return_complaint 1 "<li> The Last-paid date wasn't well-formed"
    ns_adp_abort
}


set happy_p 1


if $happy_p {

    set update_sql "
    update glassroom_domains
    set 
        domain_name='$QQdomain_name',
        by_whom_paid='$QQby_whom_paid',
        last_paid = to_date('$last_paid', 'YYYY-MM-DD'),
        expires = to_date('$expires', 'YYYY-MM-DD')
    where domain_name='$old_domain_name'"

    set db [ns_db gethandle]
    ns_db dml $db $update_sql
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new domain
    
    ad_returnredirect "domain-view.tcl?[export_url_vars domain_name]"
}
%>
