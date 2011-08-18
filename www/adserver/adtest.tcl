# $Id: adtest.tcl,v 3.0 2000/02/06 03:32:04 ron Exp $
ReturnHeaders

ns_write "<html>
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
