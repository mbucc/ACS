#
# /admin/survsimp/index.tcl
#
# by raj@alum.mit.edu, February 9, 2000
#
# survey administration page for site wide administration
# 


set page_content "[ad_admin_header "Simple Survey System (Site Wide Admin)"]

<h2>Simple Survey System Site Wide Administration</h2>

[ad_context_bar_ws_or_index "Simple Survey Site Wide Admin"]

<hr>

<ul>

"
set db [ns_db gethandle]

set selection [ns_db select $db "select survey_id, name, enabled_p
from survsimp_surveys"]

set disabled_header_written_p 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set enable "Enable"
    set disable "<a href=\"survey-toggle?[export_url_vars survey_id enabled_p]\">Disable</a>"
    if { $enabled_p == "f" } {
       set enable "<a href=\"survey-toggle?[export_url_vars survey_id enabled_p]\">Enable</a>"
       set disable "Disable"
    }
    append page_content "<li>$name: $enable $disable"

}

append page_content "
</ul>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $page_content 
