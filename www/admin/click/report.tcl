# $Id: report.tcl,v 3.0 2000/02/06 03:14:50 ron Exp $
# this really should be index.tcl but sadly due to legacy links (dating
# back to 1996 or so), it has to be "report.tcl"

ReturnHeaders

ns_write "[ad_admin_header "Clickthroughs from [ad_system_name]"]

<h2>Clickthroughs for [ad_system_name]</h2>

[ad_admin_context_bar "Clickthroughs"]

<hr>

<ul>

<li><a href=\"by-foreign-url.tcl\">by foreign URL</a>
<li><a href=\"by-local-url.tcl\">by local URL</a>

</ul>

<h4>Expensive Queries (may take a long time)</h4>

<ul>

<li><a href=\"by-foreign-url-aggregate.tcl\">by foreign URL</a> (summary report); 
<a href=\"by-foreign-url-aggregate.tcl?minimum=10\">limit to those with 10 or more </a>
<li><a href=\"by-local-url-aggregate.tcl\">by local URL</a> (summary report)

</ul>

To learn how to augment HTML pages to take advantage of clickthrough
logging, read the documentation at <a
href=\"/doc/clickthrough.html\">/doc/clickthrough.html</a>.

[ad_admin_footer]
"
