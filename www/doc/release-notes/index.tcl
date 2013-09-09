# /www/doc/release-notes/index.tcl

ad_page_contract {

    A simple script to glob the files in this directory and create an
    index page with appropriate links.

    @author  Ron Henderson (ron@arsdigita.com)
    @created 2000-07-24
    @cvs-id  index.tcl,v 1.1.2.2 2000/09/22 01:37:23 kevin Exp

}

set page_title   "ACS Release Notes"
set page_content "
[ad_header $page_title]

<h2>$page_title</h2>

part of <a href=/doc/>ACS Documentation</a>

<hr>

<p>This directory contains release notes for the ArsDigita Community
System:</p>
"

set files [glob [acs_root_dir]/www/doc/release-notes/*.html]
set notes [list]

foreach path [lsort -decreasing $files] {
    set tail [file tail $path]

    # skip any file not of the form (#.)+.html
    if ![regexp {^([0-9.]+)html} $tail match version] {
	continue
    }
    
    # all release notes should be of the form (#.+)html
    set version [string range $version 0 [expr [string length $version]-2]]
    lappend notes "<a href=$tail>ACS $version</a>\n"
}

append page_content "
<p>Current release:</p>
<ul><li>[lindex $notes 0]</ul>

<p>Older releases:</p>

<ul>
<li> [join [lrange $notes 1 end] "\n<li>"]
</ul>

[ad_footer]
"

doc_return 200 text/html $page_content

