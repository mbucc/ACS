# /www/bboard/admin-bozo-pattern-edit-2.tcl
ad_page_contract {
    Modifies the bozo pattern

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param the_regexp the new bozo pattern
    @param the_regexp_old the old bozo pattern
    @param scope the scope of the bozo pattern
    @param message_to_user what we show users who run afoul of the filter
    @param creation_comment a comment on this filter

    @cvs-id admin-bozo-pattern-edit-2.tcl,v 3.2.2.3 2000/07/21 03:58:35 ron Exp
} {
    topic:notnull
    topic_id:integer,notnull
    the_regexp:allhtml
    the_regexp_old:allhtml
    scope
    message_to_user:html
    creation_comment
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
	return
}

db_dml bozo_pattern_update "
update bboard_bozo_patterns 
set the_regexp = :the_regexp,
    scope = :scope,
    message_to_user = :message_to_user,
    creation_comment = :creation_comment
where topic_id = :topic_id
and the_regexp = :the_regexp_old"

ad_returnredirect admin-bozo-pattern.tcl?[export_url_vars topic topic_id the_regexp]

