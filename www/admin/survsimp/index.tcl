# /www/admin/survsimp/index.tcl
ad_page_contract {

    This is the main survey administration page for site wide administrator.
    It lists all the active and inactive surveys.

    @author raj@alum.mit.edu
    @date   February 9, 2000
    @cvs-id index.tcl,v 1.3.2.7 2000/09/22 01:36:11 kevin Exp
} {

}

set page_content "[ad_admin_header "Simple Survey System (Site Wide Admin)"]

<h2>Simple Survey System Site Wide Administration</h2>

[ad_admin_context_bar "Simple Survey Site Wide Admin"]

<hr>

<ul>"

set disabled_header_written_p 0
db_foreach surveys_all "select survey_id, name, enabled_p from survsimp_surveys" {
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
[ad_admin_footer]
"


doc_return  200 text/html $page_content 
