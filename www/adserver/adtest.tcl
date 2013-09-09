# /www/adserver/adtest.tcl

ad_page_contract {
    test page

    @author ron
    @creation-date 02/06/2000
    @cvs-id adtest.tcl,v 3.0.12.2 2000/09/22 01:36:39 kevin Exp
} {
    
}

doc_return 200 text/html "<html>
<head>
<title>Adserver Test Page</title>
</head>
<body>
<h2>Ad Server Test Page</h2>
<p>You should see an ad below:

<br>

[adserver_get_ad_html "test"]

</body>
</html>
"




