# $Id: index.tcl,v 3.0 2000/02/06 03:32:07 ron Exp $
ReturnHeaders 

ns_write "[ad_header "Banner Ideas"]

<h2>Banner Ideas</h2>

[ad_context_bar_ws_or_index "All Banner Ideas"]

<hr>

"

set db [banner_ideas_gethandle]

set selection [ns_db select $db "select idea_id, intro, more_url, picture_html
from bannerideas"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write [bannerideas_present $idea_id $intro $more_url $picture_html]
}


ns_write "

[ad_footer]
"
