# /admin/reload/index.tcl

ad_page_contract {
    Reload - a utility to reload Tcl files without restarting the server.

    @author Mark Dettinger (mdettinger@arsdigita.com)
    @creation-date 2 August 2000
    @cvs-id index.tcl,v 1.1.2.2 2000/09/22 01:36:02 kevin Exp
} {
}

set files [exec /webroot/web/acs-staging/bin/ls [ad_parameter PathToACS]/tcl]
set files [filter [lambda {s} {regexp ".tcl$" $s}] $files]
set files [map [lambda {s} {return "<a href=\"source-file?file=$s\">$s</a><br>"}] $files]
set num_columns 4
set num_files [llength $files]
set num_rows [expr ($num_files+$num_columns-1)/$num_columns]

for {set i 0} {$i<$num_rows} {incr i} {
    append html <tr>
    for {set j 0} {$j<$num_columns} {incr j} {
	if [expr $j*$num_rows+$i<$num_files] {
	    append html <td>[lindex $files [expr $j*$num_rows+$i]]</td>\n
	}
    }
    append html "</tr>"
}

doc_return 200 text/html "
<html>
<body bgcolor=\"#000000\" text=\"#ffffff\" link=\"#ffffff\" vlink=\"#8888ff\">
<img align=right src=\"reload.jpg\">
<h2>Reload Tcl Library Files</h2>
<table>
$html
</table>
<p>
<i>Click on a link and the file will be sourced.</i>
<p>
</body>
</html>
"


