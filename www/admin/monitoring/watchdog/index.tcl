# /admin/monitoring/watchdog/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.1.6.8 2000/09/22 01:35:40 kevin Exp
} {
    kbytes:integer,optional
    num_minutes:naturalnum,optional
}

if { [info exists num_minutes] && ![empty_string_p $num_minutes] } {
    set kbytes ""
    set bytes ""
} else {
    set num_minutes ""
    if { ![info exists kbytes] || [empty_string_p $kbytes] } {
	set kbytes 200
    }
    set bytes [expr $kbytes * 1000]
}

doc_return  200 text/html "[ad_admin_header "WatchDog"]

<h2>WatchDog</h2>

[ad_admin_context_bar [list "/admin/monitoring/index.tcl" "Monitoring"] "WatchDog"]

<hr>

<FORM ACTION=index>    
Errors from the last <INPUT NAME=kbytes SIZE=4 [export_form_value kbytes]> Kbytes of error log. 
<INPUT TYPE=SUBMIT VALUE=\"Search again\">
</FORM>

<FORM ACTION=index>
Errors from the last <INPUT NAME=num_minutes SIZE=4 [export_form_value num_minutes]> minutes of error log. <INPUT TYPE=SUBMIT VALUE=\"Search again\">
</FORM>

<PRE>
[ns_quotehtml [wd_errors "$num_minutes" "$bytes"]]
</PRE>

[ad_admin_footer]
"