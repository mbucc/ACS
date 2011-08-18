# $Id: add-2.tcl,v 3.1 2000/03/07 04:11:01 eveander Exp $
set_the_usual_form_variables
# product_name, sku, one_line_description, detailed_description, color_list,
# size_list, style_list, search_keywords, url, price,
# present_p, available_date, shipping, shipping_additional, weight, stock_status
# and all active custom fields (except ones that are boolean and weren't filled in)
# and price$user_class_id for all the user classes
# - categorization is a select multiple, so that will be dealt with separately
# - the dates are special (as usual) so they'll have to be "put together"

# first do error checking
# product_name is mandatory
set exception_count 0
set exception_text ""
if { ![info exists product_name] || [empty_string_p $product_name] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the name of the product.\n"
}
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# categorization is a select multiple, so deal with that separately
set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0

set categorization_list [list]
while { $form_counter < $form_size} {
    if { [ns_set key $form $form_counter] == "categorization" } {
	lappend categorization_list [ns_set value $form $form_counter]
    }
    incr form_counter
}

# break categorization into category_id_list, subcategory_id_list, subsubcategory_id_list
set category_id_list [list]
set subcategory_id_list [list]
set subsubcategory_id_list [list]
foreach categorization $categorization_list {
    if ![catch {set category_id [lindex $categorization 0] } ] {
	if { [lsearch -exact $category_id_list $category_id] == -1 && ![empty_string_p $category_id]} {
	    lappend category_id_list $category_id
	}
    }
    if ![catch {set subcategory_id [lindex $categorization 1] } ] {
	if {[lsearch -exact $subcategory_id_list $subcategory_id] == -1 && ![empty_string_p $subcategory_id]} {
	    lappend subcategory_id_list $subcategory_id
	}
    }
    if ![catch {set subsubcategory_id [lindex $categorization 2] } ] {
	if {[lsearch -exact $subsubcategory_id_list $subsubcategory_id] == -1 && ![empty_string_p $subsubcategory_id] } {
	    lappend subsubcategory_id_list $subsubcategory_id
	}
    }
}

# Now deal with dates.
# The column available_date is known to be a date.
# Also, some of the custom fields may be dates.

set date_fields [list "available_date"]

set db [ns_db gethandle]
set additional_date_fields [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where column_type='date' and active_p='t'"]

set all_date_fields [concat $date_fields $additional_date_fields]

foreach date_field $all_date_fields {
    if [catch  { ns_dbformvalue $form $date_field date $date_field} errmsg ] {
	set $date_field ""
    }
}

# one last manipulation of data is needed: get rid of "http://" if that's all that's
# there for the url (since that was the default value)
if { [string compare $url "http://"] == 0 } {
    set url ""
}

# We now have all values in the correct form

# Things to generate:

# 1. generate a product_id
set product_id [database_to_tcl_string $db "select ec_product_id_sequence.nextval from dual"]

# 2. generate a directory name (and create the directory) to store pictures
# and other supporting product info

# let's have dirname be the first four letters (lowercase) of the product_name
# followed by the product_id (for uniqueness)
regsub -all {[^a-zA-Z]} $product_name "" letters_in_product_name 
set letters_in_product_name [string tolower $letters_in_product_name]
if [catch {set dirname "[string range $letters_in_product_name 0 3]$product_id"}] {
    #maybe there aren't 4 letters in the product name
    set dirname "$letters_in_product_name$product_id"
}

# Get the directory where dirname is stored
set subdirectory "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce][ec_product_file_directory $product_id]"
ec_assert_directory $subdirectory

set full_dirname "$subdirectory/$dirname"
ec_assert_directory $full_dirname

# if an image file has been specified, upload it into the
# directory that was just created and make a thumbnail (using
# dimensions specified in parameters/whatever.ini)

if { [info exists upload_file] && ![string compare $upload_file ""] == 0 } {
    
    # this takes the upload_file and sticks its contents into a temporary
    # file (will be deleted when the thread ends)
    set tmp_filename [ns_queryget upload_file.tmpfile]
    

    # so that we'll know if it's a gif or a jpg
    set file_extension [file extension $upload_file]

    # copies this temp file into a permanent file
    set perm_filename "$full_dirname/product$file_extension"
    ns_cp $tmp_filename $perm_filename
    
    # create thumbnails
    # thumbnails are all jpg files
    
    # set thumbnail dimensions
    if [catch {set thumbnail_width [ad_parameter ThumbnailWidth ecommerce]} ] {
	if [catch {set thumbnail_height [ad_parameter ThumbnailHeight ecommerce]} ] {
	    set convert_dimensions "100x10000"
	} else {
	    set convert_dimensions "10000x$thumbnail_height"
	}
    } else {
	set convert_dimensions "${thumbnail_width}x10000"
    }

    set perm_thumbnail_filename "$full_dirname/product-thumbnail.jpg"

    exec /usr/local/bin/convert -geometry $convert_dimensions $perm_filename $perm_thumbnail_filename
}

set linked_thumbnail [ec_linked_thumbnail_if_it_exists $dirname]

# Need to let them select template based on category

ReturnHeaders
ns_write "[ad_admin_header "Add a Product, Continued"]

<h2>Add a Product, Continued</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Add Product"]

<hr>
<form method=post action=add-3.tcl>
[export_form_vars product_name sku category_id_list subcategory_id_list subsubcategory_id_list one_line_description detailed_description color_list size_list style_list search_keywords url price present_p available_date shipping shipping_additional weight linked_thumbnail product_id dirname stock_status]
"

# also need to export custom field values
set additional_variables_to_export [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where active_p='t'"]

foreach user_class_id [database_to_tcl_list $db "select user_class_id from ec_user_classes"] {
    lappend additional_variables_to_export "price$user_class_id"
}

eval "ns_write \"\[export_form_vars $additional_variables_to_export\]\n\""


# create the template drop-down list

ns_write "

<h3>Select a template to use when displaying this product.</h3>

<p>

If none is
selected, the product will be displayed with the system default template.<br>
<blockquote>
[ec_template_widget $db $category_id_list]
</blockquote>
<p>


<center>
<input type=submit value=\"Submit\">
</center>
</form>

[ad_admin_footer]
"