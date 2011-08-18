# $Id: index-legacy.tcl,v 3.0 2000/02/06 02:44:49 ron Exp $
# /admin/index.tcl

ReturnHeaders

set db [ns_db gethandle]

ns_write "[ad_admin_header "Admin Home for [ad_system_name]"]

<h2>[ad_system_name] Administration</h2>

[ad_context_bar_ws "Admin Home"]

<hr>

Help:  see <a href=\"/doc/webmasters.html\">the webmasters guide</a>

<ul>

<li>New stuff site-wide:  
<a href=\"new-stuff.tcl\">all</a> |
<a href=\"new-stuff.tcl?only_from_new_users_p=t\">only from new users</a>

<p>

<li><a href=\"users/\">users</a>

"

if [mv_enabled_p] {
    ns_write "<P>
<li><a href=\"member-value/\">member value</a> (money)
"
}

ns_write "
<p>

<li><a href=\"ug/\">user groups</a>


<p>

<li><A HREF=\"bboard/\">bboards</A>

<li><A HREF=\"general-comments/\">general comments</A>

<li><A HREF=\"general-links/\">general links</A>

<li><A HREF=\"calendar/\">calendar</A>
<li><A HREF=\"chat/\">chat</A>

<li><A HREF=\"neighbor/\">neighbor-to-neighbor</A>

<li><A HREF=\"news/\">news</A>

<li><A HREF=\"gc/\">classifieds</A>

<li><A HREF=\"adserver/\">ad server</A>
<li><A HREF=\"bannerideas/\">banner ideas</A>

<li><A HREF=\"contest/\">contests</A>

<li><A HREF=\"poll/\">polls</A>

<li><A HREF=\"glossary/\">glossary</A>

<li><A HREF=\"registry/\">stolen equipment registry</A>

<li><A HREF=\"spam/\">spam</A>

<li><A HREF=\"events/\">events</A>

<li><A HREF=\"press/\">press</A>

<li><A HREF=\"faq/\">FAQ</A>

<p>

<li><a href=\"intranet/\">intranet</A>
<li><a href=\"address-book/\">address book</a>
<li><a href=\"bookmarks/\">bookmarks</a>
<li><a href=\"file-storage/\">file storage</a>

<p>

<li><a href=\"partner/\">co-branding</a>

<li><a href=\"searches/\">user searches</a>

<li><a href=\"links/\">related links</a>

<li><a href=\"static/\">static content</a>
<li><a href=\"comments/\">comments on static pages</a>



<li><a href=\"click/report.tcl\">clickthroughs</a>

<li><a href=\"referer/\">referrals</a>

<p>
<li><a href=\"documentation\">documentation</a>
<li><a href=\"monitoring\">monitoring</a>
<li><a href=\"ticket/index.tcl\">project and bug tracking</a> (/ticket system)

</ul>


<h3>Heavy Duty Maintenance</h3>

These pages will change fundamental properties of the service.  Use
with extreme caution.

<ul>
<li><a href=\"content-sections/\">content sections</a>
<li><a href=\"categories/\">categories</a>
<li><a href=\"curriculum/element-list.tcl\">curriculum</a>
<li><a href=\"portals/\">portals</a>

<p>

<li><a href=\"crm/\">Customer Relationship Management (CRM)</a>

<p>

<li><a href=\"robot-detection/\">robot detection</a> 
(giving specialized content to robots)

<p>

<!-- <li><a href=\"dba/\">dba information</a> --> 

</ul>

[ad_admin_footer]
"




