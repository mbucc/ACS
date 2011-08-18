# $Id: proc-one.tcl,v 3.0 2000/02/06 03:36:59 ron Exp $
# print out documentation for one procedure
# created by philg@mit.edu
# March 27th, 1999. teadams@mit.edu modified to list default arguments
# 19981223 added ad_proc arg usage messages. jcd

set_form_variables

# proc_name

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

ReturnHeaders

ns_write "
[ad_header "$proc_name"]

<h2>$proc_name</h2>

one of <a href=\"procs.tcl\">$backlink_anchor</a> in this
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
