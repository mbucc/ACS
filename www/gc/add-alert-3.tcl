# $Id: add-alert-3.tcl,v 3.1 2000/03/10 23:58:20 curtisg Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# alert_id, domain_id, frequency, howmuch, submit_type
# also query_string, primary_category

set user_id [ad_verify_and_get_user_id]

set db [gc_db_gethandle]

if { [info exists alert_type] && [string compare all $alert_type] == 0 } {
    # user wants all the new ads
    ns_db dml $db "insert into classified_email_alerts
      (alert_id, domain_id, user_id, alert_type, expires, howmuch, frequency)
      values
      ($alert_id, $domain_id, $user_id, '$alert_type',sysdate+180, '$howmuch',
      '$frequency')"

} elseif { [info exists alert_type] && [string compare category $alert_type] == 0 } {
    if { $primary_category == "Choose a Category" } {
        ad_return_complaint 1 "<li>you need to choose a category\n"
        return
    } else {
        ns_db dml $db "insert into classified_email_alerts
      (alert_id, domain_id, user_id, alert_type, category, expires, howmuch,
      frequency)
      values
      ($alert_id, $domain_id,
      $user_id,'$alert_type','$QQprimary_category',sysdate+180,
      '$howmuch', '$frequency')"

    }
} elseif { [info exists alert_type] &&  [string compare keywords $alert_type] == 0  } {
    if { $query_string == "" } {
        ad_return_complaint 1 "<li>please choose at least keyword\n"
        return
    } else {
        ns_db dml $db "insert into classified_email_alerts
      (alert_id, domain_id, user_id, alert_type, keywords, expires, howmuch,
      frequency)
      values
      ($alert_id, $domain_id', $user_id,'$alert_type','$QQquery_string',sysdate+180,
      '$howmuch', '$frequency')"
    }
} else {
    # no alert_type
    ad_return_complaint 1 "You did not choose whether you want
      to get all ads, 
          ads within a category, or ads with some keywords. Please
      choose one of those 3 options."
    return
}

set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id]]
set_variables_after_query

ns_return 200 text/html "[gc_header "Alert Added"]

<h2>Alert Added</h2>

[ad_context_bar_ws_or_index [list "index.tcl" [gc_system_name]] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Alert Added"]

<hr>

Mail will be sent to [database_to_tcl_string $db "select email from users where user_id=$user_id"] [gc_PrettyFrequency $frequency].

[gc_footer $maintainer_email]"
