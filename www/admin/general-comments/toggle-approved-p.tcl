# $Id: toggle-approved-p.tcl,v 3.0.4.1 2000/04/28 15:09:04 carsten Exp $
set_form_variables

# comment_id  maybe return_url

if {![info exists return_url]} {
    set return_url "index.tcl"
}

set db [ns_db gethandle]

ns_db dml $db "update general_comments set approved_p = logical_negation(approved_p) where comment_id = $comment_id"

ad_returnredirect $return_url

