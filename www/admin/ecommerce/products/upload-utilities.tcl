# $Id: upload-utilities.tcl,v 3.0 2000/02/06 03:21:12 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Upload Utilities"]

<h2>Upload Utilities</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Upload Utilities"]

<hr>

There are three utilities provided with the ecommerce module that can
help you load you catalog data into the database:

<ul>
<li><a href=\"upload.tcl\">Product Loader</a>
<li><a href=\"extras-upload.tcl\">Product Extras Loader</a>
<li><a href=\"categories-upload.tcl\">Product Category Map Loader</a>
</ul>

<p>The product loader uploads a CSV file that contains one line per product
in your catalog.  Each line has fields corresponding to a subset of the
columns in the ec_products table.  The first line of the CSV file is a
header that defines which fields are being loaded and the order that
they appear in the CSV file.  The remaining lines contain the product
data.

<p>The product extras loader is similar to the product loader except it
loads data into ec_custom_product_field_values, the table which contains
the values for each product of the custom fields you've added.
The file format is
also similar to that of the product data CSV file.

<p><b>Note:</b>You must load the products and define the extra fields
you wish to use before you can load the product extras.

<p>The product category map loader creates the mappings between products
and categories and products and subcategories (specifically, it inserts
rows into ec_category_product_map and ec_subcategory_product_map.)  The
CSV file you create for uploading should consist of product id and
category or subcategory names, one per row.  This program attempts to be
smart by using the SQL like function to resolve close matches between
categories listed in the CSV file and those known in the database.

<p><b>Note:</b>You must create the categories and subcategories before
you can use the product category map loader.

[ad_admin_footer]
"
