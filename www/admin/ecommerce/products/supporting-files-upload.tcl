# $Id: supporting-files-upload.tcl,v 3.0 2000/02/06 03:21:07 ron Exp $
set_the_usual_form_variables

# product_id

set product_name [ec_product_name $product_id]

ReturnHeaders

ns_write "[ad_admin_header "Supporting Files for $product_name"]

<h2>Supporting Files for $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" "One"] "Supporting Files"]

<hr>
<h3>Current Supporting Files</h3>
<ul>
"

set db [ns_db gethandle]
set dirname [database_to_tcl_string $db "select dirname from ec_products where product_id=$product_id"]

if { ![empty_string_p $dirname] } {
    set subdirectory [ec_product_file_directory $product_id]

    set full_dirname "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce]$subdirectory/$dirname"

    # see what's in that directory
    set files [exec ls $full_dirname]
    set file_list [split $files "\n"]

    foreach file $file_list {
	ns_write "<li><a href=\"/product-file/$subdirectory/$dirname/$file\">$file</a> \[<a href=\"supporting-file-delete.tcl?[export_url_vars dirname file product_id product_name]\">delete</a>]\n"
    }

    if { [string length $file_list] == 0 } {
	ns_write "No files found.\n"
    }
} else {
    ns_write "No directory found.\n"
}

ns_write "</ul>

<h3>Upload New File</h3>

<blockquote>
"
if { [string compare $dirname ""] != 0 } {
    ns_write "<form enctype=multipart/form-data method=post action=supporting-files-upload-2.tcl>
    [export_form_vars dirname product_id]
    <input type=file size=10 name=upload_file>
    <input type=submit value=\"Continue\">
    </form>
    "
} else {
    ns_write "No directory found in which to upload files."
}

ns_write "</blockquote>

<blockquote>

Note that the picture of the product is not considered a supporting
file.  If you want to change it, go to
<a href=\"edit.tcl?[export_url_vars product_id]\">the regular product edit page</a>.

</blockquote>

[ad_admin_footer]
"
