#
# /www/education/class/admin/textbooks/search.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page shows a list of textbooks that match the search criteria
# 

ad_page_variables {
    search_string
    search_isbn
}

# either search_string or isbn must be not null


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[empty_string_p $search_string] && [empty_string_p $search_isbn]} {
    ad_return_complaint 1 "<li>You need to enter either a search string or an ISBN number."
    return
} elseif {![empty_string_p $search_string] && ![empty_string_p $search_isbn]} {
    ad_return_complaint 1 "<li>You must search by either a string or the ISBN.  You cannot search by both."
    return
}


if { ![empty_string_p $search_string] } {
    set search_text "Author/Title/Publisher \"$search_string\""
    set search_clause "
    lower(author) like [ns_dbquotevalue %[string tolower $search_string]%]
    or lower(publisher) like [ns_dbquotevalue %[string tolower $search_string]%]
    or lower(title) like [ns_dbquotevalue %[string tolower $search_string]%]"
} else {
    set search_text "ISBN \"$search_isbn\""
    set search_clause "lower(isbn) like [ns_dbquotevalue %[string tolower $search_isbn]%]"
}


# lets get a list of books so we can see whether or not a
# book matching the criteria in already in the class.  We do
# not want to do a join because we want to display different
# types of error messages

set textbook_id_list [database_to_tcl_list $db "select map.textbook_id 
      from edu_textbooks, 
           edu_classes_to_textbooks_map map 
     where class_id = $class_id 
       and map.textbook_id = edu_textbooks.textbook_id"]

set selection [ns_db select $db "
select t.textbook_id, author, publisher, 
       title, isbn
  from edu_textbooks t
 where $search_clause"]


set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Text Book Search Results</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "add.tcl" "Add a Text Book"] "Textbook Search"]
<hr>
<blockquote>
"

set count 0
# count of how many books is actually available for add
set addable 0 

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    if {!$count} {
	append return_string "
	<table cellpadding=2>
	<tr><th align=left>Title</th>
	<th align=left>Author</th>
	<th align=left>Publisher</th>
	<th align=left>ISBN</th>
	<th align=left></th>
	</tr>
	"
    }

    append return_string "
    <tr><td>$title</td>
    <td>$author</td>
    <td>$publisher</td>
    <td>$isbn</td>
    <td>"

    if {[lsearch $textbook_id_list $textbook_id] == -1} {
	append return_string "
	<a href=\"add-to-class.tcl?textbook_id=$textbook_id\">Add to class</a>"
	incr addable
    } 

    append return_string "
    </td>
    </tr>"
    incr count
}

if {$count == 0} {
    append return_string "
    <p>
    No textbooks matched your search criteria. Please <a href=\"add.tcl\">
    Add the textbook</a>
    </P>"
} else {
    append return_string "
    </table>"

    if {!$addable} {
	append return_string "
	<p>
	All textbooks that matched your search criteria are already added to $class_name. <p>
	<a href=\"add.tcl\">Add a new textbook</a>
	</P>"
    }

}

append return_string "
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string













