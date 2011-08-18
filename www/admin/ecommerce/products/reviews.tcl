# $Id: reviews.tcl,v 3.0 2000/02/06 03:20:52 ron Exp $
# reviews.tcl
#
# by eveander@arsdigita.com June 1999
#
# summarize professional reviews of one product and let site owner
# add a new review

set_the_usual_form_variables

# product_id

set product_name [ec_product_name $product_id]


ReturnHeaders

ns_write "[ad_admin_header "Professional Reviews of $product_name"]

<h2>Professional Reviews</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" "One Product"] "Professional Reviews"]

<hr>

<ul>
<li>Product Name:  $product_name
</ul>

<h3>Current Reviews</h3>
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select review_id, author_name, publication, review_date, display_p
from ec_product_reviews
where product_id=$product_id"]

set review_counter 0
while { [ns_db getrow $db $selection] } {
    incr review_counter
    set_variables_after_query
    ns_write "<li><a href=\"review.tcl?[export_url_vars review_id]\">[ec_product_review_summary $author_name $publication $review_date]</a>
    "
    if { $display_p != "t" } {
	ns_write " (this will not be displayed on the site)"
    }
}

if { $review_counter == 0 } {
    ns_write "There are no current reviews.\n"
}

ns_write "</ul>

<p>

<h3>Add a Review</h3>

<blockquote>
<form method=post action=review-add.tcl>
[export_form_vars product_id]

<table cellspacing=10>
<tr>
<td valign=top>
Publication
</td>
<td>
<input type=text name=publication size=20>
</td>
</tr>
<tr>
<td>
Reviewed By
</td>
<td>
<input type=text name=author_name size=20>
</td>
</tr>
<tr>
<td>
Reviewed On
</td>
<td>
[ad_dateentrywidget review_date]
</td>
</tr>
<tr>
<td>
Display on web site?
</td>
<td>
<input type=radio name=display_p value=\"t\" checked>Yes &nbsp;
<input type=radio name=display_p value=\"f\">No
</td>
</tr>
<tr>
<td valign=top>
Review<br>
(HTML format)
</td>
<td valign=top>
<textarea name=review rows=10 cols=50 wrap=soft></textarea>
</td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Add\">
</center>

</form>
</blockquote>

[ad_admin_footer]
"
