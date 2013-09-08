# /www/neighbor/one-category.tcl
ad_page_contract {
    This is a legacy file purely for photo.net; it redirects people
    over to the relevant page in /one-subcategory.tcl (in case there
    were bookmarks).

    @author Philip Greenspun (philg@mit.edu)
    @creation-date 1 January 1998
    @cvs-id one-category.tcl,v 3.2.2.1 2000/07/25 09:19:24 kevin Exp
    @param subcategory_1 the subcategory to look for
} {
    subcategory_1:notnull
}

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
    ad_returnredirect "one-subcategory?category_id=$category_id&id=$subcategory_id"
} else {
    ad_returnredirect /neighbor/opc?category_id=0
}
