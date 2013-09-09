# /www/intranet/employees/admin/category-edit.tcl

ad_page_contract {

    Overview:  Name-change form for categories.

    Takes a category_id and prints its name in a textbox, then passes the input
    along to category-edit-2.tcl

    Based on source-edit.tcl by teadams@arsdigita.com 4/24/00

    @author mshurpik@arsdigita.com
    @creation-date  August 1, 2000
    @cvs-id category-edit.tcl,v 1.1.2.6 2000/09/22 01:38:32 kevin Exp

    @param category_id      The item's id.  Since we are operating on a subset of 
                            the categories table, we have to be careful to check the
                            category_type at each operation.  Otherwise a user could
                            start addressing memory outside his designated block, so
                            speak.
    
    @param category_html    Unique plural pretty name for the category_type.  
                            We avoid passing the actual category_type, mostly for 
                            security.  We use our security proc to set it in the 
                            calling environment.

    @param backlink_url       For back-link (as opposed to return_url for redirect).

    @param backlink_url_name  We present a back-link to the user within the navbar,
                              so to do that we need a pretty-name.
} {
    category_html:notnull
    category_id:naturalnum
    
    backlink_url:optional
    backlink_url_name:optional
}

im_validate_and_set_category_type

if {[exists_and_not_null backlink_url] && ![exists_and_not_null backlink_url_name]} {

    ad_return_complaint 1 "<LI>If you specify <i>backlink_url</i>, 
    you must also specify an identifier in <i>backlink_url_name</i>."
    return
}

set return_url [ad_build_url "category-list.tcl" backlink_url backlink_url_name]

db_1row original_name "select category as original_name
from categories
where category_id = :category_id
and category_type = :category_type"



## Build context bar, including return_url (which we assume is to category-edit...)

set contextbar_html [ad_context_bar_ws \
	[list "/intranet/employees/admin" "Employees"] \
	[list "pipeline-list.tcl" "Pipeline"] \
	[list $backlink_url $backlink_url_name] "Edit $original_name"]


doc_return  200 text/html "
[ad_header "Edit $category_html"]
<h2>Edit $category_html</h2>
$contextbar_html

<hr>

<p>
<form action=category-edit-2 method=post>

<input type=hidden name=category_id value=$category_id>
<INPUT TYPE=HIDDEN NAME=return_url VALUE=\"$return_url\">
<INPUT TYPE=HIDDEN NAME=category_html VALUE=\"$category_html\">

Edit the name of this category: <input type=text name=new_name maxlength=50 value=\"$original_name\">

<input type=submit name=submit value=\"Confirm\">

</P> 

<p>
(To delete this category, enter a null value)
</p>


<form>
[ad_footer]
"

return

## END FILE category-edit.tcl