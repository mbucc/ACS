# File: /general-links/link-rate.tcl
# Date: 2/01/2000
# Author: tzumainn@arsdigita.com 
#
# Purpose: 
#  Updates a link's rating
#
# $Id: link-rate.tcl,v 3.0.4.1 2000/04/28 15:10:39 carsten Exp $
#--------------------------------------------------------

ad_page_variables {link_id rating}

#check for the user cookie
set user_id [ad_maybe_redirect_for_registration]

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

ns_db dml $db "update general_link_user_ratings set rating = $rating where user_id = $user_id and link_id = $link_id"
if { [ns_ora resultrows $db] == 0 } {
    ns_db dml $db "insert into general_link_user_ratings (user_id, link_id, rating)
    select $user_id, $link_id, $rating
    from dual
    where 0 = (select count(*) from general_link_user_ratings
               where user_id = $user_id
               and link_id = $link_id)
    "
}

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect "one-link.tcl?[export_url_vars link_id]"
