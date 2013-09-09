# /www/admin/bboard/administrator-add.tcl
ad_page_contract {
    Adds an adminstrator to a bboard topic

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param user_id_from_search the ID of the user to add

    @cvs-id administrator-add.tcl,v 3.1.6.4 2000/07/22 00:00:15 kevin Exp
} {
    topic
    topic_id:integer,notnull
    user_id_from_search:integer,notnull
}

# -----------------------------------------------------------------------------

ad_administration_group_user_add $user_id_from_search "administrator" "bboard" $topic_id

ad_returnredirect "topic-administrators.tcl?[export_url_vars topic topic_id]"
