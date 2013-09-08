# /www/intranet/employees/admin/category-list.tcl

ad_page_contract {

    Overview: Lists names of categories from the categories table, within a 
    particular category_type.

    Also offers links to add, edit, and delete. 

    Based on source-list.tcl by teadams@arsdigita.com 4/24/00

    This page links to category-edit.tcl and category-add.tcl.

    @author mshurpik@arsdigita.com
    @creation-date August 1, 2000
    @cvs-id category-list.tcl,v 1.1.2.7 2000/09/22 01:38:32 kevin Exp
    
    @param category_html    Unique plural pretty name for the category_type.  
                            We avoid passing the actual category_type, mostly for 
                            security.  We use our security proc to set it in the 
                            calling environment.

    @param backlink_url       For back-link (as opposed to return_url for redirect).

    @param backlink_url_name  We present a back-link to the user within the navbar,
                              so to do that we need a pretty-name.


} {
    category_html:notnull

    exception_text:html,optional

    backlink_url:optional
    backlink_url_name:optional
}


im_validate_and_set_category_type


## We won't take one without the other
if {[exists_and_not_null backlink_url] && ![exists_and_not_null backlink_url_name]} {

    ad_return_complaint 1 "<LI>If you specify <i>backlink_url</i>, 
    you must also specify an identifier in <i>backlink_url_name</i>."
    return
}
 

set return_url [ad_build_url [ns_conn url] backlink_url backlink_url_name]


## If we have a message for the user, append a link to clear the message.

if {[info exists exception_text]} {

    append exception_text " <FONT SIZE=-1> ...<A HREF = \"
    [ad_build_url return_url category_html]\">clear</A> </FONT>"

} else {

    set exception_text ""

}


## Query the database and build a list of category names.

set categories_html "<UL>"

db_foreach get_category "select category_id, category 
from categories where category_type = :category_type order by upper(category) asc" {

    append categories_html "<LI>$category
    <FONT SIZE=-1>...<a href=[ad_build_url "category-edit.tcl" category_id category_html backlink_url backlink_url_name]>edit</a></FONT>"

} if_no_rows {

    append categories_html "<LI>There are no $category_html defined."

}

append categories_html "</UL>"


## Build context bar.  Include backlink_url and backlink_url_name if we have them both.
if {[exists_and_not_null backlink_url]} {

    set contextbar_html [ad_context_bar_ws \
	    [list "/intranet/employees/admin" "Employees"] \
	    [list "/intranet/employees/admin/pipeline-list.tcl" "Pipeline"]\
	    [list $backlink_url $backlink_url_name] "$category_html"]
    
} else {

    set contextbar_html [ad_context_bar_ws [list "/intranet/employees/admin" "Employees"] [list "/intranet/employees/admin/pipeline-list.tcl" "Pipeline"] [list "$category_html"]

}


doc_return  200 text/html "
[ad_header "$category_html"]
<h2>$category_html</h2>
$contextbar_html
<hr>



<form action=category-add method=post>
<INPUT TYPE=HIDDEN NAME=return_url VALUE=\"$return_url\">
<INPUT TYPE=HIDDEN NAME=category_html VALUE=\"$category_html\">

Add New Category: <input type=text name=new_category maxlength=50> 
<input type=submit name=submit value=\"Confirm\">



</form>

$exception_text

$categories_html

[ad_footer]
v"

return

## END FILE category-list.tcl





