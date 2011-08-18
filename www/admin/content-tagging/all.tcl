# $Id: all.tcl,v 3.0 2000/02/06 03:15:24 ron Exp $
ReturnHeaders

set title "Naughty Dictionary"

ns_write "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Content Tagging Package"] $title]

<hr>

<form action=rate.tcl method=post>

"
set db [ns_db gethandle]
set pretty_tag(0) "Rated G"
set pretty_tag(1) "Rated PG"
set pretty_tag(3) "Rated R"
set pretty_tag(7) "Rated X"


set sql "select word, tag from content_tags order by tag, word"
set selection [ns_db select $db $sql]

set last_tag ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {[string compare $tag $last_tag]} {
	ns_write "</ul><b>$pretty_tag($tag)</b><ul>"
	set last_tag $tag
    }
    ns_write "<li><a href=lookup.tcl?[export_url_vars word]>$word</a>"
}

ns_write "</ul>

[ad_admin_footer]
"



