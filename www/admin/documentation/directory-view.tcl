# $Id: directory-view.tcl,v 3.0 2000/02/06 03:16:36 ron Exp $
set_the_usual_form_variables

# directory, maybe text_p

# if text_p = t, we are looking at pure text

if ![info exists text_p] {
    set text_p "f"
}


set exception_count 0
set exception_text ""

if {![info exists directory] || [empty_string_p $directory]} {
    incr exception_count
    append exception_text "<li>Please enter a directory."
}
	        
if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders

ns_write "[ad_header "Contents of $directory"]

<h2>Contents of $directory</h2>

[ad_admin_context_bar [list "index.tcl" "Documentation"] "Browse"]
<hr>
<ul>
"
set file_text ""
set directory_text ""

foreach f [glob -nocomplain $directory/*] {
    if { [string match "*CVS" $f ] == 0 && [string match "*~*" $f] == 0 && [string match "*#*" $f] == 0 } {
	# this is not a CVS directory or a backup file
	if {[file isdirectory $f]} {
	    append directory_text "<li><a href=\"directory-view.tcl?directory=[ns_urlencode $f]\">$f</a> (directory)" 
	} else {
	    set last_accessed [ns_fmttime [file atime $f]   "%m/%d/%Y %T"]
	    set last_modified [ns_fmttime [file mtime $f]  "%m/%d/%Y %T"]
	    set size [file size $f]
	    set stream [open $f r]

	    regsub [ns_info pageroot] $f "" f
	    set comments ""
	    set line_list [split [read $stream] "\n"]

	    set group_together 0

	    foreach line $line_list {
		set line [string trim $line]
		if {[regexp "^#" $line dummy]} {
		    append comments "$line<br>"
		    set group_together 1
		} elseif {$group_together == 1}  {
		    append comments "<p>"
		    set group_together 0
		}
	    }

	    if {$text_p == "t"} {
		append file_text "<li><a href=\"/doc/sql/display-sql.tcl?url=[ns_urlencode $f]\">$f</a><br> Last modified: $last_modified  | Last accessed: $last_accessed | Size: $size<p>
$comments
<p>
" 
           } else {
	       append file_text "<li><a href=\"$f\">$f</a><br> Last modified: $last_modified  | Last accessed: $last_accessed | Size: $size<p>
$comments
<p>
" 
	   } 

            close $stream
            set comments ""
	}
	
    }
}
ns_write "
$file_text
<p>
$directory_text
</ul>
[ad_admin_footer]"

