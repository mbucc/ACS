# $Id: manage-categories-for-domain.tcl,v 3.1.2.4 2000/03/15 05:23:57 curtisg Exp $
set_the_usual_form_variables

# domain_id

set db [gc_db_gethandle]
set selection [ns_db 1row $db "select full_noun, domain from ad_domains where domain_id = $domain_id"]
set_variables_after_query

append html "[ad_admin_header "Categories for $domain Classified Ads"]

<h2>Categories</h2>

[ad_admin_context_bar [list "index.tcl" "Classifieds"] [list "domain-top.tcl?domain_id=$domain_id" $full_noun] "Categories"]

<hr>

<h3>The Categories</h3>

<ul>

"

set selection [ns_db select $db "select ac.primary_category, count(*) as n_ads
from ad_categories ac, classified_ads ca
where ac.domain_id = $domain_id
and ca.domain_id = $domain_id
and ac.primary_category = ca.primary_category
and (sysdate <= expires or expires is null)
group by ac.primary_category
order by upper(ac.primary_category)"]

set counter 0 
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr counter
    append html "<li>
<a href=\"ads-from-one-category.tcl?domain_id=$domain_id&primary_category=[ns_urlencode $primary_category]\">$primary_category</a>
($n_ads)
\[ <a href=\"delete-category.tcl?domain_id=$domain_id&primary_category=[ns_urlencode $primary_category]\"> delete </a> | 
<a href=\"category-edit.tcl?domain_id=$domain_id&primary_category=[ns_urlencode $primary_category]\"> edit </a> 
\]"

}

if { $counter == 0 } {
    append html "no categories defined currently"
}

append html "

<p>

<li><a href=\"category-add.tcl?domain_id=$domain_id\">add a new category</a>

</ul>

<h3>Categories that are presented to users placing ads</h3>

(but that don't show up on the front page because there aren't any ads
in these categories)

<p>

<ul>
"

set selection [ns_db select $db "select ac.primary_category
from ad_categories ac
where ac.domain_id = $domain_id
and 0 = (select count(*) from classified_ads ca 
            where ca.domain_id = $domain_id
            and ca.primary_category = ac.primary_category)
order by upper(ac.primary_category)"]

set counter 0
while {[ns_db getrow $db $selection]} {
    incr counter
    set_variables_after_query
    append html "<li>$primary_category \[ <a href=\"delete-category.tcl?domain_id=$domain_id&primary_category=[ns_urlencode $primary_category]\"> DELETE </a> | 
<a href=\"category-edit.tcl?domain_id=$domain_id&primary_category=[ns_urlencode $primary_category]\"> EDIT </a> 
\]"

}

if { $counter == 0 } {
    append html "No orphan categories found."
}

append html "
</ul>

[ad_admin_footer]
"

ns_db releasehandle $db
ns_return 200 text/html $html
