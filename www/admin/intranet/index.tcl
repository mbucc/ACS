# /www/admin/intranet/index.tcl

ad_page_contract {
     Display tools available to members of intranet admin group
    
     @author luke@arsdigita.com
     @cvs-id index.tcl,v 3.3.2.4 2000/09/22 01:35:28 kevin Exp
} {
}

set whole_page "
[ad_admin_header "Intranet administration"]
<h2>Intranet administration</h2>
[ad_context_bar_ws [list ../ "Admin Home"] "Intranet administration"]
<hr>

<h3>Tools and Reports</h3>

<ul>
  <li> <a href=[im_url_stub]/employees/admin/>Employee administration</a>
  <li> <a href=[im_url_stub]/absences/>Work absences</a>
</ul>

<h3>Category Maintenance</h3>

<ul>
"

db_foreach category_type_by_category_type {
    select category_type, count(*) as n_categories 
    from categories 
    where category_type like 'Intranet%'
    group by category_type
    order by category_type asc
} {
    append whole_page "  <li>$category_type (number of categories defined: <a href=\"/admin/categories/one-type?[export_url_vars category_type]\">$n_categories</a>)\n"
}

append whole_page "
</ul>

[ad_admin_footer]
"



doc_return  200 text/html $whole_page

