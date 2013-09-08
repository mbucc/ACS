# /www/gc/admin/domain-top.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id domain-top.tcl,v 3.2.6.8 2000/09/22 01:37:59 kevin Exp

    @param domain_id
} {
    domain_id:integer,notnull
}
 
ad_maybe_redirect_for_registration

set user_id [ad_get_user_id]

db_1row gc_admin_domain_top_domain_info_get [gc_query_for_domain_info $domain_id ad_domains.rowid,]

if {![ad_administrator_p] && ![ad_administration_group_member "gc" $domain $user_id]} {    
    ad_return_error "Unauthorized" "Unauthorized" 
    return
}

append html "[ad_admin_header "Administer the $domain Classifieds"]

<h2>Administration</h2>

[ad_context_bar_ws_or_index [list "/gc/" "Classifieds"] [list "index.tcl" "Classifieds Admin"] $full_noun]

<hr>

<ul>
<p>

<H3> The ads</h3>
<li><a href=\"/gc/domain-top?domain_id=$domain_id\">user's view for $domain classifieds</a>
<p>
<li> <form action=ads method=post>
Ads from the last <select name=num_days>[ad_integer_optionlist 1 30]</select>
[export_form_vars domain_id] day(s)
<input type=submit name=submit value=\"Go\">
</form>

<li><a href=\"ads?domain_id=$domain_id&num_days=all\">all ads</a>

<H3>Users</h3>
<li>
Pick out the users who've posted at least

<form method=post action=community-view>
[export_form_vars domain_id]
<input type=text name=n_postings value=1 size=4> time(s)

between

[_ns_dateentrywidget start_date]

and

[_ns_dateentrywidget end_date]


<input type=submit value=\"Go\">

</form>

<li> <a href=\"view-alerts?[export_url_vars domain_id]\">View alerts</a>

</ul>

[ad_admin_footer]"

doc_return  200 text/html $html
