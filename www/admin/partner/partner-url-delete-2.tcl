# /www/admin/partner/partner-url-delete-2.tcl

ad_page_contract {
    Deletes specified url 

    @param url_id integer ID of the URL we are deleting
    @param operation String that must be "Yes" for delete to occur

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-url-delete-2.tcl,v 3.2.2.2 2000/07/21 03:57:50 ron Exp
} {
    url_id:integer,notnull
    { operation "No" }
}


set partner_id [db_string partner_id_from_url \
	"select partner_id
  	   from ad_partner_url
          where url_id=:url_id"]

if { [string compare $operation "Yes"] == 0 } {
    db_transaction {
	db_dml partner_proc_delete "delete from ad_partner_procs where url_id=:url_id"
	db_dml partner_url_delete "delete from ad_partner_url where url_id=:url_id"
    }
}

db_release_unused_handles

ad_returnredirect partner-view?[export_url_vars partner_id]