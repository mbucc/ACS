# /www/admin/gc/domain-top.tcl
ad_page_contract {
    @author xxx
    @creation-date unknown
    @cvs-id domain-top.tcl,v 3.4.2.5 2000/09/22 01:35:22 kevin Exp
} {
    domain_id:integer
}


db_1row info_for_domain [gc_query_for_domain_info $domain_id ad_domains.rowid,]


append html "[ad_admin_header "Administer the $domain Classifieds"]

<h2>Administration</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] $full_noun]

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

<p>

<li><a href=\"manage-categories-for-domain?domain_id=$domain_id\">ads by category</a>

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

<p>

<h3>Domain properties</h3>
<li><a href=\"manage-categories-for-domain?[export_url_vars domain_id]\">manage categories</a>

<li><a href=\"domain-administrator-update?[export_url_vars domain_id]\">administrator/owner of $domain</a>

<li><a href=\"/admin/ug/group?group_id=[ad_administration_group_id "gc" $domain]\">user/helper administrators</a>

<li><a href=\"domain-edit?[export_url_vars domain_id]\">update $domain domain parameters</a>

<p>

<li><a href=\"domain-delete?[export_url_vars domain_id]\">delete $domain</a>
(only do this if you were simply testing the system)

</ul>

[ad_admin_footer]"


doc_return  200 text/html $html
