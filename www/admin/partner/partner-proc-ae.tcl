# /www/admin/partner/partner-proc-ae.tcl

ad_page_contract {
    Assigns a procedure name to a url/partner combination

    @param url_id If specified, we're adding a new proc to an existing url
    @param proc_type one of header/footer
    @param proc_id If specified, we edit the url for the specified row
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-proc-ae.tcl,v 3.2.2.5 2000/09/22 01:35:45 kevin Exp
} {
    { url_id:naturalnum "" }
    { proc_type:trim "" }
    { proc_id:naturalnum "" }
    { return_url "" }
}


if  { ![empty_string_p $proc_id] } {
    db_1row partner_proc_ae \
	    "select proc_name, url_id, trim(proc_type) as proc_type, call_number
  	       from ad_partner_procs
              where proc_id=:proc_id"

    set page_title "Edit $proc_type procedure"

} else {
    set page_title "Add $proc_type procedure"
    set proc_id [db_nextval ad_partner_procs_proc_id_seq]

    set call_number [db_string partner_max_call_number \
	    "select max(call_number)+1
	       from ad_partner_procs 
	      where url_id=:url_id
                and trim(proc_type)=trim(:proc_type)"]

    if { [empty_string_p $call_number] } {
	set call_number 1
    }
}

db_1row partner_id_from_url \
	"select partner_id from ad_partner_url where url_id=:url_id"

set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] [list "partner-url?[export_url_vars url_id]" URL] "$page_title"]

set page_body "
<form method=post action=\"partner-proc-ae-2\">
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

# ad_partner_return_template releases the db handles

doc_return  200 text/html [ad_partner_return_template]
