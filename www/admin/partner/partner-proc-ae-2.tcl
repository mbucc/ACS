# /www/admin/partner/partner-proc-ae-2.tcl

ad_page_contract {
    Writes procedures name to database

    @param url_id associated url
    @param proc_id procedure ID (for adding/editing)
    @param proc_name name of procedure
    @param proc_type header/footer
    @param call_number order in which to call this procedure
    @param return_url 

    @author mbryzek@arsdigita.com
    @creation-date 10/1999

    @cvs-id partner-proc-ae-2.tcl,v 3.2.2.3 2000/07/24 02:53:26 mshurpik Exp
} {
    url_id:naturalnum,notnull
    proc_id:naturalnum,notnull
    proc_name:trim,notnull
    proc_type:trim,notnull
    call_number:notnull
    { return_url "" }
}


# Check for uniqueness
set exists_p [db_string partner_proc_name_unique_check \
	"select decode(count(*),0,0,1) 
           from ad_partner_procs 
          where url_id=:url_id 
            and proc_name=:proc_name
            and proc_id<>:proc_id
            and proc_type=:proc_type"]

if { $exists_p } {
    ad_partner_return_error "Duplicate procedure name" "<ul><li>Specified proc \"$proc_name\" has already been registered for this partner and url</ul>\n"
    return
}


db_dml partner_proc_name_update \
	"update ad_partner_procs 
            set proc_name=:proc_name
          where proc_id = :proc_id"
    
if { [db_resultrows] == 0 } {
    db_dml partner_proc_name_insert \
	    "insert into ad_partner_procs
             (url_id, proc_id, proc_name, proc_type, call_number)
             values 
             (:url_id, :proc_id, :proc_name, :proc_type, :call_number)"
}

db_release_unused_handles

ad_returnredirect "partner-url?[export_url_vars url_id]"

