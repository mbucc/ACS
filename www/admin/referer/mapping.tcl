# $Id: mapping.tcl,v 3.0 2000/02/06 03:27:48 ron Exp $
set_form_variables 0

ReturnHeaders

ns_write "[ad_admin_header "Referral lumping patterns"]

<h2>Referral lumping patterns</h2>

[ad_admin_context_bar [list "index.tcl" "Referrals"] "Lumping Patterns"]

<hr>

<ul>

"

set db [ns_db gethandle]
set selection [ns_db select $db "select rowid, rlgp.*
from referer_log_glob_patterns rlgp
order by glob_pattern
"]


set counter 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    set description ""
 
   append description "<li>We map URLs matching
<ul>
<li>$glob_pattern
to
<li>$canonical_foreign_url
</ul>\n"
    if {[string length $search_engine_name] > 0} {
	append description "We think that this is search engine called \"$search_engine_name\"."
	if {[string length $search_engine_regexp] > 0} {
	    append description "  We look for the string that the user typed with the Regexp \"<code>$search_engine_regexp</code>\"."
	}
    }
    append description "<br><a href = \"mapping-change.tcl?[export_url_vars glob_pattern]\">edit</a> 
|
<a href=\"apply-to-old-data.tcl?[export_url_vars glob_pattern]&simulate_p=1\">simulate</a>
|
<a href=\"apply-to-old-data.tcl?[export_url_vars glob_pattern]&simulate_p=0\">apply to legacy data (destructive)</a>

<p>
"
    ns_write "$description\n"
}

if { $counter == 0 } {
    ns_write "no lumping patterns currently installed"
}

ns_write "

<p>

<li><a href=\"mapping-add.tcl\">Add lumping pattern</a> 
</ul>

[ad_admin_footer]
"

