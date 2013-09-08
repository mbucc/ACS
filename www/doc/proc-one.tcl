# /www/doc/proc-one.tcl

ad_page_contract {
    Print out documentation for one procedure.
    
    @param proc_name The name of the procedure.

    @author philg@mit.edu
    @author teadamas@mit.edu
    @author jcd

    @creation-date ?
    @cvs-id proc-one.tcl,v 3.1.6.4 2000/09/22 01:37:22 kevin Exp
} {
    proc_name:notnull
}

ad_returnredirect /api-doc/proc-view?proc=[ns_urlencode $proc_name]
return

# -----------------------------------------------------------------------------
# The rest of this page has been superceded by the api-doc package,
# but we'll leave it in place until doc/proc* is fully removed. If you
# get an error from proc-doc, make sure the latest version of acs-core
# is enabled.  
# -----------------------------------------------------------------------------

set document ""

if [nsv_exists proc_doc $proc_name] {
    set backlink_anchor "the documented procedures"
    set what_it_does_section "
 What it does:<br>
 <blockquote>
 [nsv_get proc_doc $proc_name]
 </blockquote>

 Defined in: <strong>[proc_source_file_full_path $proc_name]</strong>
 </code>

<p>
"

} else {
    set what_it_does_section ""
    set backlink_anchor "the defined (but not documented) Tcl procedures"
}

append Usage "<b>$proc_name</b> <i>"

if {[nsv_exists ad_proc_args $proc_name]} { 
    append Usage "[ns_quotehtml [nsv_get ad_proc_args $proc_name]] "
} else { 
    foreach arg [info args $proc_name] {
        if [info default $proc_name $arg default] {
            append Usage "&nbsp;&nbsp;{&nbsp;$arg&nbsp;\"[ns_quotehtml $default]\"&nbsp;} "
        } else {
            append Usage "&nbsp;&nbsp;$arg "
        }
    }
}

append Usage "</i>\n"

append document "
[ad_header "$proc_name"]

<h2>$proc_name</h2>

one of <a href=\"procs\">$backlink_anchor</a> in this
installation of the ACS

<hr>
Usage:
<blockquote>
$Usage
</blockquote>
$what_it_does_section

Source code:
<pre>
[ns_quotehtml [info body $proc_name]]
</pre>

[ad_admin_footer]
"
doc_return 200 text/html $document