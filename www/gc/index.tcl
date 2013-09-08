# /www/gc/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.3.2.4 2000/09/22 01:37:54 kevin Exp
}

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

set sql "select * from ad_domains 
where (active_p = 't' or active_p is null)
order by upper(domain)"

set counter 0
set items ""
db_foreach gc_index_domain_list $sql {
    incr counter
    append items "<li><a href=\"domain-top?domain_id=$domain_id\">$full_noun</a>\n"
}

if { $counter == 0 } {
    append items "no domains found; looks like someone hasn't really set this up yet"
}

append html "$items
</ul>

<br clear=right>

[gc_footer [ad_system_owner]]
"

doc_return  200 text/html $html
