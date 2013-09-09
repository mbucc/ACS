# /www/bboard/admin-bozo-pattern-add-2.tcl
ad_page_contract {
    Adds a new bozo pattern

    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param the_regexp the regular expression that is the bozo pattern
    @param scope the scope of the bozo pattern
    @param message_to_user what we tell users who trigger the filter
    @param creation_comment an explanation of the bozo pattern

    @cvs-id admin-bozo-pattern-add-2.tcl,v 3.2.2.3 2000/07/21 03:58:34 ron Exp
} {
    topic:notnull
    topic_id:notnull,integer
    the_regexp:allhtml
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

db_dml bozo_pattern_insert "
insert into bboard_bozo_patterns
(topic_id, the_regexp, scope, message_to_user, creation_date, creation_user, 
 creation_comment)
values
(:topic_id, :the_regexp, :scope, :message_to_user, sysdate, 
 [ad_verify_and_get_user_id], :creation_comment)"

ad_returnredirect "admin-home.tcl?[export_url_vars topic topic_id]"
