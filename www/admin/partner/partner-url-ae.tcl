# /www/admin/partner/partner-url-ae.tcl

ad_page_contract {
    Form to add/edit a new url

    @param partner_id integer specified only when adding
    @param url_id Integer specified only when editing
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-url-ae.tcl,v 3.2.2.3 2000/09/22 01:35:45 kevin Exp
} {
    { partner_id:integer "" }
    { url_id:integer "" }
    { return_url "" }
}

if  {![empty_string_p $url_id]} {
    
    db_1row partner_stub_partner_id \
	    "select url_stub, partner_id
               from ad_partner_url 
              where url_id=:url_id"
    set page_title "Edit URL"
    set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] [list partner-url?[export_url_vars url_id] "One URL"] "$page_title"]

} else {

    set url_id [db_nextval "ad_partner_url_url_id_seq"]
    set page_title "Add URL"
    set url_stub "/"
    set context_bar [ad_context_bar_ws [list "index" "Partner manager"] [list "partner-view?[export_url_vars partner_id]" "One partner"] "$page_title"]
}

set page_body "
<form method=post action=\"partner-url-ae-2\">
[export_form_vars partner_id return_url]
[export_form_vars -sign url_id]
<table>
<tr>
  <td>URL Stub (with leading slash):</td>
  <td><input type=text size=40 maxlength=50 name=\"url_stub\" [export_form_value url_stub]></td>
</tr>
</table>

<center><input type=submit value=\" $page_title \"></center>
</form>
"

# ad_partner_return_template releases the db handles
doc_return  200 text/html [ad_partner_return_template]
