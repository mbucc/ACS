# /www/admin/gc/domain-delete.tcl
ad_page_contract {
    Lets the site administrator delete a domain.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs_id domain-delete.tcl,v 3.2.6.5 2000/09/22 01:35:22 kevin Exp
} {
    domain_id:integer
}

db_1row domain_info "select domain, full_noun from ad_domains where domain_id=:domain_id"


append page_contents "[ad_admin_header "Delete $domain"]

<h2>Delete $domain</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?[export_url_vars domain_id]" $full_noun] "Confirm Deletion"]

<hr>

Are you sure that you want to delete $domain and its
[db_string num_ads "select count(*) from classified_ads where domain_id = $domain_id"] ads?

<form method=post action=domain-delete-2>
[export_form_vars domain_id]
<center>
<input type=submit name=submit value=\"Yes, I'm sure\">
</center>

</form>
[ad_admin_footer]
"


doc_return  200 text/html $page_contents
