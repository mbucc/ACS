ad_page_contract {
    Toggles the html_p bit for one bboard msg.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 21 July 2000
    @cvs-id html-p-toggle.tcl,v 1.1.2.2 2000/11/11 00:50:44 lars Exp
} {
    msg_id:notnull
    {top_msg_id {$msg_id}}
    {return_url {q-and-a-fetch-msg?msg_id=$top_msg_id}}
}


ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

db_1row bboard_posting { select message, html_p from bboard where msg_id = :msg_id and user_id = :user_id }

switch -- $html_p {
    t { 
	set html_p "f"
    }
    f {
	set check [ad_html_security_check $message]
	if { ![empty_string_p $check] } {
	    ad_return_complaint 1 "<li>We can't display your bboard posting as HTML: $check"
	    return
	}
	set html_p "t"
    }
}

db_dml toggle_html_p {
    update bboard
    set html_p = :html_p
    where msg_id = :msg_id
    and user_id = :user_id
}


ad_returnredirect $return_url



