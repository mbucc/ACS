#
# /www/admin/news/toggle-approved-p.tcl
#
# toggles approval status for one news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: toggle-approved-p.tcl,v 3.1.2.1 2000/04/28 15:09:12 carsten Exp $

set_the_usual_form_variables 0
# maybe return_url, name
# news_item_id

set db [ns_db gethandle]
set user_id [ad_get_user_id]

# permission check

ns_db dml $db "update news_items set approval_state = decode(approval_state, 'approved', 'disapproved', 'approved'), approval_user = $user_id, approval_date = sysdate, approval_ip_address = '[DoubleApos [ns_conn peeraddr]]' where news_item_id = $news_item_id"

ad_returnredirect "item.tcl?[export_url_vars news_item_id]"



