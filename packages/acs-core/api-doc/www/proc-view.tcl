ad_page_contract {
    Display information about one procedure.
    
    @cvs-id proc-view.tcl,v 1.1.4.6 2000/07/21 03:55:41 ron Exp
} {
    proc
    source_p:optional,integer,trim
}

doc_body_append "
[ad_header $proc]
<h2>$proc</h2>

[ad_context_bar_ws_or_index [list "" "API Browser"] $proc]

<hr>

"

set default_source_p [ad_get_client_property -default 0 acs-core api_doc_source_p]


if { ![info exists source_p] } {
    set source_p $default_source_p
}

if { ![nsv_exists api_proc_doc $proc] } {
    doc_body_append "This proc is not defined with ad_proc or proc_doc"
} else {
    if { $source_p } {
	lappend links "<a href=\"proc-view?[export_ns_set_vars url {source_p}]&source_p=0\">hide source</a>"
    } else {
	lappend links "<a href=\"proc-view?[export_ns_set_vars url {source_p}]&source_p=1\">show source</a>"
    }


    if { $source_p != $default_source_p } {
	lappend links "<a href=\"set-default?[export_url_vars source_p]&return_url=[ns_urlencode [ns_conn url]?[export_url_vars proc]]\">make this the default</a>"
    } 

    if { $source_p } {
	doc_body_append "<table width=100%><tr><td bgcolor=#e4e4e4>\n[api_proc_documentation -script -source $proc]\n</td></tr></table>"
    } else {
	doc_body_append "<table width=100%><tr><td bgcolor=#e4e4e4>\n[api_proc_documentation -script $proc]\n</td></tr></table>"
    }
    doc_body_append "\[ [join $links " | "] \]"
}

doc_body_append "

<p>

<form action=proc-view method=get>
Show another procedure: <input type=text name=proc> <input type=submit value=\"Go\">
</form>

[ad_footer]
"

