# $Id: integrity-check-delete-comment.tcl,v 3.0.4.1 2000/04/28 15:09:04 carsten Exp $
set_the_usual_form_variables
# comment_id

set db [ns_db gethandle]

ns_db dml $db "delete from general_comments where comment_id = $comment_id"

ad_returnredirect "integrity-check.tcl"
