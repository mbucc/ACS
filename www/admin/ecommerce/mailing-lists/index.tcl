ad_page_contract {
    @cvs-id index.tcl,v 3.1.6.4 2000/09/22 01:34:56 kevin Exp
} {
}


set page_html "[ad_admin_header "Mailing Lists"]

<h2>Mailing Lists</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Mailing Lists"]

<hr>

<h3>Mailing Lists with Users</h3>
"



append page_html "[ec_mailing_list_widget "f"]

<h3>All Mailing Lists</h3>

<blockquote>
<form method=post action=one>

[ec_category_widget]
<input type=submit value=\"Go\">
</form>

</blockquote>

[ad_admin_footer]
"
doc_return  200 text/html $page_html
