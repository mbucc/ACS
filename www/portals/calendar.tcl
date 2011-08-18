#
# calendar for sloan portal
# by aileen@mit.edu, randyg@arsdigita.com
# Feb 2000
#

ad_page_variables {
    date
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

ns_return 200 text/html "
[ad_header "Calendars @ [ad_system_name]"]
<h2>Calendar</h2>

[ad_context_bar_ws_or_index [list /portals/user$user_id-1.ptl "Portal"] "Calendar"]

<hr>
[edu_calendar_for_portal $db $date]
[ad_footer]
"
