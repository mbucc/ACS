# $Id: partner-proc-delete-2.tcl,v 3.0.4.1 2000/04/28 15:09:13 carsten Exp $
set_the_usual_form_variables
# proc_id, operation

set db [ns_db gethandle]
set url_id [database_to_tcl_string $db "select url_id
  		                        from ad_partner_procs
                                        where proc_id='$QQproc_id'"]

if { [string compare $operation "Yes"] == 0 } {
    ns_db dml $db "delete from ad_partner_procs where proc_id='$proc_id'"
}

ad_returnredirect partner-url.tcl?[export_url_vars url_id]