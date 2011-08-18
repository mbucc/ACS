# $Id: returncodeall.tcl,v 3.0 2000/02/06 03:27:29 ron Exp $
#expected variable is all of
#mycode_list mycode_add mycode_add_insert mycode_edit mycode_edit_insert
#also definitely base_file_name and base_dir_name and whattodo
set_the_usual_form_variables 0


ReturnHeaders

ns_write "

[ad_admin_header "Saving the $base_file_name module"]

<h2>Saving the $base_file_name module.</h2>

part of the <a href=\"index.tcl\">Prototype Builder</a>

<hr>
<h3>Attempting to save the files...</h3>"


if {[string first ".." $base_dir_name] != -1} {
      ns_write "We're sorry, but for security reasons we \n"
      ns_write "will not attempt to save these file,\n"
      ns_write "because we have detected a \"..\" in the directoryname\n"
      ns_write "$base_dir_name. \n\n<p>"
} else {
    # we might need to make the directory

    set directory [ns_info pageroot]
    set directory "$directory/$base_dir_name"
    if ![file exists $directory] {
         if [catch {ns_mkdir $directory} errmsg] {
             ns_write "<P>Tried to make $directory, but failed with me\
ssage: $errmsg<P>\n";
         } else {
             ns_write "<P>created directory $directory<P>\n"
     }
     }
    foreach filetype \
        {-list.tcl -add.tcl -add-2.tcl -view.tcl -edit.tcl -edit-2.tcl} {
    set filename "$directory/$base_file_name$filetype"
    set varname mycode
    switch -- $filetype {
    -list.tcl {append varname _list}
        -add.tcl  {append varname _add}
        -add-2.tcl  {append varname _add_insert}
        -view.tcl  {append varname _view}
        -edit.tcl  {append varname _edit}
        -edit-2.tcl  {append varname _edit_insert}
    }
    if [catch {set filetosavein [open $filename w]} errmsg] {
    ns_write "There was an error in opening $filename.\n<br>"
        ns_write "The error message was: \n $errmsg\n\n<p>"
} else {
    puts $filetosavein [set $varname]
  ns_write "$base_file_name$filetype saved successfully \nin $filename.\n\n<p>"
}   }   }

ns_write "<h4>If everything went well, you can now go to the <a href=\"/$base_dir_name/${base_file_name}-list.tcl\">front 
page</a> of the module you just created.<h4>
</ul>
[ad_admin_footer]"

