# www/admin/spam/view-spam-file.tcl

ad_page_contract {

 View a file in the dropzone.

     @param filename name of file to view
    @author hqm@arsdigita.com
    @cvs-id view-spam-file.tcl,v 3.4.2.4 2000/09/22 01:36:07 kevin Exp
} {
  filename

 }



set clean_filename [spam_sanitize_filename $filename]
set path [spam_file_location $clean_filename]

append pagebody "[ad_admin_header "View Drop Zone Spam File $clean_filename"]

<h2>View Drop Zone Spam File: <tt>$clean_filename</tt></h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "View Drop Zone File"]

<hr>
<p>
View spam file $path
<p>
<font size=+1><tt><a href=delete-spam-file?filename=[ns_urlencode $filename]>Delete?</a></tt>
<p>
"

append pagebody "
Raw Text From File: $path"

if { ![file readable $path] || ![file isfile $path] } {
    append pagebody " <font color=red>File not found or not readable!</font>"
} else {
    set fd [open $path]
    set content [read $fd]
    close $fd
    set quoted_content [ns_quotehtml $content]
    append pagebody "<pre>\n$quoted_content\n</pre>"
}

append pagebody "<hr>"

if {[string match "*-html*" $path] || [string match "*-aol*" $path]} {
    append pagebody "<h3>How it appears in HTML</h3>"
    append pagebody $content
}

append pagebody "
<hr>
<p>
[ad_admin_footer]"


doc_return  200 text/html $pagebody

