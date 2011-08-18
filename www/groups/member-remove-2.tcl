# $Id: member-remove-2.tcl,v 3.1.4.1 2000/04/28 15:10:57 carsten Exp $
set_the_usual_form_variables

# group_id, user_id
# return_url (optional)

set db [ns_db gethandle]

ns_db dml $db "delete from user_group_map where
user_id = $user_id and group_id = $group_id"

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "index.tcl"
}