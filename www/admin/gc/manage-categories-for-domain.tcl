# /www/admin/gc/manage-categories-for-domain.tcl
ad_page_contract {
    Displays all categories within a domain.

    @param domain_id which domain

    @author philg@mit.edu
    @cvs manage-categories-for-domain.tcl,v 3.3.6.6 2000/09/22 01:35:23 kevin Exp
} {
    domain_id:integer
}

db_1row domain_info "select full_noun, domain from ad_domains where domain_id = $domain_id"

set page_content "[ad_admin_header "Categories for $domain Classified Ads"]

<h2>Categories</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] "Categories"]

<hr>

<h3>The Categories</h3>

<ul>

"

set counter 0 

db_foreach primary_categories_with_ads "select ac.primary_category, max(ac.category_id) as category_id, count(*) as n_ads
from ad_categories ac, classified_ads ca
where ac.domain_id = :domain_id
and ca.domain_id = :domain_id
and ac.primary_category = ca.primary_category
and (sysdate <= expires or expires is null)
group by ac.primary_category
order by upper(ac.primary_category)" {

    incr counter
    append page_content "<li>
<a href=\"ads-from-one-category?[export_url_vars domain_id primary_category]\">$primary_category</a>
($n_ads)
\[ <a href=\"delete-category?[export_url_vars domain_id category_id]\"> delete </a> | 
<a href=\"category-edit?[export_url_vars domain_id category_id]\"> edit </a> 
\]"

}

if { $counter == 0 } {
    append page_content "no categories defined currently"
}

append page_content "

<p>

<li><a href=\"category-add?domain_id=$domain_id\">add a new category</a>

</ul>

<h3>Categories that are presented to users placing ads</h3>

(but that don't show up on the front page because there aren't any ads
in these categories)

<p>

<ul>
"

set counter 0

db_foreach primary_categories_with_or_without_ads "select ac.primary_category,
category_id
from ad_categories ac
where ac.domain_id = :domain_id
and 0 = (select count(*) from classified_ads ca 
            where ca.domain_id = :domain_id
            and ca.primary_category = ac.primary_category)
order by upper(ac.primary_category)" {

    incr counter

    append page_content "<li>$primary_category \[ <a href=\"javascript:if(confirm('Are you sure you want to delete this category?'))location.href='delete-category?[export_url_vars domain_id category_id]'\"> DELETE </a> | 
<a href=\"category-edit?[export_url_vars domain_id category_id]\"> EDIT </a> 
\]"

}

if { $counter == 0 } {
    append page_content "No orphan categories found."
}

append page_content "
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
