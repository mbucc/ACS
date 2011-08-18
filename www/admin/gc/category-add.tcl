# $Id: category-add.tcl,v 3.1 2000/03/11 00:45:11 curtisg Exp $
set_the_usual_form_variables

# domain_id

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select full_noun from ad_domains where domain_id = $domain_id"]
set_variables_after_query

set category_id [database_to_tcl_string $db "select ad_category_id_seq.nextval from dual"]

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "Add category"]

<h2>Add category</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] [list "manage-categories-for-domain.tcl?[export_url_vars domain_id]" "Categories"] "Add Category"]

<hr>

<form method=post action=category-add-2.tcl>
[export_form_vars category_id domain_id]
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
