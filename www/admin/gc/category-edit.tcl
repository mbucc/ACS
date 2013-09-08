# /www/admin/gc/category-edit.tcl
ad_page_contract {
    Allows administrator to edit a category.

    @param domain_id which domain
    @param category_id

    @author philg@mit.edu
    @cvs category-edit.tcl,v 3.4.2.5 2000/09/22 01:35:18 kevin Exp
} {
    domain_id:integer
    category_id:naturalnum
}

db_1row category_info "select ac.ad_placement_blurb, ad.domain,
ac.primary_category
from ad_categories ac, ad_domains ad
where ac.domain_id = :domain_id
and ad.domain_id = ac.domain_id
and ac.category_id = :category_id"

set page_content "[ad_admin_header "Edit $primary_category"]

<h2>Edit $primary_category</h2>

in the <a href=\"domain-top?domain_id=$domain_id\">$domain classifieds</a>

<hr>

<form method=post action=category-edit-2>
<input type=hidden name=domain_id value=\"$domain_id\">
<input name=old_primary_category type=hidden value=\"[philg_quote_double_quotes $primary_category]\">

Category name: <input name=primary_category type=text size=50 value=\"[philg_quote_double_quotes $primary_category]\"><p>
Annotation for the ad placement page:<br>
<textarea cols=60 rows=6 wrap=soft type=text name=ad_placement_blurb>[philg_quote_double_quotes $ad_placement_blurb]</textarea>
<center>
<input type=submit name=submit_type value=\"Edit\">
</center>
<br>
<br>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
