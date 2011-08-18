# glossary/index.tcl
#
# by unknown (probably philg@mit.edu)
#
# later refined by aure@caltech.edu
#
# $Id: index.tcl,v 3.0 2000/02/06 03:45:03 ron Exp $

set user_id [ad_verify_and_get_user_id]

ReturnHeaders
ns_write "[ad_header "Glossary"]

<h2>Terms Defined</h2>

[ad_context_bar_ws_or_index Glossary]

<hr>
<blockquote>
"


set db [ns_db gethandle]

set selection [ns_db select $db "select term, author
from glossary
where approved_p = 't'
order by upper(term)"]

set old_first_char ""
set count 0

set big_string "<table border=0 cellpadding=0 cellspacing=0>"

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    set first_char [string toupper [string index $term 0]]
    if { [string compare $first_char $old_first_char] != 0 } {
	if { $count > 0 } {
	    append big_string "</ul></td></tr>\n"
	}
	append big_string "<tr><td valign=top><h3>$first_char</h3>\n</td><td><ul>\n"
    }
    
    append big_string "<li><a href=\"one.tcl?term=[ns_urlencode $term]\">$term</a>\n"
    if { $author == $user_id && [ad_parameter ApprovalPolicy glossary] == "open" } {
	append big_string "\[ <a href=\"term-edit.tcl?term=[ns_urlencode $term]\">Edit</a> \]\n"
    }

    set old_first_char $first_char
    incr count
}

append big_string "</ul></td></tr></table>\n"

if { [ad_parameter ApprovalPolicy glossary] == "open" } {
    append big_string "<a href=\"term-new.tcl\">Add a Term</a>\n"
} elseif { [ad_parameter ApprovalPolicy glossary] == "wait" } {
    append big_string "<a href=\"term-new.tcl\">Suggest a Term</a>\n"
}

append big_string "
</blockquote>

[ad_footer]
"

ns_db releasehandle $db
ns_write $big_string
