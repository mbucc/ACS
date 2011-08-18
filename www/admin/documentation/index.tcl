# $Id: index.tcl,v 3.1 2000/03/11 10:51:14 aure Exp $
ReturnHeaders 
ns_write "[ad_admin_header "Documentation"]

<h2>Documentation</h2>

[ad_admin_context_bar "Documentation"]
<hr>
<a href=\"/doc\">Human-generated documentation</a>
<h3>Browse</h3>
<ul>
<li><a href=\"directory-view.tcl?directory=[ns_urlencode [ns_info pageroot]/doc]\">[ad_system_name] design docs</a> | <a href=\"directory-view-with-contents.tcl?directory=[ns_urlencode [ns_info pageroot]]/doc\">full content</a>
<li><a href=\"directory-view.tcl?directory=[ns_urlencode [ns_info pageroot]/doc/sql]&text_p=t\">[ad_system_name] sql</a> | <a href=\"directory-view-with-contents.tcl?directory=[ns_urlencode [ns_info pageroot]]/doc/sql&text_p=t\">full content</a>
<li><a href=\"/doc/procs.tcl\">[ad_system_name] procedures</a> | <a href=\"directory-view-with-contents.tcl?directory=[ns_urlencode [ns_info pageroot]/../tcl]&text_p=t\">full content</a>
<li><a href=\"directory-view.tcl?directory=[ns_urlencode [ns_info pageroot]]&text_p=t\">[ad_system_name] files</a> | <a href=\"directory-view-with-contents.tcl?directory=[ns_urlencode [ns_info pageroot]]&text_p=t\">full content</a>
</ul>
<h3>Major changes to ACS</h3>
<ul>
<li><a href=\"/doc/custom.html\">ACS Customizations</a> 
<li><a href=\"/doc/patches.html\">ACS Patches</a>
</ul>


[ad_admin_footer]"
