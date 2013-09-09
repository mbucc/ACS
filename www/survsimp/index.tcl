# /www/survsimp/index.tcl
ad_page_contract {
    Lists all the enabled surveys
    a user is eligable to complete.

    @author  philg@mit.edu
    @date    February 9, 2000
    @cvs-id  index.tcl,v 1.5.2.6 2000/09/22 01:39:19 kevin Exp
} {

}

set whole_page "[ad_header "Surveys"]

<h2>Surveys</h2>

[ad_context_bar_ws_or_index "Surveys"]

<hr>

<ul>

"

set counter 0

db_foreach survsimp_enabled_surveys "select survey_id, name, enabled_p from survsimp_surveys where enabled_p = 't' order by upper(name)" {
    append whole_page "<li><a href=\"one?[export_url_vars survey_id]\">$name</a>\n"
    incr counter
}

if { $counter == "0" } {
    append whole_page "<li>No surveys active\n"
}

append whole_page "

</ul>

[ad_footer]
"


doc_return  200 text/html $whole_page 
