# /www/intranet/employees/admin/change-subordinates-2.tcl

ad_page_contract {

    Performs database insert for transferring employees to a new supervisor.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date Sat May 20 21:18:28 2000
    @cvs-id change-subordinates-2.tcl,v 3.4.6.8 2000/08/16 21:24:47 mbryzek Exp
    @param from_user_id The original supervisor 
    @param user_id_from_search The new supervisor
    @param return_url The url to return to
    @param id An array of ids specifying the underlings changing hands passed as id_*
} {
    from_user_id:naturalnum
    user_id_from_search:naturalnum
    {return_url ""}
    id:array
}




db_transaction {
    set array_search_id [array startsearch id]
    while {[array anymore id $array_search_id]} {
	set the_id [array nextelement id $array_search_id]
	if {$id($the_id) == "t"} {
	    db_dml update*_emp*_info "update im_employee_info 
	    set supervisor_id=:user_id_from_search
	    where user_id=:the_id"
	}

    }
}
    
db_release_unused_handles

if { [empty_string_p $return_url] } {
    set return_url "view.tcl?user_id=$from_user_id"
}

ad_returnredirect $return_url