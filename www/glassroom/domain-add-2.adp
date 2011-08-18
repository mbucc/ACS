<%
# domain-add-2.adp -- add a new domain to the the glassroom_domains
#                   table.
#                   (this is an ADP as opposed to a .tcl file so that 
#                   it's consistent naming with domain-add.adp)


set_the_usual_form_variables

# Expects domain_name, by_whom_paid, last_paid, expires, ns_db magic vars that
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

set happy_p 1


if [catch { ns_dbformvalue [ns_conn form] expires date expires } errmsg] {
    ad_return_complaint 1 "<li> The expiration date wasn't well-formed"
    ns_adp_abort
}

if [catch { ns_dbformvalue [ns_conn form] last_paid date last_paid } errmsg] {
    ad_return_complaint 1 "<li> The Last-paid date wasn't well-formed"
    ns_adp_abort
}



if $happy_p {
    
    # Assuming we don't need to confirm entry.  Just add it to the
    # glassroom_domains table
    
    set insert_sql "
    insert into glassroom_domains
      (domain_name, by_whom_paid, last_paid, expires)
    values
      ('$QQdomain_name', '$QQby_whom_paid',
       to_date('$last_paid', 'yyyy-mm-dd'),
       to_date('$expires', 'yyyy-mm-dd'))
    "
    
    set db [ns_db gethandle]
    ns_db dml $db "$insert_sql"
    ns_db releasehandle $db
    
    
    # and redirect back to index.tcl so folks can see the new domain  list
    
    ad_returnredirect "index.tcl"
}
%>

