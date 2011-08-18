# $Id: returncode.tcl,v 3.0 2000/02/06 03:27:27 ron Exp $
#expected variable is one of
#code_list mycode_add mycode_add_insert mycode_edit mycode_edit_insert
#also definitely base_name and base_dir_name and whattodo
set_the_usual_form_variables 0
ReturnHeaders text/plain

if [info exists code_list] {
    set mycode $code_list
}
if [info exists mycode_add] {
    set mycode $mycode_add
}
if [info exists mycode_add_insert] {
    set mycode $mycode_add_insert
}
if [info exists mycode_edit] {
    set mycode $mycode_edit
}
if [info exists mycode_edit_insert] {
    set mycode $mycode_edit_insert
}

if [string match $whattodo "Save code"] {
    set directory [ns_info pageroot]
    append directory "/$base_dir_name"
    set filename "/$directory/$base_name"
    if {[string first ".." $filename] != -1} {
    ns_write "#We're sorry, but for security reasons we \n"
    ns_write "#will not attempt to save this file,\n"
    ns_write "#because we have detected a \"..\" in the filename\n"
    ns_write "#$filename. \n\n"
    } else {
    # we might need to make the directory
    if ![file exists $directory] {
        if [catch {ns_mkdir $directory} errmsg] {
        ns_write "# Tried to make $directory, but failed with message: $errmsg\n";
        } else {
        ns_write "# created directory $directory\n"
        }
    }
    if [catch {set filetosavein [open $filename w]} errmsg] {   
        ns_write "#There was an error in opening $filename.\n"
        ns_write "#The error message was: \n# $errmsg\n\n"
    } else {
        puts $filetosavein $mycode
        ns_write "#$base_name saved successfully \n#in $filename.\n\n"
        }   
    }
}


#set roundonequote [ns_quotehtml $mycode]
#regsub -all "amp;" $roundonequote "" roundtwoquote
#set roundthreequote ""
#append roundthreequote "<pre>" $roundtwoquote "</pre>"

ns_write "$mycode"