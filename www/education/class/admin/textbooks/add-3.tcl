#
# /www/education/class/admin/textbooks/add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page inserts the new textbook into the database

ad_page_variables {
    title
    author
    textbook_id
    {isbn ""}
    {comments ""}
    {publisher ""}
    {required_p f}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


#lets check the input
set exception_text ""
set exception_count 0

if {[empty_string_p $title]} {
    incr exception_count
    append exception_text "<li>You must provide a title."
}

if {[empty_string_p $author]} {
    incr exception_count
    append exception_text "<li>You must provide an author."
}

if {[empty_string_p $textbook_id]} {
    incr exception_count
    append exception_text "<li>You must provide a text book identification number."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

# check for a double-click
if {[database_to_tcl_string $db "select count(textbook_id) from edu_textbooks where textbook_id = $textbook_id"] > 0} {
    ad_returnredirect ""
    return
}


if {![empty_string_p $isbn]} {
    #now lets trim the white space from the beginning and end of the isbn
    set isbn [string trim $isbn]
    
    #now we want to strip out all '-' that may appear in the string
    regsub -all {\-} $isbn "" isbn
}


ns_db dml $db "begin transaction"

ns_db dml $db "insert into edu_textbooks (
                               textbook_id,
                               title,
                               author,
                               publisher,
                               isbn)
                           values (
                               $textbook_id,
                               [ns_dbquotevalue $title],
                               [ns_dbquotevalue $author],
                               [ns_dbquotevalue $publisher],
                               '$isbn')"

ns_db dml $db "insert into edu_classes_to_textbooks_map (
                            class_id, 
                            textbook_id,
                            comments,
                            required_p)
                       values (
                            $class_id,
                            $textbook_id,
                            [ns_dbquotevalue $comments],
                            '$required_p')"

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect ""



