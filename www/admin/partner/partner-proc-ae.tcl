# $Id: partner-proc-ae.tcl,v 3.0 2000/02/06 03:26:39 ron Exp $
set_the_usual_form_variables
# url_id, proc_type if we're adding (proc_type is either header or footer)
# proc_id if we're editing

set db [ns_db gethandle]

if  {[info exists proc_id] && ![empty_string_p $proc_id]} {
    set selection [ns_db 1row $db "select proc_name, url_id, proc_type, call_number
  		                   from ad_partner_procs
                                   where proc_id='$QQproc_id'"]
    set_variables_after_query
    set proc_type [string trim $proc_type]
    set page_title "Edit $proc_type procedure"
} else {
    set proc_id [database_to_tcl_string $db "select ad_partner_procs_proc_id_seq.nextVal from dual"]
    set page_title "Add $proc_type procedure"
    set call_number [database_to_tcl_string_or_null $db \
	    "select max(call_number)+1
               from ad_partner_procs 
              where url_id='$QQurl_id'
                and proc_type='$QQproc_type'"]
    if {[empty_string_p $call_number]} {
	set call_number 1
    }
}

set partner_id [database_to_tcl_string $db \
	"select partner_id from ad_partner_url where url_id='$url_id'"]

ns_db releasehandle $db

set context_bar [ad_context_bar_ws [list "index.tcl" "Partner manager"] [list "partner-view.tcl?[export_url_vars partner_id]" "One partner"] [list "partner-url.tcl?[export_url_vars url_id]" URL] "$page_title"]

set page_body "
<form method=post action=\"partner-proc-ae-2.tcl\">
[export_form_vars url_id proc_id return_url proc_type call_number]

<table>
<tr>
  <td>Procedure name:</td>
  <td><input type=text size=40 maxlength=40 name=\"proc_name\" [export_form_value proc_name]></td>
</tr>
</table>

<center><input type=submit value=\" $page_title \"></center>
</form>
"

ns_return 200 text/html [ad_partner_return_template]
