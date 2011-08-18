# $Id: faq-defs.tcl,v 3.0 2000/02/06 03:13:34 ron Exp $
# File:   /tcl/faq-defs.tcl
# Date:   12/19/99
# Contact: dh@arsdigita.com
#
# Purpose: faq related functions

proc_doc faq_authorize { db faq_id } "given faq_id, this procedure will check whether the user can the right to see this faq. if faq doesn't exist page is served to the user informing him that the page doesn't exist. if successfule it will return user_id of the administrator." {
    set selection [ns_db 0or1row $db "
    select faq_id, scope, group_id
    from faqs
    where faq_id=$faq_id"]
    
    if { [empty_string_p $selection] } {
	# faq doesn't exist
	uplevel {
	    ns_return 200 text/html "
	    [ad_scope_header "FAQ Doesn't Exist" $db]
	    [ad_scope_page_title "FAQ Doesn't Exist" $db]
	    [ad_scope_context_bar [list index.tcl?[export_url_scope_vars]  "FAQs"] "No FAQ"]
	    <hr>
	    <blockquote>
	    Requested FAQ does not exist.
	    </blockquote>
	    [ad_scope_footer]
	    "
	}
	return -code return
    }
    
    # faq exists
    set_variables_after_query
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }
    
    set authorization_status [ad_scope_authorization_status $db $scope all group_member none $id]
    
    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    return -code return
	}
	reg_required {
	    ad_redirect_for_registration
	    return -code return
	}
    }
}

proc_doc faq_admin_authorize { db faq_id } "given faq_id, this procedure will check whether the user can administer this faq (check whether the user is group administrator). if faq doesn't exist page is served to the user informing him that the page doesn't exist. if successfull it will return user_id of the administrator." {
    set selection [ns_db 0or1row $db "
    select faq_id, scope, group_id
    from faqs
    where faq_id=$faq_id"]

    if { [empty_string_p $selection] } {
	# faq doesn't exist
	uplevel {
	    ns_return 200 text/html "
	    [ad_scope_admin_header "FAQ Doesn't Exist" $db]
	    [ad_scope_admin_page_title "FAQ Doesn't Exist" $db]
	    [ad_scope_admin_context_bar [list index.tcl?[export_url_scope_vars]  "FAQs Admin"] "No FAQ"]
	    <hr>
	    <blockquote>
	    Requested FAQ does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	return -code return
    }
 
    # faq exists
    set_variables_after_query
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $db $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    return -code return
	}
	reg_required {
	    ad_redirect_for_registration
	    return -code return
	}
    }
}

proc_doc faq_maintaner_p { db faq_id } "checks whether the user has the right to mantain this faq" {

    set selection [ns_db 1row $db "
    select faq_id, scope, group_id
    from faqs
    where faq_id=$faq_id"]
    
    set_variables_after_query
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }
    
    set authorization_status [ad_scope_authorization_status $db $scope admin group_admin none $id]

    if { $authorization_status=="authorized" } {
	return 1
    } else {
	return 0
    }
}
