# $Id: supporting-files-upload-2.tcl,v 3.0.4.1 2000/04/28 15:08:54 carsten Exp $
set_the_usual_form_variables
# upload_file, dirname, product_id

if { ![info exists upload_file] || [string compare $upload_file ""] == 0 } {
    ad_return_complaint 1 "<li> You didn't specify a file to upload.\n"
    return
}


set tmp_filename [ns_queryget upload_file.tmpfile]

set subdirectory [ec_product_file_directory $product_id]

set full_dirname "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce]$subdirectory/$dirname"

if ![regexp {([^//\]+)$} $upload_file match client_filename] {
    # couldn't find a match
    set client_filename $upload_file
}

set perm_filename "$full_dirname/$client_filename"

ns_cp $tmp_filename $perm_filename

ad_returnredirect "supporting-files-upload.tcl?[export_url_vars product_id]"
