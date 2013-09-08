# /www/admin/gc/edit-categories.tcl
ad_page_contract {
    @author philg@mit.edu
    @cvs_id edit-categories.tcl,v 3.3.2.4 2000/09/22 01:35:23 kevin Exp
} {
}

db_foreach domain_info "select domain_id, full_noun from ad_domains" {

    append bullet_list "<li><a href=\"domain-top?domain_id=$domain_id\">$full_noun</a>\n"
}


set page_content "<html>
<head>
<title>Pick a Domain</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Pick a Domain</h2>

[ad_admin_context_bar [list "" "Classifieds"] "Edit Categories"]
<hr>

<ul>

$bullet_list

</ul>

[ad_admin_footer]

</body>
</html>"


doc_return  200 text/html $page_content
db_release_unused_handles
