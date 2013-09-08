# /webmail/folder-create.tcl

ad_page_contract {
    Present form to create a new folder.
    @author Jin Choi (jsc@arsdigita.com)
    @creation-date 2000-02-23
    @cvs-id folder-create.tcl,v 1.2.6.3 2000/09/22 01:39:27 kevin Exp
} {
    target
}

doc_return  200 text/html "[ad_header "Create New Folder"]
<h2>Create New Folder</h2>

 [ad_context_bar_ws [list "index.tcl" "WebMail"] "Create New Folder"]

<hr>

<form action=\"folder-create-2\" method=POST>
 [export_form_vars target]

Folder Name: <input type=text size=50 name=folder_name><br>

</form>

 [ad_footer]
"

