# /admin/index.tcl
#
# by aure@arsdigita.com and dh@arsdigita.com
#
# 2000-02-03
#
# $Id: index.tcl,v 3.4.2.2 2000/03/16 18:31:01 bryanche Exp $

ns_return 200 text/html "
[ad_admin_header "Admin Home for [ad_system_name]"]

<h2>[ad_system_name] Administration</h2>

[ad_context_bar_ws "Admin Home"]

<hr>

[help_upper_right_menu [list "/doc/webmasters" "help: the webmaster's guide"]]

<br clear=all>

[help_upper_right_menu [list "index-legacy" "old style admin page"]]

<ul>

<b>New stuff site-wide:</b>  

<a href=\"new-stuff\">all</a> |
<a href=\"new-stuff?only_from_new_users_p=t\">only from new users</a>

<p>
<a name=user_management>
<b>User Management</b>
<ul>
<li><a href=\"categories/\">categories</a>
<li><a href=\"crm/\">crm</a> (customer relationship management)

[expr {[mv_enabled_p]==1?"<li><a href=\"member-value/\">member value</a> (money)":""}]

<li><a href=\"users/\">users</a>
<li><a href=\"ug/\">user groups</a>
<li><a href=\"searches/\">user searches</a>

<p>

<li><a href=\"bboard/\">bboards</a>
<li><a href=\"general-comments/\">general comments</a>
<li><a href=\"calendar/\">calendar</a>
<li><a href=\"chat/\">chat</a>
<li><a href=\"neighbor/\">neighbor-to-neighbor</a>
<li><a href=\"news/\">news</a>
<li><a href=\"gc/\">classifieds</a>
<li><a href=\"adserver/\">ad server</a>
<li><a href=\"bannerideas/\">banner ideas</a>
<li><a href=\"contest/\">contests</a>
<li><a href=\"poll/\">polls</a>
<li><a href=\"glossary/\">glossary</a>
<li><a href=\"registry/\">stolen equipment registry</a>
<li><a href=\"spam/\">spam</a>
<li><a href=\"/events/admin/\">events</a>
<li><a href=\"press/\">press</a>
<li><a href=\"education/\">education</a>

</ul>

<p>

<a name=user_modules>
<b>User Utility Modules</b>
<ul>
<li><a href=\"address-book/\">address book</a>
<li><a href=\"bboard/\">bboards</a>
<li><a href=\"bookmarks/\">bookmarks</a>
<li><a href=\"calendar/\">calendar</a>
<li><a href=\"chat/\">chat</a>
<li><a href=\"gc/\">classifieds</a>
<li><a href=\"contest/\">contests</a>
<li><a href=\"download/\">download</a>
<li><a href=\"/events/admin/\">events</a>
<li><a href=\"faq/\">faq</a>
<li><a href=\"file-storage/\">file storage</a>
<li><a href=\"glossary/\">glossary</a>
<li><a href=\"intranet/\">intranet</a>
<li><a href=\"neighbor/\">neighbor-to-neighbor</a>
<li><a href=\"news/\">news</a>
<li><a href=\"poll/\">polls</a>
<li><a href=\"press/\">press</a>
<li><a href=\"registry/\">stolen equipment registry</a>
<li><a href=\"ticket/\">ticket tracker</a> (project and bug tracking)
</ul>


<p>

<a name=site_tools>
<b>Site Wide Tools</b>

<ul>
<li><a href=\"adserver/\">ad server</a>
<li><a href=\"bannerideas/\">banner ideas</a>
<li><a href=\"click/report\">clickthroughs</a>
<li><a href=\"partner/\">co-branding</a>
<li><a href=\"content-sections/\">content sections</a>
<li><a href=\"curriculum/element-list\">curriculum</a>
<li><a href=\"display/\">display</a>
<li><a href=\"documentation\">documentation</a>
<li><a href=\"monitoring\">monitoring</a>
<li><a href=\"portals/\">portals</a>
<li><a href=\"pull-down-menus/\">pull-down menus</a>
<li><a href=\"referer/\">referrals</a>
<li><a href=\"robot-detection/\">robot detection</a> 
<li><a href=\"spam/\">spam</a>
<li><a href=\"static/\">static content</a>
</ul>
<p>

<a name=module_tools>

<b>Module Tools</b>
<ul>
<li><a href=\"comments/\">comments on static pages</a>
<li><a href=\"content-tagging/\">content tagging</a>
<li><a href=\"general-comments/\">general comments</a>
<li><a href=\"general-links/\">general links</a>
<li><a href=\"links/\">related links</a>
</ul>
</ul>

[ad_admin_footer]"
