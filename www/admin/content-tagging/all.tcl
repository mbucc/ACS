#File: /www/admin/content-tagging/all.tcl
ad_page_contract {
    Shows all the words in the dictionary
    @param none
    @author unknown
    @cvs-id all.tcl,v 3.2.2.4 2000/09/22 01:34:35 kevin Exp
} {
}

set title "Naughty Dictionary"

set page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Content Tagging Package"] $title]

<hr>

<form action=rate method=post>

"

set pretty_tag(0) "Rated G"
set pretty_tag(1) "Rated PG"
set pretty_tag(3) "Rated R"
set pretty_tag(7) "Rated X"



set last_tag ""
db_foreach select_tag "select word, tag from content_tags order by tag, word" {
    if {[string compare $tag $last_tag]} {
	append page_content "</ul><b>$pretty_tag($tag)</b><ul>"
	set last_tag $tag
    }
    append page_content "<li><a href=lookup?[export_url_vars word]>$word</a>"
}




append page_content "</ul>
[ad_admin_footer]
"



doc_return  200 text/html $page_content





