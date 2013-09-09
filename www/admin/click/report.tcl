# www/admin/click/report.tcl

ad_page_contract {
    @cvs-id report.tcl,v 3.2.2.2 2000/09/22 01:34:31 kevin Exp
} {    
}
 
# this really should be index.tcl but sadly due to legacy links (dating
# back to 1996 or so), it has to be "report.tcl"

set html "[ad_admin_header "Clickthroughs from [ad_system_name]"]

<h2>Clickthroughs for [ad_system_name]</h2>

[ad_admin_context_bar "Clickthroughs"]

<hr>

<ul>

<li><a href=\"by-foreign-url\">by foreign URL</a>
<li><a href=\"by-local-url\">by local URL</a>

</ul>

<h4>Expensive Queries (may take a long time)</h4>

<ul>

<li><a href=\"by-foreign-url-aggregate\">by foreign URL</a> (summary report); 
<a href=\"by-foreign-url-aggregate?minimum=10\">limit to those with 10 or more </a>
<li><a href=\"by-local-url-aggregate\">by local URL</a> (summary report)

</ul>

To learn how to augment HTML pages to take advantage of clickthrough
logging, read the documentation at <a
href=\"/doc/clickthrough\">/doc/clickthrough.html</a>.

[ad_admin_footer]
"

doc_return 200 text/html $html
