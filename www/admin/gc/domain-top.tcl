# $Id: domain-top.tcl,v 3.1.2.1 2000/03/14 22:21:17 curtisg Exp $
set_the_usual_form_variables

# domain_id

set db [gc_db_gethandle]
set selection [ns_db 1row $db [gc_query_for_domain_info $domain_id ad_domains.rowid,]]
set_variables_after_query

append html "[ad_admin_header "Administer the $domain Classifieds"]

<h2>Administration</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] $full_noun]

<hr>

<ul>
<p>

<H3> The ads</h3>
<li><a href=\"/gc/domain-top.tcl?domain_id=$domain_id\">user's view for $domain classifieds</a>
<p>
<li> <form action=ads.tcl method=post>
Ads from the last <select name=num_days>[ad_integer_optionlist 1 30]</select>
[export_form_vars domain_id] day(s)
<input type=submit name=submit value=\"Go\">
</form>

<li><a href=\"ads.tcl?domain_id=$domain_id&num_days=all\">all ads</a>

<p>

<li><a href=\"manage-categories-for-domain.tcl?domain_id=$domain_id\">ads by category</a>

<H3>Users</h3>
<li>
Pick out the users who've posted at least

<form method=post action=community-view.tcl>
[export_form_vars domain_id]
<input type=text name=n_postings value=1 size=4> time(s)

between

[_ns_dateentrywidget start_date]

and

[_ns_dateentrywidget end_date]


<input type=submit value=\"Go\">

</form>
<li> <a href=\"view-alerts.tcl?[export_url_vars domain_id]\">View alerts</a>

<p>

<h3>Domain properties</h3>
<li><a href=\"manage-categories-for-domain.tcl?[export_url_vars domain_id]\">manage categories</a>

<li><a href=\"domain-administrator-update.tcl?[export_url_vars domain_id]\">administrator/owner of $domain</a>

<li><a href=\"/admin/ug/group.tcl?group_id=[ad_administration_group_id $db "gc" $domain]\">user/helper administrators</a>

<li><a href=\"domain-edit.tcl?[export_url_vars domain_id]\">update $domain domain parameters</a>

<p>

<li><a href=\"domain-delete.tcl?[export_url_vars domain_id]\">delete $domain</a>
(only do this if you were simply testing the system)

</ul>



[ad_admin_footer]"

ns_db releasehandle $db
ns_return 200 text/html $html
