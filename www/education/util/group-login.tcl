#
# /www/education/util/group-login.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows the user to select which group to log in as
#

ad_page_variables {
    return_url
    group_id
    group_type
}

set user_id [ad_verify_and_get_user_id] 
    
if {$user_id == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure the user is in the group and that the group_id 
# corresponds to the correct group_type

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select 1
     from user_group_map map, 
          user_groups ug 
    where map.user_id = $user_id 
      and ug.group_id = map.group_id 
      and group_type = '$group_type'
      and ug.active_p = 't' 
      and map.group_id=$group_id"] 

if { [info exists return_url] && ![empty_string_p $return_url] } {
    set final_page $return_url
} else {
    set final_page "/"
}

if {$selection == ""} {
    set site_admin_p [ad_administrator_p $db $user_id]
} else {
    set site_admin_p 0
}

if { ![empty_string_p $selection] || [string compare $site_admin_p 1] == 0} {
    ad_set_client_property education $group_type $group_id
    ad_returnredirect $return_url
} else {
    ad_return_error "Not authorized" "You are not authorized to enter this group."
}










