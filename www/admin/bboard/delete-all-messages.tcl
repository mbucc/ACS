# $Id: delete-all-messages.tcl,v 3.0 2000/02/06 02:49:17 ron Exp $
set_the_usual_form_variables

# topic_id

set db [bboard_db_gethandle]
if [catch {set selection [ns_db 0or1row $db "select bt.*,u.password as admin_password
from bboard_topics bt, users u
where bt.topic_id=$topic_id
and bt.primary_maintainer_id = u.user_id"]} errmsg] {
    [bboard_return_cannot_find_topic_page]
    return
}
# we found the data we needed
set_variables_after_query

set n_messages [database_to_tcl_string $db "select count(*) from bboard where topic_id = $topic_id"]

ns_return 200 text/html "[ad_admin_header "Clear Out $topic"]

<h2>Clear Out \"$topic\"</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] [list "administer.tcl?[export_url_vars topic]" "One Bboard"] "Clear Out"]

<hr>

Are you sure that you want to delete all $n_messages messages from
this forum?  

<center>

<form action=\"delete-all-messages-2.tcl\">
[export_form_vars topic]
<input type=submit value=\"yes, I'm sure; delete them!\">

</form>

</center>


[ad_admin_footer]
"
