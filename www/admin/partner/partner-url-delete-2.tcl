# $Id: partner-url-delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:13 carsten Exp $
set_the_usual_form_variables
# url_id, operation

set db [ns_db gethandle]
set partner_id [database_to_tcl_string $db \
	"select partner_id
  	   from ad_partner_url
          where url_id='$QQurl_id'"]

if { [string compare $operation "Yes"] == 0 } {
    ns_db dml $db "begin transaction"
    ns_db dml $db "delete from ad_partner_procs where url_id='$url_id'"
    ns_db dml $db "delete from ad_partner_url where url_id='$url_id'"
    ns_db dml $db "end transaction"
}

ad_returnredirect partner-view.tcl?[export_url_vars partner_id]