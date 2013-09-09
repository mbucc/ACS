ad_page_contract {
    @param directory
    @param text_p

    @author ?
    @creation-date ?
    @cvs-id directory-view-with-contents.tcl,v 3.1.6.5 2000/09/22 01:34:42 kevin Exp
} {
    directory:notnull
    text_p:optional
}


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


set page_content "[ad_header "Contents of $directory"]

<h2>Contents of $directory</h2>

[ad_admin_context_bar [list "index.tcl" "Documentation"] "Full Contents"]
<hr>
"
set directory_text ""

foreach f [glob -nocomplain $directory/*] {
    if { [string match "*CVS" $f ] == 0 && [string match "*~*" $f] == 0 && [string match "*#*" $f] == 0 } {
	# this is not a CVS directory or a backup file
	if {[file isdirectory $f]} {
	    append directory_text "<li><a href=\"directory-view-with-contents?directory=[ns_urlencode $f]&text_p=t\">$f</a>" 
	} else {
	    set last_accessed [ns_fmttime [file atime $f]   "%m/%d/%Y %T"]
	    set last_modified [ns_fmttime [file mtime $f]  "%m/%d/%Y %T"]
	    set size [file size $f]
	    set stream [open $f r]

	    regsub [ns_info pageroot] $f "" f
	    regsub {\.\./} $f "" f

	    append page_content "<h2>$f</h2>Last modified: $last_modified  | Last accessed: $last_accessed | Size: $size<p>
<p>"
            if {$text_p == "t"} {
		append page_content "<pre>[ns_quotehtml [read $stream]]</pre>"
	    } else {
		append page_content "[read $stream]"
	    }
             
	    close $stream
	}
    }
}
append page_content "
<ul>
$directory_text
</ul>
[ad_admin_footer]"



doc_return  200 text/html $page_content

