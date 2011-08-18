# $Id: one-category.tcl,v 3.0.4.1 2000/04/28 15:11:14 carsten Exp $
# this is a legacy file purely for photo.net; it redirects people 
# over to the relevant page in /one-subcategory.tcl (in case there were
# bookmarks)

set_the_usual_form_variables

# subcategory_1

# we know that it is photographic
set category_id 0

# we now need to know which subcat
case $subcategory_1  {
    "Camera Shops" { set subcategory_id 2 } 
    "Individuals selling cameras on the Internet" { set subcategory_id 3 } 
    "Workshops" { set subcategory_id 8 } 
    "Wedding Photographers" { set subcategory_id 7 } 
    "Product and/or Manufacturer" { set subcategory_id 6 } 
    "Processing Laboratories" { set subcategory_id 5 } 
    "Camera Repair" { set subcategory_id 1 } 
    "Miscellaneous" { set subcategory_id 7 } 
}

if [info exists subcategory_id] {
    ad_returnredirect "one-subcategory.tcl?category_id=$category_id&id=$subcategory_id"
} else {
    ad_returnredirect /neighbor/opc.tcl?category_id=0
}
