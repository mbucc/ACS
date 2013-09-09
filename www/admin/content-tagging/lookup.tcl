# File: /www/admin/content-tagging/lookup.tcl
ad_page_contract {
    Displays the word and allows user to change the word's rating
    @param word
    @author unknown
    @cvs-id lookup.tcl,v 3.3.2.4 2000/09/22 01:34:35 kevin Exp
} {
    word
}

if {[empty_string_p $word]} {
    ad_returnredirect "all.tcl"
    return
} 



set title "Tagged Word Results" 

set page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Naughty Package"] $title]

<hr>

<form action=rate method=post>
[export_entire_form]
"


set pretty_tag(0) "Rated G"
set pretty_tag(1) "Rated PG"
set pretty_tag(3) "Rated R"
set pretty_tag(7) "Rated X"


if {[db_0or1row select_tag "select tag from content_tags where word=:word"]} {





    append page_content "<input type=hidden name=todo value=update>\n"

} else {
    set tag 0
    append page_content "<b>$word</b> is not yet rated<P>
    <input type=hidden name=todo value=create>\n"
}

append page_content "<p>Give a rating to <b>$word</b>:<ul>"

foreach potential_tag {0 1 3 7} {
    if { $tag != $potential_tag } {
	append page_content "<li><input type=radio name=tag value=$potential_tag> $pretty_tag($potential_tag)"
    } else {
	append page_content "<li><input type=radio name=tag value=$potential_tag checked> $pretty_tag($potential_tag)"
    }
}
append page_content "
<P> (A \"G\" rating will remove the word from the database)
</ul>
<center>
<input type=submit value=Rate>
</form>
</center>

[ad_admin_footer]
"



doc_return  200 text/html $page_content





