# $Id: toggle-dont-spam-me-p.tcl,v 3.0.4.1 2000/04/28 15:11:24 carsten Exp $

set user_id [ad_get_user_id]

set db [ns_db gethandle]

ns_db dml $db "update users_preferences set dont_spam_me_p = logical_negation(dont_spam_me_p) where user_id = $user_id"

ad_returnredirect "home.tcl"
