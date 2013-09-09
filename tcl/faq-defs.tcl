# /tcl/faq-defs.tcl

ad_library {
    faq related functions

    @author dh@arsdigita.com
    @creation-date 12/19/99
    @cvs-id faq-defs.tcl,v 3.1.2.6 2000/09/22 01:34:01 kevin Exp
}


proc_doc faq_authorize { faq_id } "given faq_id, this procedure will check whether the user can the right to see this faq. if faq doesn't exist page is served to the user informing him that the page doesn't exist. if successfule it will return user_id of the administrator." {
    set faq_exists [db_0or1row faq_info "
    select faq_id, scope, group_id
    from faqs
    where faq_id = :faq_id"]
    
    if { !$faq_exists } {
	# faq doesn't exist
	uplevel {
	    doc_return  200 text/html "
	    [ad_scope_header "FAQ Doesn't Exist"]
	    [ad_scope_page_title "FAQ Doesn't Exist"]
	    [ad_scope_context_bar [list index.tcl?[export_url_scope_vars]  "FAQs"] "No FAQ"]
	    <hr>
	    <blockquote>
	    Requested FAQ does not exist.
	    </blockquote>
	    [ad_scope_footer]
	    "
	}
	ad_script_abort
    }
    
    # faq exists
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }
    
    set authorization_status [ad_scope_authorization_status $scope all group_member none $id]
    
    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

proc_doc faq_admin_authorize { faq_id } "given faq_id, this procedure will check whether the user can administer this faq (check whether the user is group administrator). if faq doesn't exist page is served to the user informing him that the page doesn't exist. if successfull it will return user_id of the administrator." {

    set faq_exists [db_0or1row faq_info "
    select faq_id, scope, group_id
    from faqs
    where faq_id = :faq_id"]

    if { !$faq_exists } {
	# faq doesn't exist
	uplevel {
	    doc_return  200 text/html "
	    [ad_scope_admin_header "FAQ Doesn't Exist"]
	    [ad_scope_admin_page_title "FAQ Doesn't Exist"]
	    [ad_scope_admin_context_bar [list index.tcl?[export_url_scope_vars]  "FAQs Admin"] "No FAQ"]
	    <hr>
	    <blockquote>
	    Requested FAQ does not exist.
	    </blockquote>
	    [ad_scope_admin_footer]
	    "
	}
	ad_script_abort
    }
 
    # faq exists
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }

    set authorization_status [ad_scope_authorization_status $scope admin group_admin none $id]

    set user_id [ad_verify_and_get_user_id]

    switch $authorization_status {
	authorized {
	    return $user_id
	}
	not_authorized {
	    ad_return_warning "Not authorized" "You are not authorized to see this page"
	    ad_script_abort
	}
	reg_required {
	    ad_redirect_for_registration
	    ad_script_abort
	}
    }
}

proc_doc faq_maintaner_p { faq_id } "checks whether the user has the right to mantain this faq" {

    db_1row faq_info "
    select faq_id, scope, group_id
    from faqs
    where faq_id = :faq_id"
    
    switch $scope {
	public {
	    set id 0
	}
	group {
	    set id $group_id
	}
    }
    
    set authorization_status [ad_scope_authorization_status $scope admin group_admin none $id]

    if { $authorization_status=="authorized" } {
	return 1
    } else {
	return 0
    }
}
