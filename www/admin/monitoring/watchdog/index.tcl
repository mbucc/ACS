# $Id: index.tcl,v 3.0 2000/02/06 03:25:46 ron Exp $
set_form_variables 0
# kbytes

if {![info exists kbytes] || [empty_string_p $kbytes]} {
    if ![info exists num_minutes] {
	set kbytes 200
    } else {
	set kbytes ""
    }
}

if ![empty_string_p $kbytes] {
    set bytes [expr $kbytes * 1000]
} else {
    set bytes ""
}

if {![info exists num_minutes]} {
    set num_minutes ""
}

ns_return 200 text/html "[ad_admin_header "WatchDog"]

<h2>WatchDog</h2>

[ad_admin_context_bar [list "/admin/monitoring/index.tcl" "Monitoring"] "WatchDog"]

<hr>

<FORM ACTION=index.tcl>    
Errors from the last <INPUT NAME=kbytes SIZE=4 [export_form_value kbytes]> Kbytes of error log. 
<INPUT TYPE=SUBMIT VALUE=\"Search again\">
</FORM>

<FORM ACTION=index.tcl>
Errors from the last <INPUT NAME=num_minutes SIZE=4 [export_form_value num_minutes]> minutes of error log. <INPUT TYPE=SUBMIT VALUE=\"Search again\">
</FORM>

<PRE>
[ns_quotehtml [wd_errors "$num_minutes" "$bytes"]]
</PRE>

[ad_admin_footer]
"