# $Id: domain-delete.tcl,v 3.1 2000/03/11 00:45:12 curtisg Exp $
set_the_usual_form_variables

# domain_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from ad_domains
where domain_id=$domain_id"]
set_variables_after_query

append html "[ad_admin_header "Delete $domain"]

<h2>Delete $domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Confirm Deletion"]

<hr>

Are you sure that you want to delete $domain and its
[database_to_tcl_string $db "select count(*) from classified_ads where domain_id = $domain_id"] ads?

<form method=post action=domain-delete-2.tcl>
[export_form_vars domain_id]
<center>
<input type=submit name=submit value=\"Yes, I'm sure\">
</center>

</form>
[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
