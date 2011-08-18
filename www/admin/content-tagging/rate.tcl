# $Id: rate.tcl,v 3.0.4.1 2000/04/28 15:08:30 carsten Exp $
set_the_usual_form_variables

# word, tag, todo

set db [ns_db gethandle]

set user_id [ad_get_user_id]

if { $todo == "create" } {   
    ns_db dml $db "insert into content_tags
(word, tag, creation_user, creation_date)
values
('$QQword', $tag,$user_id, sysdate)"
} else {
    if { $tag == 0 } {
	ns_db dml $db "delete from content_tags where word='$QQword'"
    } else {
	ns_db dml $db "update content_tags set tag = $tag where word = '$QQword'"
    }
}

ad_returnredirect "index.tcl"

