# /webmail/folder-create.tcl
# by jsc@arsdigita.com (2000-02-23)

# Present form to create a new folder.

ad_page_variables target

ns_return 200 text/html "[ad_header "Create New Folder"]
<h2>Create New Folder</h2>

 [ad_context_bar_ws [list "index.tcl" "WebMail"] "Create New Folder"]

<hr>

<form action=\"folder-create-2.tcl\" method=POST>
 [export_form_vars target]

Folder Name: <input type=text size=50 name=folder_name><br>

</form>

 [ad_footer]
"

