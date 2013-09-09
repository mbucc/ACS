ad_library {
    Provides procedures used by the Contest module.

    @author Various [info@arsdigita.com]
    @cvs-id contest-defs.tcl,v 3.1.2.2 2000/07/11 14:56:51 eveander Exp
}

# Check for the user cookie, redirect if not found.
proc contest_security_checks {args why} {
    uplevel {
	#serve the index page w/o user login
	set security_current_url [string tolower [ns_conn url]]
	if {[string compare $security_current_url "/contest/index.tcl"]} {
	    return filter_ok
	} elseif {[string compare $security_current_url "/contest/index"]} {
	    return filter_ok
	} elseif {[string compare $security_current_url "/contest/"]} {
	    return filter_ok
	}

	set user_id [ad_verify_and_get_user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	    return filter_return
	} 
	return filter_ok
    }
}

# returns 1 if current user is in admin group for contest module
proc contest_user_admin_p {} {
    set user_id [ad_verify_and_get_user_id]
    return [ad_administration_group_member contest "" $user_id]
}

# Checks if user is logged in, AND is a member of the contest admin group
proc contest_security_checks_admin {args why} {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id == 0} {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    } 

    if {![contest_user_admin_p]} {
	ad_return_error "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
	
    return filter_ok
}

proc ad_contest_admin_footer {} {
    set owner [ad_parameter ContestAdminOwner contest [ad_admin_owner]]
    return "<hr>
<a href=\"mailto:$owner\"><address>$owner</address></a>
</body>
</html>"
}
