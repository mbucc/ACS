# /www/glossary/index.tcl

ad_page_contract {

    @author Walter McGinnis (walter@arsdigita.com)
    @cvs-id: index.tcl,v 3.3.2.4 2000/09/22 01:38:05 kevin Exp
} {} 

set user_id [ad_verify_and_get_user_id]

set whole_page "[ad_header "Glossary"]

<h2>Terms Defined</h2>

[ad_context_bar_ws_or_index Glossary]

<hr>
<blockquote>
"

set sql "select term, author
from glossary
where approved_p = 't'
order by upper(term)"

set old_first_char ""
set count 0

append whole_page "<table border=0 cellpadding=0 cellspacing=0>"

db_foreach glossary_loop $sql {
    set first_char [string toupper [string index $term 0]]
    if { [string compare $first_char $old_first_char] != 0 } {
	if { $count > 0 } {
	    append whole_page "</ul></td></tr>\n"
	}
	append whole_page "<tr><td valign=top><h3>$first_char</h3>\n</td><td><ul>\n"
    }
    
    append whole_page "<li><a href=\"one?[export_url_vars term]\">$term</a>\n"
    if { $author == $user_id && [ad_parameter ApprovalPolicy glossary] == "open" } {
	append whole_page "\[ <a href=\"term-edit?[export_url_vars term]\">Edit</a> \]\n"
    }

    set old_first_char $first_char
    incr count
}

db_release_unused_handles

append whole_page "</ul></td></tr></table>\n"

if { [ad_parameter ApprovalPolicy glossary] == "open" } {
    append whole_page "<a href=\"term-new\">Add a Term</a>\n"
} elseif { [ad_parameter ApprovalPolicy glossary] == "wait" } {
    append whole_page "<a href=\"term-new\">Suggest a Term</a>\n"
}

append whole_page "
</blockquote>

[ad_footer]
"


doc_return  200 text/html $whole_page
