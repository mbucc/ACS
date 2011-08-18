# $Id: domain-administrator-update-2.tcl,v 3.1.2.1 2000/04/28 15:10:35 carsten Exp $
set_the_usual_form_variables

# domain_id, user_id_from_search
# first_names_from_search, last_name_from_search, email_from_search

set db [ns_db gethandle]

ns_db dml $db "update ad_domains set primary_maintainer_id = $user_id_from_search where domain_id = $domain_id"

ad_returnredirect "domain-top.tcl?[export_url_vars domain_id]"