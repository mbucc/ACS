# /www/admin/bboard/delete-all-messages.tcl
ad_page_contract {
    Checks they really want to delete all the messages.

    @param topic_id the ID of the topic being cleared

    @author ?
    @creation-date ?
    @cvs-id delete-all-messages.tcl,v 3.2.2.4 2000/09/22 01:34:21 kevin Exp
} {
    topic_id:integer
}

# -----------------------------------------------------------------------------

if { ![db_0or1row get_topic_info "
select bt.*,
       u.password as admin_password
from   bboard_topics bt, 
       users u
where  bt.topic_id=:topic_id
and    bt.primary_maintainer_id = u.user_id"]} {
    [bboard_return_cannot_find_topic_page]
    return
}


set n_messages [db_string n_messages "
select count(*) from bboard where topic_id = :topic_id"]

# -----------------------------------------------------------------------------

doc_return  200 text/html "[ad_admin_header "Clear Out $topic"]

<h2>Clear Out \"$topic\"</h2>

[ad_admin_context_bar [list "index.tcl" "BBoard Hyper-Administration"] \
	[list "administer.tcl?[export_url_vars topic]" "One Bboard"] \
	"Clear Out"]

<hr>

Are you sure that you want to delete all $n_messages messages from
this forum?  

<center>

<form action=\"delete-all-messages-2\">
[export_form_vars topic]
<input type=submit value=\"yes, I'm sure; delete them!\">

</form>

</center>

[ad_admin_footer]
"
