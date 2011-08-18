# $Id: upload.tcl,v 3.0 2000/02/06 03:21:13 ron Exp $
# This page uploads a CSV file containing store-specific products into the catalog.  The file format should be:
#
# field_name_1, field_name_2, ... field_name_n
# value_1, value_2, ... value_n
#
# where the first line contains the actual names of the columns in ec_products and the remaining lines contain
# the values for the specified fields, one line per product.
#
# Legal values for field names are the columns in ec_products (see [ns_info pageroot]/docs/sql/ecommerce.sql
# for current column names):
# product_id (required)
# sku
# product_name (required)
# one_line_description
# detailed_description
# search_keywords
# price
# shipping
# shipping_additional
# weight
# dirname
# present_p
# active_p
# available_date
# announcements
# announcements_expire
# url
# template_id
# stock_status
#
# Note: dirname, creation_date, available_date, last_modified, last_modifying_user and modified_ip_address are set 
# automatically and should not appear in the CSV file.

ReturnHeaders

ns_write "[ad_admin_header "Upload Products"]

<h2>Upload Products</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Upload Products"]

<hr>

<blockquote>

<form enctype=multipart/form-data action=upload-2.tcl method=get>
CSV Filename <input name=csv_file type=file>
<p>
<center>
<input type=submit value=Upload>
</center>
</form>

<p>

<b>Notes:</b>

<blockquote>
<p>

This page uploads a CSV file containing product information into the database.  The file format should be:
<p>
<blockquote>
<code>field_name_1, field_name_2, ... field_name_n<br>
value_1, value_2, ... value_n</code>
</blockquote>
<p>
where the first line contains the actual names of the columns in ec_products and the remaining lines contain
the values for the specified fields, one line per product.
<p>
Legal values for field names are the columns in ec_products:
<p>
<blockquote>
<pre>
"

set undesirable_cols [list "dirname" "creation_date" "available_date" "last_modified" "last_modifying_user" "modified_ip_address"]
set required_cols [list "product_id" "product_name"]

set db [ns_db gethandle]

for {set i 0} {$i < [ns_column count $db ec_products]} {incr i} {
    set col_to_print [ns_column name $db ec_products $i]
    if { [lsearch -exact $undesirable_cols $col_to_print] == -1 } {
	ns_write "$col_to_print"
	if { [lsearch -exact $required_cols $col_to_print] != -1 } {
	    ns_write " (required)"
	}
	ns_write "\n"
    }
}

ns_write "</pre>
</blockquote>
<p>
Note: <code>[join $undesirable_cols ", "]</code> are set 
automatically and should not appear in the CSV file.

</blockquote>
</blockquote>

[ad_admin_footer]

"
