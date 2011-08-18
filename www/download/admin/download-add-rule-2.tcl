# /www/download/admin/download-add-rule-2.tcl
#
# Date:     01/04/2000
# Author :  ahmeds@mit.edu
# Purpose:  target page to add new rule associated with a downloadable file 
#
# $Id: download-add-rule-2.tcl,v 3.0.6.2 2000/05/18 00:05:15 ron Exp $

set_the_usual_form_variables
# maybe scope, maybe scope related variables (group_id)
# new_rule_id, version_id, download_id, price, visibility , availability, currency
 
ad_scope_error_check

set db [ns_db gethandle]
download_admin_authorize $db $download_id

# Now check to see if the input is good as directed by the page designer

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
    set return_url "download-view.tcl?[export_url_scope_vars download_id]"
}

set counter [database_to_tcl_string $db "
select count(*) 
from   download_rules 
where  download_id = $download_id 
[ad_decode $version_id "" "" "and version_id = $version_id"]"]

if { $counter > 0 } {
    # there are other rules with the same download_id and possibly same version_id
    # seek confirmation from the administrator before updating them
    
    set download_name [database_to_tcl_string $db "
    select download_name 
    from   downloads
    where  download_id = $download_id"]
    
    set page_title "Confirm Changing Rule for $download_name"

    ns_return 200 text/html "
    [ad_scope_header $page_title $db]
    [ad_scope_page_title $page_title $db]
    [ad_scope_context_bar_ws \
	    [list "/download/" "Download"] \
	    [list "/download/admin/" "Admin"] \
	    [list "download-view.tcl?[export_url_scope_vars download_id]" "$download_name"] \
	    [list "download-add-rule.tcl?[export_url_scope_vars download_id]" "Add Rule" ] \
	    $page_title]
    
    <hr>

    <blockquote>
    This will change $counter existing rule(s). 
    Are you sure that you want to update all the existing rule(s)? 
    </blockquote>

    <center>
    <form method=post action=download-update-rule.tcl>
    [export_form_scope_vars new_rule_id download_id version_id price visibility availability currency]
    <input type=submit value=\"Yes, I'm sure\">
    </form>
    </center>
    
    <p>

    [ad_scope_footer]    
    "
    
} else {
    ad_dbclick_check_dml $db download_rules rule_id $new_rule_id $return_url "
    insert into download_rules
    ( rule_id, 
      version_id, 
      download_id, 
      visibility, 
      availability, 
      price, 
      currency) 
    values 
    ( $new_rule_id, 
     '$version_id', 
      $download_id, 
     '$QQvisibility', 
     '$QQavailability', 
     '$price', 
     '$QQcurrency')"
}

