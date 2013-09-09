ad_page_contract {
    Lets you pick a domain to edit from all the domains.

    @author xxx
    @date unknown
    @cvs-id edit.tcl,v 3.3.2.6 2000/09/22 01:35:23 kevin Exp
} {

}

db_foreach get_all_ad_domains "select * from ad_domains" {
    append bullet_list "<li><a href=\"domain-top?domain_id=$domain_id\">$backlink_title</a>\n"
}

set page_content "<html>
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


doc_return  200 text/html $page_content
