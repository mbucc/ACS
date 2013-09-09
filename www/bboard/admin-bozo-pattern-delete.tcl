# /www/bboard/admin-bozo-pattern-delete.tcl
ad_page_contract {
    Removes a bozo pattern from the system
    
    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param the_regexp the regular expression forming the bozo pattern

    @cvs-id admin-bozo-pattern-delete.tcl,v 3.2.2.3 2000/07/21 03:58:35 ron Exp
} {
    topic
    topic_id:integer,notnull
    the_regexp:allhtml
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
	return
}

# cookie checks out; user is authorized

db_dml bozo_pattern_delete "
delete from bboard_bozo_patterns 
where topic_id = :topic_id
and the_regexp = :the_regexp"

ad_returnredirect "admin-home.tcl?[export_url_vars topic topic_id]"

