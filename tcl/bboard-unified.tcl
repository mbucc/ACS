# /tcl/bboard-unified.tcl
ad_library {
    Procs for unified bboards

    @author LuisRodriguez@photo.net  
    @creation-date May 2000
    @cvs-id bboard-unified.tcl,v 3.1.4.5 2000/07/27 22:35:19 kevin Exp
}

# -----------------------------------------------------------------------------

#
# Hacked from proc in bboard-defs.tcl
#

proc bboard_one_line_suffix_color {selection subject_line_suffix {color ""}} {
    # subject_line_suffix is a list containig any combination of keywords:
    # {name email date}. It controls what information is displayed after the
    # usual one line subject.
    set posting_time [ns_set get $selection posting_time]
    set urgent_p [ns_set get $selection urgent_p]
    set topic_id [ns_set get $selection topic_id]
    set msg_id [ns_set get $selection msg_id]
    # Author of the current message:
    set poster_id [ns_set get $selection poster_id]
    set name [ns_set get $selection name]
    set email [ns_set get $selection email]
    # The User who is viewing this:
    upvar user_id user_id
    set suffix ""
    foreach column $subject_line_suffix {
	if { $column == "name" && $name != "" } {
	    append suffix " by <a style=\"color:$color\" href=\"/shared/community-member.tcl?user_id=$poster_id\">$name</a>"
        }
	if { $column == "email" && $email != "" } {
	    append suffix " <font color=\"$color\">($email)</font>"
        }
	if { $column == "date" && [info exists posting_time] && $posting_time != "" } {
	    append suffix " <font color=\"$color\">($posting_time)</font>"
        }
    }
    if { [ad_parameter UrgentMessageEnabledP "bboard" 0] && [info exists urgent_p] && $urgent_p == "t" } {
	append suffix " <font color=red>urgent!</font> "
	if { $poster_id == $user_id } {
	    append suffix " <a style=\"color:$color\" href=\"msg-urgent-toggle.tcl?[export_url_vars msg_id]&return_url=[ns_urlencode q-and-a.tcl?[export_url_vars topic_id]]\">Make unurgent</a> "
	}
    }
    return $suffix
}

proc_doc icon_id_to_img_html { icon_id } {
    Returns IMG  HTML for displaying icon from icon_id
} {
    set return_img ""

    db_foreach icon_info "
    SELECT icon_file, icon_name, icon_width, icon_height
    FROM   bboard_icons
    WHERE  icon_id = :icon_id" {

	set icon_dir [ad_parameter IconSrc bboard/unified "/bboard/unified/icons"]
	set return_img "<img alt=\"$icon_name\" width=$icon_width height=$icon_height src=\"$icon_dir/$icon_file\">"
    } 

    db_release_unused_handles
    return $return_img
}

proc_doc validate_bboard_access { topic_id read_access user_id } {
    Return 1 if user has access to forum, otherwise return 0 
} {

    set access_allowed 0

    # This mess is to try to avoid the subquery for the common case ("any" or "public" access)
    if { [string compare $read_access "any"] == 0 || 
         [string compare $read_access "public"] == 0 } {
	set access_allowed 1
    } else {
	if { ([string compare $read_access "group"] == 0 && 
	      [ad_permission_p bboard $topic_id "" $user_id]) ||
	     [ad_administration_group_member "site_wide" "" $user_id] } {
	    set access_allowed 1
	}
    }
    
    return $access_allowed
}

proc_doc scrub_access_to_unified_topics { user_id } {
    Changes bboard_unified to ensure that user_id does not have unauthorized access to any forums 
} {
    set scrub_topics [list]

    db_foreach topic_access {
	SELECT DISTINCT bboard_unified.topic_id AS topic_id, 
	       bboard_topics.read_access AS read_access
	FROM   bboard_topics, bboard_unified
	WHERE  bboard_topics.topic_id = bboard_unified.topic_id
	AND    bboard_topics.read_access not in ('any', 'public')
	AND    bboard_unified.topic_id = :user_id
    } {
	if { !( [validate_bboard_access $topic_id $read_access $user_id] ) } {
	    lappend scrub_topics $topic_id
	}

    } if_no_rows {
	return
    }

    if { [llength $scrub_topics] != 0 } {
	db_dml bboard_unifed_update "
	UPDATE bboard_unified
	SET    default_topic_p = 'f'
	WHERE  user_id = :user_id
	AND    topic_id in ([join $scrub_topics ", "])"
    }    
}

proc_doc update_user_unified_topics { user_id } {
    Update the topics in bboard_unified for a user
} {
    db_dml unified_topic_insert "
	INSERT INTO bboard_unified
	(user_id, topic_id, default_topic_p, color, icon_id)
	SELECT :user_id, topic_id, default_topic_p, color, icon_id
	FROM bboard_topics
	WHERE topic_id NOT IN (SELECT topic_id
	                       FROM bboard_unified
                               WHERE user_id = :user_id)
	"

    scrub_access_to_unified_topics $user_id
}

    
