# /www/download/admin/download-update-rule.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  target page to update existing rules associated with a downloadable file 
#
# $Id: download-update-rule.tcl,v 3.0.6.3 2000/05/18 00:05:16 ron Exp $
# -----------------------------------------------------------------------------

set_the_usual_form_variables 0

# maybe scope, maybe scope related variables (group_id)
# new_rule_id, version_id, download_id, price, visibility , availability, currency
 
ad_scope_error_check

set db_pool [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pool 0]
set db2 [lindex $db_pool 1]

download_admin_authorize $db $download_id

 
#Now check to see if the input is good as directed by the page designer
set exception_count 0
set exception_text ""


if {![empty_string_p $price] && [regexp {[^0-9.]} $price] } {
    incr exception_count
    append exception_text "<li>Invalid price was given. <br>"
} 


if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

if { ![info exists return_url] } {
    set return_url "index.tcl?[export_url_scope_vars]"
}


set version_id_clause [ad_decode $version_id "" "" "and version_id = $version_id"]

# select all existing rules that the new rule is going to override, we need to update them

set selection [ns_db select $db "
select rule_id
from   download_rules
where  download_id = $download_id
$version_id_clause"]

while { [ns_db getrow $db $selection ] } {
    set_variables_after_query
  
    ns_db dml $db2 "
    update download_rules
    set    visibility   = '$QQvisibility',
           availability = '$QQavailability',
           price        = '$price', 
           currency     = '$QQcurrency'
    where  rule_id      = $rule_id "
}
    
if { [empty_string_p $version_id] } {
    
    # the new rule is for all versions of a specific download_id
    # if any such rule exists from before, it is already updated
    # else we will insert the rule

    set counter [database_to_tcl_string $db "
    select count(*)
    from   download_rules
    where  download_id = $download_id
    and    version_id is null"] 

    if { $counter == 0 } {
	
	if { ![info exists return_url] } {
	    set return_url "index.tcl?[export_url_scope_vars]"
	}
	
	ad_dbclick_check_dml $db download_rules rule_id $rule_id $return_url "
	insert into download_rules
	(rule_id, version_id, download_id, visibility, availability, price, currency) 
	values 
	($new_rule_id, '$version_id', $download_id, '$QQvisibility', '$QQavailability', '$price', '$QQcurrency')
	"
    }
} 

ad_returnredirect download-view.tcl?[export_url_scope_vars download_id]


