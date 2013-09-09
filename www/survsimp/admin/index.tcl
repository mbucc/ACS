# /www/survsimp/admin/index.tcl
ad_page_contract {
    This page is the main table of contents for navigation page 
    for simple survey module administrator

    @author philg@mit.edu
    @date February 9, 2000
    @cvs-id index.tcl,v 1.5.2.6 2000/09/22 01:39:20 kevin Exp
} {

}

set page_content "[ad_header "Simple Survey System (Admin)"]

<h2>Simple Survey System Administration</h2>

[ad_context_bar_ws_or_index "Simple Survey Admin"]

<hr>

<ul>

"

# Don't need to verify since the security filter should 
# have bounced him if there wasn't a user_id.
set user_id [ad_get_user_id]

if { [ad_administrator_p $user_id] } {
    set user_restriction_clause ""
} else {
    set user_restriction_clause "where creation_user = :user_id"
}

set disabled_header_written_p 0

db_foreach survsimp_surveys "select survey_id, name, enabled_p
from survsimp_surveys $user_restriction_clause
order by enabled_p desc, upper(name)" {

    if { $enabled_p == "f" && !$disabled_header_written_p } {
	set disabled_header_written_p 1
	append page_content "<h4>Disabled Surveys</h4>\n"
    }
    append page_content "<li><a href=\"one?[export_url_vars survey_id]\">$name</a>\n"
}

append page_content "

<p>

<li><a href=\"survey-create\">Create a new survey</a>
</ul>

[ad_footer]
"

doc_return  200 text/html $page_content 
