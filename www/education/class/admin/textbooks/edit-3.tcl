#
# /www/education/class/admin/textbooks/edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page updates the textbooks table to reflect the changes
#

ad_page_variables {
    author
    title
    isbn
    textbook_id
    publisher
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set class_id [lindex $id_list 1]

set validation_sql "select count(tb.textbook_id)
 from edu_textbooks tb,
      edu_classes_to_textbooks_map map
where tb.textbook_id = $textbook_id 
  and map.textbook_id = tb.textbook_id
  and map.class_id = $class_id"

if {[database_to_tcl_string $db $validation_sql] == 0} {
    ad_return_complaint 1 "<li>You are not authorized to edit this book."
    return
}


if {![empty_string_p $isbn]} {
    #now lets trim the white space from the beginning and end of the isbn
    set isbn [string trim $isbn]
    
    #now we want to strip out all '-' that may appear in the string
    regsub -all {\-} $isbn "" isbn
}


ns_db dml $db "update edu_textbooks
set title='$title', 
    publisher='$publisher', 
    isbn='$isbn', 
    author='$author'
where textbook_id=$textbook_id"

ns_db releasehandle $db

ad_returnredirect "../"

