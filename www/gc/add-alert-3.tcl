ad_page_contract {
    
    Actually inserts into the database the correct types of email
    alerts, according to the criterion the user selected.
    
    @author xxx
    @date unknown
    @cvs-id add-alert-3.tcl,v 3.2.6.6 2001/01/10 18:59:21 khy Exp
} {
    alert_id:naturalnum,notnull,verify
    domain_id
    frequency
    howmuch
    alert_type
    query_string
    primary_category
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

if { [info exists alert_type] && [string compare all $alert_type] == 0 } {
    # user wants all the new ads
    db_dml alert_for_all_new_ads_dml "insert into classified_email_alerts
      (alert_id, domain_id, user_id, alert_type, expires, howmuch, frequency)
      values
      (:alert_id, :domain_id, :user_id, :alert_type, sysdate+180, :howmuch,
      :frequency)" -bind [ad_tcl_vars_to_ns_set alert_id domain_id \
              user_id alert_type howmuch frequency]

} elseif { [info exists alert_type] && [string compare category $alert_type] == 0 } {
    if { $primary_category == "Choose a Category" } {
        ad_return_complaint 1 "<li>you need to choose a category\n"
        return
    } else {
        db_dml alert_for_category_new_ads_dml "insert into classified_email_alerts
      (alert_id, domain_id, user_id, alert_type, category, expires, howmuch,
      frequency)
      values
      (:alert_id, :domain_id, :user_id, :alert_type, :primary_category, sysdate+180,
      :howmuch, :frequency)" -bind [ad_tcl_vars_to_ns_set alert_id domain_id \
              user_id alert_type primary_category howmuch frequency]
    }
} elseif { [info exists alert_type] &&  [string compare keywords $alert_type] == 0  } {
    if { $query_string == "" } {
        ad_return_complaint 1 "<li>please choose at least keyword\n"
        return
    } else {
        db_dml alert_for_category_new_ads_dml "insert into classified_email_alerts
      (alert_id, domain_id, user_id, alert_type, keywords, expires, howmuch,
      frequency)
      values
      (:alert_id, :domain_id, :user_id, :alert_type, :query_string,
       sysdate+180, :howmuch, :frequency)" -bind [ad_tcl_vars_to_ns_set alert_id domain_id \
              user_id alert_type query_string howmuch frequency]
    }
} else {
    # no alert_type
    ad_return_complaint 1 "You did not choose whether you want
      to get all ads, 
          ads within a category, or ads with some keywords. Please
      choose one of those 3 options."
    return
}

db_1row gc_query_for_domain_info [gc_query_for_domain_info $domain_id]

set page_content "[gc_header "Alert Added"]

<h2>Alert Added</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Alert Added"]

<hr>

Mail will be sent to [db_string unused "select email from users where user_id=$user_id"] [gc_PrettyFrequency $frequency].

[gc_footer $maintainer_email]"


doc_return  200 text/html $page_content








