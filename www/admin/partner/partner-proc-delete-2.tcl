# /www/admin/partner/partner-proc-delete-2

ad_page_contract {
    Deletes (if operation set to Yes) the specified proc name

    @param proc_id integer ID of the procedure we're removing
    @param operation String that must be set to "Yes" to do the delete

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-proc-delete-2.tcl,v 3.2.2.2 2000/07/21 03:57:49 ron Exp
} {
    proc_id:integer,notnull
    { operation "No" }
}


set url_id [db_string partner_url_id_from_partner_procs \
	"select url_id
  	   from ad_partner_procs
          where proc_id=:proc_id"]

if { [string compare $operation "Yes"] == 0 } {
    db_dml partner_proc_id_delete "delete from ad_partner_procs where proc_id=:proc_id"
}

db_release_unused_handles
ad_returnredirect partner-url?[export_url_vars url_id]