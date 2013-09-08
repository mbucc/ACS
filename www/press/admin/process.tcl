# /www/press/admin/process.tcl

ad_page_contract {

    Process the result of a group action

    @author  Ron Henderson (ron@arsdigita.com)
    @created Thu Sep 14 05:05:11 2000
    @cvs-id  process.tcl,v 1.1.2.1 2000/09/16 19:07:21 ron Exp
} {
    press_items:multiple,notnull
    action:notnull
}

switch $action {

    delete  { 
	ad_returnredirect "delete?[export_url_vars press_items]" 
    }
    
    importance_high { 
	ad_returnredirect "importance?[export_url_vars press_items]&important_p=t" 
    }

    importance_low {
	ad_returnredirect "importance?[export_url_vars press_items]&important_p=f" 
    }
	
    default {
	ad_return_error "Not Implemented" "This action has not been implemented yet"
	return
    }
}


