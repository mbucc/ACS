# $Id: directory-view-with-contents.tcl,v 3.0 2000/02/06 03:16:35 ron Exp $
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

[ad_admin_context_bar [list "index.tcl" "Documentation"] "Full Contents"]
<hr>
"
set directory_text ""

foreach f [glob -nocomplain $directory/*] {
    if { [string match "*CVS" $f ] == 0 && [string match "*~*" $f] == 0 && [string match "*#*" $f] == 0 } {
	# this is not a CVS directory or a backup file
	if {[file isdirectory $f]} {
	    append directory_text "<li><a href=\"directory-view-with-contents.tcl?directory=[ns_urlencode $f]&text_p=t\">$f</a>" 
	} else {
	    set last_accessed [ns_fmttime [file atime $f]   "%m/%d/%Y %T"]
	    set last_modified [ns_fmttime [file mtime $f]  "%m/%d/%Y %T"]
	    set size [file size $f]
	    set stream [open $f r]

	    regsub [ns_info pageroot] $f "" f
	    regsub {\.\./} $f "" f

	    ns_write "<h2>$f</h2>Last modified: $last_modified  | Last accessed: $last_accessed | Size: $size<p>
<p>"
            if {$text_p == "t"} {
		ns_write "<pre>[ns_quotehtml [read $stream]]</pre>"
	    } else {
		ns_write "[read $stream]"
	    }
             
	    close $stream
	}
    }
}
ns_write "
<ul>
$directory_text
</ul>
[ad_admin_footer]"

