# /www/admin/referer/mapping.tcl
#

ad_page_contract {
    @cvs-id Id: mapping.tcl,v 3.3.2.2 2000/07/13 06:27:02 paul Exp $
} {
}


set page_content "[ad_admin_header "Referral lumping patterns"]

<h2>Referral lumping patterns</h2>

[ad_admin_context_bar [list "" "Referrals"] "Lumping Patterns"]

<hr>

<ul>

"


set sql "select rowid, rlgp.*
from referer_log_glob_patterns rlgp
order by glob_pattern
"

set counter 0
db_foreach referer_glob_pattern_count $sql {
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
    append description "<br><a href = \"mapping-change?[export_url_vars glob_pattern]\">edit</a> 
|
<a href=\"apply-to-old-data?[export_url_vars glob_pattern]&simulate_p=1\">simulate</a>
|
<a href=\"apply-to-old-data?[export_url_vars glob_pattern]&simulate_p=0\">apply to legacy data (destructive)</a>

<p>
"
    append page_content "$description\n"
}

if { $counter == 0 } {
    append page_content "no lumping patterns currently installed"
}

append page_content "

<p>

<li><a href=\"mapping-add\">Add lumping pattern</a> 
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content

