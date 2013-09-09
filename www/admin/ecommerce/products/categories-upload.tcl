#  www/admin/ecommerce/products/categories-upload.tcl
ad_page_contract {
  This page uploads a CSV file containing product category "hints" and
  creates product category mappings. This is probably not generally
  useful for people who have clean data...

  The file format should be:

    product_id_1, category_description_1
    product_id_2, category_description_2
    ...
    product_id_n, category_description_n

  Where each line contains a product id, category name pair. There may
  be multiple lines for a single product id which will cause the
  product to get placed in multiple categories (or subcategories)

  This program attempts to match the category name to an existing
  category using looses matching (SQL: like) because some data is
  really nasty with lots of different formats for similar categories.
  Maybe loose matching should be an option.

  If a subcategory match is found, the product is placed into the
  matching subcategory as well as the parent category of the matching
  subcategory. If no match is found for a product, no mapping entry is
  made. A product id may appear on multiple lines to place a product
  in multiple categories.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id categories-upload.tcl,v 3.1.6.1 2000/07/22 07:57:37 ron Exp
} {
}

doc_body_append "[ad_admin_header "Upload Category Mapping Data"]

<h2>Upload Catalog Category Mapping Data</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Upload Category Mapping Data"]

<hr>

<blockquote>

<form enctype=multipart/form-data action=categories-upload-2 method=post>
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

This page uploads a CSV file containing product category \"hints\" and creates product category mappings.  
This is probably not generally useful for people who have clean data...
<p>
The file format should be:
<p>
<blockquote>
<code>product_id_1, category_description_1<br>
product_id_2, category_description_2<br>
...<br>
product_id_n, category_description_n</code>
</blockquote>
<p>
Where each line contains a product id, category name pair.  There may be multiple lines for a single product id
which will cause the product to get placed in multiple categories (or subcategories)
<p>
This program attempts to match the category name to an existing category using looses matching (SQL: like)
because some data is really nasty with lots of different formats for similar categories.
<p>
If a subcategory match is found, the product is placed into the matching subcategory as well as the parent category  
of the matching subcategory. If no match is found for a product, no mapping entry is made.

</blockquote>
</blockquote>

[ad_admin_footer]
"
