# /www/admin/gc/category-add.tcl
ad_page_contract  {
    Allows administrator to add a category.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs category-add.tcl,v 3.2.6.5 2001/01/10 18:56:22 khy Exp
} {
    domain_id:integer
}


set full_noun [db_string full_noun "select full_noun from ad_domains where domain_id = :domain_id"]

set category_id [db_string category_id "select ad_category_id_seq.nextval from dual"]


set page_content "[ad_admin_header "Add category"]

<h2>Add category</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] [list "manage-categories-for-domain.tcl?[export_url_vars domain_id]" "Categories"] "Add Category"]

<hr>

<form method=post action=category-add-2>
[export_form_vars -sign category_id]
[export_form_vars domain_id]
Category name: 
<input name=primary_category type=text size=50\">
<p>
Annotation for the ad placement page:<br>
<textarea cols=60 rows=6 wrap=soft type=text name=ad_placement_blurb></textarea>
<center>
<input type=submit name=submit_type value=\"Proceed\">
</center>
[ad_admin_footer]
"


doc_return  200 text/html $page_content