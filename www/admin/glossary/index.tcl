# $Id: index.tcl,v 3.0.4.1 2000/04/28 15:09:06 carsten Exp $
#
# /admin/glossary/index.tcl
#
# by jsc@arsdigita.com in February 1999
# 

set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


ReturnHeaders
ns_write "[ad_admin_header "Terms Defined"]
<h2>Terms Defined</h2>
[ad_admin_context_bar Glossary]
<hr>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select term
from glossary
where approved_p = 'f'
order by upper(term)"]

set old_first_char ""
set count 0
set pending_items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    set first_char [string toupper [string index $term 0]]
    if { [string compare $first_char $old_first_char] != 0 } {
	if { $count > 0 } {
	    append pending_items "</ul>\n"
	}
	append pending_items "<h3>$first_char</h3>\n<ul>\n"
    }
    
    append pending_items "<li><a href=\"one.tcl?term=[ns_urlencode $term]\">$term</a>
\[ <a href=\"term-approve.tcl?term=[ns_urlencode $term]\">Approve</a> \]\n"

    set old_first_char $first_char
    incr count
}

if { ![empty_string_p $pending_items] } {
    ns_write "<h3>Pending Definitions</h3>
<ul>
$pending_items
</ul>
</ul>
"
}

ns_write "



<h3>Approved Definitions</h3>
<blockquote>
"

set selection [ns_db select $db "select term
from glossary
where approved_p = 't'
order by upper(term)"]

set old_first_char ""
set count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    
    set first_char [string toupper [string index $term 0]]
    if { [string compare $first_char $old_first_char] != 0 } {
	if { $count > 0 } {
	    ns_write "</ul>\n"
	}
	ns_write "<h3>$first_char</h3>\n<ul>\n"
    }
    
    ns_write "<li><a href=\"one.tcl?term=[ns_urlencode $term]\">$term</a>\n"

    set old_first_char $first_char
    incr count
}

ns_write "</ul>

<p>
<a href=\"term-new.tcl\">Add a Term</a>

</blockquote>

[ad_admin_footer]
"
