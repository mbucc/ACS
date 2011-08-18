# $Id: partner-url.tcl,v 3.0 2000/02/06 03:26:51 ron Exp $
proc ad_partner_proc_html { db url_id proc_type} {
    set selection [ns_db select $db "select proc_name, proc_id
                                     from ad_partner_${proc_type}_procs
                                     where url_id='$url_id'"]
 
    set str ""
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append str "  <LI>$proc_name | <A HREF=\"/doc/proc-one.tcl?proc_name=[ns_urlencode $proc_name]\">view</A> | <A HREF=\"partner-proc-ae.tcl?[export_url_vars proc_id]\">edit</a> | <A HREF=\"partner-proc-delete.tcl?[export_url_vars proc_id]\">delete</a>\n"
    } 

    if { [empty_string_p $str] } { 
	set str "<UL>  <LI> No procedures have been registered.</UL>"
    } else {
	set str "<OL>$str</OL>"
    }

    return "
    <b>$proc_type calling order</b>
    $str
<UL>  
<LI><A HREF=\"partner-proc-ae.tcl?[export_url_vars partner_id proc_type url_id]\">Add a $proc_type procedure</A>
</UL>
"
}


set_the_usual_form_variables
# url_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select partner_id, url_stub 
                               from ad_partner_url
                               where url_id=$url_id"]

set_variables_after_query

set selection [ns_db 1row $db \
	"select partner_name
           from ad_partner 
          where partner_id='$partner_id'"]
set_variables_after_query

set page_title "$partner_name ($url_stub)"
set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] [list "partner-view.tcl?[export_url_vars partner_id]" "One partner"] "URL"]

set page_body "
[ad_partner_proc_html $db $url_id header]
[ad_partner_proc_html $db $url_id footer]

<b>preview</b>
<ul>
  <li> <a href=\"partner-url-sample.tcl?[export_url_vars url_id]\">Preview</a> what this template looks like
</ul>
"

ns_return 200 text/html [ad_partner_return_template]