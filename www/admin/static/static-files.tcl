# /www/admin/static/static-files.tcl

ad_page_contract {

    @author mbryzek@arsdigita.com
    @creation-date Jul 8 2000

    @cvs-id static-files.tcl,v 3.1.2.5 2000/09/22 01:36:09 kevin Exp
} {

}


set sql_query "select url_stub from static_pages order by url_stub"


set page_body "<HTML>
<HEAD>
<SCRIPT LANGUAGE=\"JavaScript1.2\" SRC=\"resize.js\"></SCRIPT>
<SCRIPT LANGUAGE=\"JavaScript1.2\" SRC=\"list.js\"></SCRIPT>
<SCRIPT LANGUAGE=\"JavaScript\">
function init() \{
  if(parseInt(navigator.appVersion) < 4) \{
    alert(\"Sorry, a 4.0+ browser is required to view this demo.\");
    return;
  \}
  var width, height = 22;
  if(isNav4) width = 3*window.innerWidth/4;
  else width = 3*document.body.clientWidth/4;
  var bgColor = \"#CCCCCC\";
  var root = new List(true, width, height);
  root.setFont(\"<FONT FACE='Arial,Helvetica' SIZE=-1'><B>\",\"</B></FONT>\");
"

set seen [ns_set new]
ns_set put $seen "" "root"

set dir_counter 0
set file_counter 0

db_foreach static_loop $sql_query {
    if { $dir_counter == 30 } {
	break
    }

    set path_elements [split $url_stub "/"]

    # For each of the directory elements, if we haven't seen it before,
    # create a directory for it.
    set curpath ""
    set n [expr [llength $path_elements] - 1]
    for { set i 1 } { $i < $n } { incr i } {
	set dir [lindex $path_elements $i]
	set newpath "$curpath/$dir"
	if { [ns_set get $seen $newpath] == "" } {
	    set varname "dir[incr dir_counter]"
	    ns_set put $seen $newpath $varname
	    
	    append page_body "var $varname = new List(false, width, height);\n";
	    append page_body "${varname}.setFont(\"<FONT FACE='Arial,Helvetica' SIZE=-1'><B>\",\"</B></FONT>\");\n"

	    set parentvar [ns_set get $seen $curpath]
	    append page_body "${parentvar}.addList($varname, \"$dir\");\n";
	}
	set curpath $newpath
    }

    set file [lindex $path_elements $n]
    set parentvar [ns_set get $seen $curpath]
    append page_body "${parentvar}.addItem(\"$file\");\n"
}

append page_body "root.build(width/8,40);
\}
</SCRIPT>
<STYLE TYPE=\"text/css\">
\#spacer \{ position: absolute; height: 5000; \}
</STYLE>
<STYLE TYPE=\"text/css\">
"
for { set i 0 } { $i < $dir_counter } { incr i } {
    append page_body "\#lItem$i { position:absolute; }\n";
}

append page_body "
</STYLE>
</HEAD>
<BODY onLoad=\"init();\">
<DIV ID=\"spacer\"></DIV>
"

for { set i 0 } { $i < $dir_counter } { incr i } {
    append page_body "<DIV ID=\"lItem$i\" NAME=\"lItem$i\"></DIV>\n"
}

append page_body "</BODY>
</HTML>
"



doc_return  200 text/html $page_body






















