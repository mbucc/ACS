# /www/download/admin/download-add-rule-2.tcl
ad_page_contract {
    target page to add new rule associated with a downloadable file 

    @param new_rule_id the ID for the new rule
    @param version_id the version of the file the rule applies to
    @param download_id the file the rule applies to
    @param price
    @param visibility
    @param availability
    @param currency
    @param scope
    @param group_id

    @author ahmeds@mit.edu
    @creation-date 4 Jan 2000
    @cvs-id download-add-rule-2.tcl,v 3.10.2.7 2000/09/24 22:37:13 kevin Exp
} {
    new_rule_id:integer,notnull
    version_id:integer
    download_id:integer,notnull
    price
    visibility
    availability
    currency
    scope:optional
    group_id:optional
}

# -----------------------------------------------------------------------------

ad_scope_error_check

download_admin_authorize $download_id

# Now check to see if the input is good as directed by the page designer

page_validation {

    if {![empty_string_p $price] && [regexp {[^0-9.]} $price] } {
        error "Invalid price was given."
    } 
}


if { ![info exists return_url] } {
    set return_url "download-view?[export_url_scope_vars download_id]"
}

set counter [db_string num_rules "
select count(*) 
from   download_rules 
where  download_id = :download_id 
[ad_decode $version_id "" "" "and version_id = :version_id"]"]

if { $counter > 0 } {
    # there are other rules with the same download_id and possibly same version_id
    # seek confirmation from the administrator before updating them
    
    db_1row download_name "
    select download_name 
    from   downloads
    where  download_id = :download_id"
    
    set page_title "Confirm Changing Rule for $download_name"

    doc_return 200 text/html "
    [ad_scope_header $page_title]
    [ad_scope_page_title $page_title]
    [ad_scope_context_bar_ws \
	    [list "/download/index?[export_url_scope_vars]" "Download"] \
	    [list "/download/admin/index?[export_url_scope_vars]" "Admin"] \
	    [list "download-view?[export_url_scope_vars download_id]" "$download_name"] \
	    [list "download-add-rule?[export_url_scope_vars download_id]" "Add Rule" ] \
	    $page_title]
    
    <hr>

    <blockquote>
    This will change $counter existing rule(s). 
    Are you sure that you want to update all the existing rule(s)? 
    </blockquote>

    <center>
    <form method=post action=download-update-rule>
    [export_form_scope_vars new_rule_id download_id version_id price visibility availability currency]
    <input type=submit value=\"Yes, I'm sure\">
    </form>
    </center>
    
    <p>

    [ad_scope_footer]    
    "
    
} else {

    set bind_vars [ad_tcl_vars_to_ns_set new_rule_id visibility \
	    availability price currency version_id download_id]

    ad_dbclick_check_dml -bind $bind_vars rule_insert download_rules rule_id \
	    $new_rule_id $return_url "
    insert into download_rules
    ( rule_id, 
      version_id, 
      download_id, 
      visibility, 
      availability, 
      price, 
      currency) 
    values 
    (:new_rule_id, 
     :version_id, 
     :download_id, 
     :visibility, 
     :availability, 
     :price, 
     :currency)"
}







