#
# /survsimp/index.tcl
#
# by philg@mit.edu, February 9, 2000
#
# show all the (enabled) surveys that a user could take
# 
#$Id: index.tcl,v 1.2 2000/03/12 06:38:13 michael Exp $
#

set db [ns_db gethandle]

set whole_page "[ad_header "Surveys"]

<h2>Surveys</h2>

[ad_context_bar_ws_or_index "Surveys"]

<hr>

<ul>

"

set selection [ns_db select $db "select survey_id, name, enabled_p
from survsimp_surveys
where enabled_p = 't'
order by upper(name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append whole_page "<li><a href=\"one.tcl?[export_url_vars survey_id]\">$name</a>\n"
}

append whole_page "

</ul>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $whole_page 
