# $Id: supporting-file-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:54 carsten Exp $
set_the_usual_form_variables
# dirname file product_id

set subdirectory [ec_product_file_directory $product_id]

set full_dirname "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce]$subdirectory/$dirname"

exec rm $full_dirname/$file

ad_returnredirect "supporting-files-upload.tcl?[export_url_vars product_id]"