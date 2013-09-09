# /admin/ug/group-type-module-add-2.tcl
ad_page_contract {
    associates module with the group type
    @author tarik@arsdigita.com
    @cvs-id group-type-module-add-2.tcl,v 3.2.2.7 2000/07/25 05:57:46 kevin Exp
    @creation-date 22 December 1999

    @param group_type_module_id the ID of the group_type module
    @param group_type the group type
    @param module_key the identifier of the module
    @param return_url:optional an optional URL to go back to
} {  
    group_type:notnull
    module_key:notnull
    {return_url "group-type?[export_url_vars group_type]"}
}

if { [catch { db_exec_plsql user_group_type_module_add {
    begin :1 := 1; user_group_type_module_add(:group_type, :module_key); end;}
} err_msg] } {
    # Oracle choked on the insert
    
    # Note that double-clicks are gracefully handled in the pl/sql procedure (no side-effects!)
    # So we do not have to check here for the double-click
    ns_log Error "[info script] choked. Oracle returned error:  $err_msg"
    
    ad_return_error "Error in insert" "
    We were unable to do your insert in the database. 
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $err_msg
    </pre>
    </blockquote>"
    return
}

ad_returnredirect $return_url




