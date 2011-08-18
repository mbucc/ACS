<%
# domain-edit.adp -- edit a domain in the glassroom_domains table.  
#                    This file is an ADP so that we can ns_adp_include the 
#                    domain entry/editing form

set_form_variables

# Expects domain_name

if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
	return
}


# snarf the domain information

set db [ns_db gethandle]

set select_sql "
select by_whom_paid, last_paid, expires
  from glassroom_domains
 where domain_name='$domain_name'"

set selection [ns_db 1row $db $select_sql]
set_variables_after_query

ns_db releasehandle $db




# emit the page contents

ns_puts "[ad_header "Edit \"$domain_name\""]"

ns_puts "<h2>Edit \"$domain_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list domain-view.tcl?[export_url_vars domain_name] "View Domain"] "Edit Domain"]
<hr>
"


# include the shared HTML form

ns_adp_include "domain-form.adp" "Update Domain" "domain-edit-2.adp"



ns_puts "[glassroom_footer]"

%>

