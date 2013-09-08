# /www/download/admin/download-update-rule.tcl
ad_page_contract {
    target page to update existing rules associated with a downloadable file 

    @param new_rule_id the ID for the new rule
    @param download_id the file to add the rule to 
    @param version_id the version of the file to add the rule to
    @param price
    @param visibility
    @param availability
    @param currency
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-update-rule.tcl,v 3.9.2.6 2000/09/24 22:37:16 kevin Exp
} {
    new_rule_id:integer,notnull
    download_id:integer,notnull
    version_id:integer
    price
    visibility
    availability
    currency
    scope:optional
    group_id:optional,integer
}

# -----------------------------------------------------------------------------
 
ad_scope_error_check

download_admin_authorize $download_id

 
#Now check to see if the input is good as directed by the page designer

page_validation {
    if {![empty_string_p $price] && [regexp {[^0-9.]} $price] } {
	error "Invalid price was given. "
    } 
}

if { ![info exists return_url] } {
    set return_url "index?[export_url_scope_vars]"
}

set version_id_clause [ad_decode $version_id "" "" "and version_id = :version_id"]

# select all existing rules that the new rule is going to override, we need to update them

db_foreach existing_rules "
select rule_id
from   download_rules
where  download_id = :download_id
$version_id_clause" {

    db_dml rule_update "
    update download_rules
    set    visibility   = :visibility,
           availability = :availability,
           price        = :price, 
           currency     = :currency
    where  rule_id      = :rule_id "
}
    
if { [empty_string_p $version_id] } {
    
    # the new rule is for all versions of a specific download_id
    # if any such rule exists from before, it is already updated
    # else we will insert the rule

    set counter [db_string num_rules "
    select count(*)
    from   download_rules
    where  download_id = :download_id
    and    version_id is null"] 

    set bind_vars [ad_tcl_vars_to_ns_set download_id version_id visibility \
	availability price currency new_rule_id]


    if { $counter == 0 } {
	
	if { ![info exists return_url] } {
	    set return_url "index?[export_url_scope_vars]"
	}
	
	ad_dbclick_check_dml -bind $bind_vars rule_insert download_rules \
		rule_id	$rule_id $return_url "
	insert into download_rules
	(rule_id, version_id, download_id, visibility, availability, 
	 price, currency) 
	values 
	(:new_rule_id, :version_id, :download_id, :visibility,
	 :availability, :price, :currency)
	"
    }
} 

ad_returnredirect download-view?[export_url_scope_vars download_id]

