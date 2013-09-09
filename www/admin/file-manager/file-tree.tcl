# /www/admin/file-manager/file-tree.tcl

ad_page_contract {

    Display the server's file tree (except for ignored files)

    @author  ron@arsdigita.com
    @author  karlg@arsdigita.com
    @created Tue May 30 22:15:07 2000
    @cvs-id  file-tree.tcl,v 1.4.2.5 2000/09/22 01:35:10 kevin Exp
}

proc get_dirs { path } {

  set files [list]

  catch {
    foreach file [lsort [glob "$path/*"]] {
	if [file isdirectory $file] { 
	    lappend files $file 
	}
    }
  } errmsg

  return $files
}

proc print_dir { path } {

    upvar output output depth depth

    set depth  [expr $depth + 1]    
    set files  [get_dirs $path]
    set len    [llength $files]
    set ignore [split [ad_parameter Ignore file-manager "admin"] ","]
    set spacer ""

    for { set i 0 } { $i < $depth } { incr i } {
	append spacer "<td width=1 nowrap></td>"
    }

    for { set i 0 } { $i < $len } { incr i } {

	set file [lindex $files $i]
	set tail [file tail $file]

	if {[lsearch $ignore $tail] != -1} {
	    continue
	}
	
	append output "
	<tr>
	$spacer
	<td colspan=4>
	<a href=file-list?path=$file target=list>$tail</a>
	</td>
	</tr>"
	print_dir $file 
	
	append output "\n"
    }
    
  set depth [expr $depth - 1]
}

set root  [ns_info pageroot]
set depth 0
set output "
<html>
<body bgcolor=white>
<h3><a target=_top href=\"\">[file tail $root]</a></h3>
<p>
<table>
"

foreach dir [fm_managed_directories] {
    set path [file join $root $dir]

    append output "
    <tr>
    <td colspan=4>
    <a href=file-list?path=$path target=list>[file tail $path]</a>
    </td>
    </tr>"

    print_dir $path

    append output "\n"
}

append output "
</table>
<form method=post action=file-tree>
<input type=submit value=Refresh>
</form>
</body>
</html>"

doc_return  200 text/html $output

