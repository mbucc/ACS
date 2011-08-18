# $Id: partner-url-ae.tcl,v 3.0 2000/02/06 03:26:44 ron Exp $
set_the_usual_form_variables
# partner_id if we're adding
# url_id if we're editing


set db [ns_db gethandle]

if  {[info exists url_id] && ![empty_string_p $url_id]} {
    set selection [ns_db 1row $db "select url_stub, partner_id
  		                 from ad_partner_url 
                                 where url_id='$QQurl_id'"]
    set_variables_after_query
    set page_title "Edit URL"
} else {
    set url_id [database_to_tcl_string $db "select ad_partner_url_url_id_seq.nextVal from dual"]
    set page_title "Add URL"
    set url_stub "/"
}

set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] [list "partner-view.tcl?[export_url_vars partner_id]" "One partner"] "$page_title"]

set page_body "
<form method=post action=\"partner-url-ae-2.tcl\">
[export_form_vars partner_id url_id return_url]

<table>
<tr>
  <td>URL Stub (with leading slash):</td>
  <td><input type=text size=40 maxlength=50 name=\"url_stub\" [export_form_value url_stub]></td>
</tr>
</table>

<center><input type=submit value=\" $page_title \"></center>
</form>
"

ns_return 200 text/html [ad_partner_return_template]
