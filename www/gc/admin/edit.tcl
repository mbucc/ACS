# /www/gc/admin/edit.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id edit.tcl,v 3.3.2.7 2000/09/22 01:38:00 kevin Exp
} {}

set sql "select * from ad_domains"
db_foreach gc_admin_edit_domain_list $sql {    
    append bullet_list "<li><a href=\"domain-top?domain_id=$domain_id\">$domain</a>\n"
}

db_release_unused_handles
doc_return  200 text/html "<html>
<head>
<title>Pick a Domain</title>
</head>
<body bgcolor=#ffffff text=#000000>
<h2>Pick a Domain</h2>

<hr>

<ul>

$bullet_list

</ul>

<hr>
<a href=\"http://www-swiss.ai.mit.edu/philg/\"><address>philg@mit.edu</address></a>

</body>
</html>"
