# /www/intranet/procedures/add-2.tcl

ad_page_contract {
    Stores a new procedure to the db

    @param procedure_id the id of the procedure we're adding
    @param name the name of the procedure
    @param user_id user_id of this procedure's supervisor
    @param note general notes about the procedure

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id add-2.tcl,v 3.2.6.11 2001/01/12 08:53:20 khy Exp
} {
    procedure_id:integer,verify
    name:optional
    note:optional,html
    user_id:integer,optional

    
}

set creation_user [ad_maybe_redirect_for_registration]

set exception_count 0
set exception_text ""

if [empty_string_p ${name}] {
    incr exception_count
    append exception_text "<LI>The procedure needs a name\n"
}

if [empty_string_p ${user_id}] {
    incr exception_count
    append exception_text "<LI>Missing supervisor"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

db_transaction {


    set insert_sql "insert into im_procedures 
    (procedure_id, name, note, creation_date, creation_user) values
    (:procedure_id, :name, :note, sysdate, :creation_user)"

    if [catch {db_dml procedure_insert $insert_sql} errmsg] {
	if {[db_string procedure_exists "select count(*) from im_procedures where procedure_id = :procedure_id"] == 0} {
	    ad_return_error "Error" "Can't add procedure. Error: <PRE>$errmsg</PRE> "
	    return
	} else {
	    ad_returnredirect index
	    return
	}
    }

    db_dml procedure_user_insert "insert into im_procedure_users 
    (procedure_id, user_id, certifying_user, certifying_date) values
    (:procedure_id, :user_id, :creation_user, sysdate)"

}


db_release_unused_handles

ad_returnredirect index













