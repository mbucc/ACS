# /www/admin/monitoring/filters.tcl

ad_page_contract {
    Displays a list of filter procs present on the web server.

    @author        Jon Salz <jsalz@mit.edu>
    @cvs-id        filters.tcl,v 3.4.2.4 2000/09/22 01:35:33 kevin Exp
} {
    {match_method "GET"}
    {match_path "(any)"}
}

if { $match_path == "(any)" } {
} else {
    if { ![regexp {^/} $match_path] } {
	set match_path "/$match_path"
    }
}


set page_content "[ad_admin_header "Filters"]

<form>

<h2>Filters on [ad_system_name]</h2>

[ad_admin_context_bar [list "" "Monitoring"] "Filters"]
<hr>

Showing <select name=match_method onChange=\"form.submit()\">
[ad_generic_optionlist [list "all" "GET" "HEAD" "POST"] [list "" "GET" "HEAD" "POST"] $match_method]
</select>

filters matching path:

<input name=match_path value=\"$match_path\"> <input type=submit value=\"Show\">
[ad_decode [expr { $match_path == "(any)" }] 0 "<input type=button onClick=\"form.match_path.value='(any)';form.submit()\" value=\"Show All\">" ""]
<table>
<tr>
<th align=left bgcolor=#C0C0C0>Priority</th>
<th align=left bgcolor=#C0C0C0>Kind</th>
<th align=left bgcolor=#C0C0C0>Method</th>
<th align=left bgcolor=#C0C0C0>Path</th>
<th align=left bgcolor=#C0C0C0>Proc</th>
<th align=left bgcolor=#C0C0C0>Defined in File</th>
<th align=left bgcolor=#C0C0C0>Args</th>
<th align=center bgcolor=#C0C0C0>Debug?</th>
<th align=center bgcolor=#C0C0C0>Crit.?</th>
</tr>
"


if { $match_method == "" } {
    set match_method [list GET HEAD POST]
}

set counter 0
set bgcolors { white #E0E0E0 }
foreach k { preauth postauth trace } {
    foreach meth $match_method {
	foreach f [nsv_get rp_filters "$meth,$k"] {
	    set bgcolor [lindex $bgcolors [expr { $counter % [llength $bgcolors] }]]
	    incr counter
	    
	    set priority [lindex $f 0]
	    set kind [lindex $f 1]
	    set method [lindex $f 2]
	    set path [lindex $f 3]
	    set proc [lindex $f 4]
	    set args [lindex $f 5]
	    if { $args == "" } {
		set args "&nbsp;"
	    }
	    set debug [ad_decode [lindex $f 6] "t" "Yes" "No"]
	    set critical [ad_decode [lindex $f 7] "t" "Yes" "No"]
	    set description [lindex $f 8]
	    set file [file tail [lindex $f 9]]
	    if { $kind != $k || ($match_path != "(any)" && ![string match $path $match_path]) } {
		continue
	    }
	    append page_content "<tr>"
	    foreach name { priority kind method path proc file args debug critical } {
		append page_content "<td bgcolor=$bgcolor>[set $name]</td>"
	    }
	    append page_content "</tr>\n"
	}
    }
}

append page_content "</table>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
