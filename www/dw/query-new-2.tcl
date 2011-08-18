# $Id: query-new-2.tcl,v 3.0.4.1 2000/04/28 15:09:59 carsten Exp $
set_the_usual_form_variables

# query_name

# put in some error checking here for empty name

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode /dw/query-new.tcl]
   return
}

set db [ns_db gethandle]
set query_id [database_to_tcl_string $db "select query_sequence.nextval from dual"]

ns_db dml $db "insert into queries (query_id, query_name, query_owner, definition_time)
values
($query_id, '$QQquery_name', $user_id, sysdate)"

ad_returnredirect "query.tcl?query_id=$query_id"

