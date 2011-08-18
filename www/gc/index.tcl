# $Id: index.tcl,v 3.1 2000/03/10 23:58:27 curtisg Exp $
set simple_headline "<h2>Welcome to [gc_system_name] </h2>

[ad_context_bar_ws_or_index [gc_system_name]]
"

if ![empty_string_p [ad_parameter IndexPageDecorationTop gc]] {
    set full_headline "<table cellspacing=10><tr><td>[ad_parameter IndexPageDecorationTop gc]<td>$simple_headline</tr></table>"
} else {
    set full_headline $simple_headline
}


append html "[gc_header [gc_system_name]]

$full_headline

<hr>

[ad_parameter IndexPageDecorationSide gc]

<ul>

"

set db [gc_db_gethandle]

set selection [ns_db select $db "select * from ad_domains 
where (active_p = 't' or active_p is null)
order by upper(domain)"]

set counter 0
set items ""
while {[ns_db getrow $db $selection]} {
    incr counter
    set_variables_after_query
    append items "<li><a href=\"domain-top.tcl?domain_id=$domain_id\">$full_noun</a>\n"
}

if { $counter == 0 } {
    append items "no domains found; looks like someone hasn't really set this up yet"
}

append html "$items
</ul>

<br clear=right>

[gc_footer [ad_system_owner]]
"
ns_return 200 text/html $html
