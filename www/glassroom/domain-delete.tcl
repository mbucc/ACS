# $Id: domain-delete.tcl,v 3.0.4.1 2000/04/28 15:10:42 carsten Exp $
# domain-delete.tcl -- confirm the removal of a domain from 
#                     glassroom_domains
#

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



# emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete \"$domain_name\""]

<h2>Delete \"$domain_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list domain-view.tcl?[export_url_vars domain_name] "View Domain"] "Delete Domain"]
<hr>

Are you sure you want to delete this domain?

<ul>
   <li> <a href=\"domain-delete-2.tcl?[export_url_vars domain_name]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"domain-view.tcl?[export_url_vars domain_name]\">no, let me look at the domain info again</a>
</ul>

[glassroom_footer]
"

