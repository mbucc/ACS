# $Id: mass-delete.tcl,v 3.0.4.1 2000/04/28 15:09:46 carsten Exp $
set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

ns_db dml $db "delete from bm_list where owner_id = $user_id "

ad_returnredirect index.tcl

