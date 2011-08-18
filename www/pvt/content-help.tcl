# $Id: content-help.tcl,v 3.0 2000/02/06 03:53:31 ron Exp $
set_the_usual_form_variables
# section_id

set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]

set selection [ns_db 1row $db "
select section_pretty_name, help_blurb
from content_sections
where section_id = $section_id"]

set_variables_after_query

ReturnHeaders 
ns_write "
[ad_header "$section_pretty_name help"]
[ad_decorate_top "<h2>$section_pretty_name help</h2>
[ad_context_bar_ws "Help"]
" [ad_parameter WorkspacePageDecoration pvt]]

<hr>

$help_blurb

[ad_footer]
"

