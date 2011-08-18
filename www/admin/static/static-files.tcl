# $Id: static-files.tcl,v 3.0 2000/02/06 03:30:27 ron Exp $
set db [ns_db gethandle]

set selection [ns_db select $db "select url_stub from static_pages order by url_stub"]


ReturnHeaders

ns_write "<HTML>
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

while { [ns_db getrow $db $selection] } {
    if { $dir_counter == 30 } {
	break
    }
    set_variables_after_query
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
	    
	    ns_write "var $varname = new List(false, width, height);\n";
	    ns_write "${varname}.setFont(\"<FONT FACE='Arial,Helvetica' SIZE=-1'><B>\",\"</B></FONT>\");\n"

	    set parentvar [ns_set get $seen $curpath]
	    ns_write "${parentvar}.addList($varname, \"$dir\");\n";
	}
	set curpath $newpath
    }

    set file [lindex $path_elements $n]
    set parentvar [ns_set get $seen $curpath]
    ns_write "${parentvar}.addItem(\"$file\");\n"
}

ns_write "root.build(width/8,40);
\}
</SCRIPT>
<STYLE TYPE=\"text/css\">
\#spacer \{ position: absolute; height: 5000; \}
</STYLE>
<STYLE TYPE=\"text/css\">
"
for { set i 0 } { $i < $dir_counter } { incr i } {
    ns_write "\#lItem$i { position:absolute; }\n";
}

ns_write "
</STYLE>
</HEAD>
<BODY onLoad=\"init();\">
<DIV ID=\"spacer\"></DIV>
"


for { set i 0 } { $i < $dir_counter } { incr i } {
    ns_write "<DIV ID=\"lItem$i\" NAME=\"lItem$i\"></DIV>\n"
}

ns_write "</BODY>
</HTML>
"