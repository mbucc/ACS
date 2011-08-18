# $Id: modify-daily-spam.tcl,v 3.0.4.1 2000/04/28 15:09:21 carsten Exp $
# modify-daily-spam.tcl
#
# hqm@arsdigita.com
#
# Modify daily spam table

set_the_usual_form_variables

set iter 0

set db [ns_db gethandle]

with_transaction $db { 
    ns_db dml $db "delete from daily_spam_files"

    while {[info exists user_class_id_$iter]} {
	if {[empty_string_p [set file_prefix_$iter]] || [empty_string_p [set subject_$iter]]} {
	    # ignore entries with null strings
	} else {
	    set user_class_name [database_to_tcl_string $db "select name from user_classes where user_class_id  = [set user_class_id_$iter]"]
	    if {![info exists template_p_$iter]} {
		set template_p_$iter "f"
	    }
	    ns_db dml $db "insert into daily_spam_files (from_address, target_user_class_id, user_class_description, subject, file_prefix, template_p) 
values ([ns_dbquotevalue [set from_address_$iter]], [set user_class_id_$iter], [ns_dbquotevalue $user_class_name], [ns_dbquotevalue [set subject_$iter]],[ns_dbquotevalue [set file_prefix_$iter]],[ns_dbquotevalue [set template_p_$iter]])"
	}
	incr iter
    } 
} {
    ns_returnerror 500 "Error in updating daily_spam_files table: $errmsg"
    return
}

ad_returnredirect "show-daily-spam.tcl"