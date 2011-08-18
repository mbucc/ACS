# $Id: index.tcl,v 3.0 2000/02/06 02:48:25 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Banner Ideas" ]

<h2>Banner Ideas</h2>

[ad_admin_context_bar "Banner Ideas Administration"]

<hr>

Documentation:  <a href=\"/doc/bannerideas.html\">/doc/bannerideas.html</a>.

<h3>Banner ideas</h3>


<ul>
"

set db [banner_ideas_gethandle]
set sql_query  "select idea_id, intro, more_url, picture_html, clickthroughs
from bannerideas
order by idea_id"
set selection [ns_db select $db $sql_query] 

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    # can't show the picture because it is usually absolute URLs
    # and we're probably on HTTPS right now
    ns_write "<li>$intro &nbsp; &nbsp; 
...
<br>
<a href=\"$more_url\">more</a> ($clickthroughs clicks so far to $more_url) | 
<a href=\"banner-edit.tcl?[export_url_vars  idea_id]\">Edit</a>
<p>
"

}

if { $counter == 0 } {
    ns_write "<li>there are no ideas in the database right now"
}

ns_write "<p>

<li><a href=\"banner-add.tcl\">Add a banner idea</a>
</ul>

[ad_admin_footer]
"

