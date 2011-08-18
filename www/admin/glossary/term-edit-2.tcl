# $Id: term-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:07 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode [ns_conn url]]?term=$term
}

set exception_count 0
set exception_text ""

set_the_usual_form_variables
# term, definition

set db [ns_db gethandle]


if { ![info exists term] || [empty_string_p $QQterm] } {
    incr exception_count
    append exception_text "<li>No term to edit\n"
} else {
    set author [database_to_tcl_string_or_null $db "select author
    from glossary
    where term = '$QQterm'"]

}

if { ![info exists definition] || [empty_string_p $QQdefinition] } {
    incr exception_count
    append exception_text "<li>No definition provided\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ns_db dml $db "update glossary set definition = '$QQdefinition' where term = '$QQterm'"

ad_returnredirect "one.tcl?term=[ns_urlencode $term]"