# /wp/bulk-copy-top.tcl
ad_page_contract {
    Displays a prompt for bulk copying. It's white-on-black to be \
    a little more obvious.    
    @cvs-id bulk-copy-top.tcl,v 3.1.6.6 2000/09/22 01:39:29 kevin Exp
    @creation-date 28 Nov 1999
    @author Jon Salz <jsalz@mit.edu>
    @param presentation_id
} {
    presentation_id:naturalnum,notnull
}
# modified by jwong@arsdigita.com on 12 Jul 2000 for ACS 3.4 upgrade


 
doc_return  200 "text/html" "
<html>
<head>
<title>Bulk Copy</title>
</head>
<body bgcolor=black text=white link=white vlink=white alink=gray>
<center>
<font size=+1>
<br>
<b>Please select a presentation below to copy slides from,
<br>or <a href=\"presentation-top?presentation_id=$presentation_id\" target=\"_parent\">cancel and return to your presentation</a>.</b>
</body>
</html>
"
