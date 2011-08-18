# $Id: index.tcl,v 3.0.4.1 2000/04/28 15:09:17 carsten Exp $
set db [ns_db gethandle]

#we aren't going to do much with this besides pass it on
#set user_id [ad_verify_and_get_user_id]
#if {[string compare $user_id 0] == 0} {
#    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
#}

ReturnHeaders

ns_write "
<html>
<head>
<title>Prototype Pages</title>
</head>
<body bgcolor=\"white\" text=\"black\">


<h2>Generate Prototype pages for a Table</h2>

<hr>
Confused? Read about <a href=\"doctest.html\">how to use</a> this module.<br>
Intrigued? Get a <a href=\"prototype.tar.gz\">copy</a> for yourself.

<h3>Pick a Table</h3>

<form method=POST action=\"tableinfo.tcl\">

Please tell us the name of the table:<br>
<input type=text size=30 name=table_name>
<p>
Or choose a table from this list:<br>
[ns_htmlselect -sort Table [ns_table list $db]]
<p>
<br>
Please tell us a base directory name for the tcl files you wish to create:<br>
[ns_info pageroot]/<input name=base_dir_name size=30 value=\"\" type=text><br>\n  
Please tell us a base filename for the pages you wish to create:<br>
<input name=base_file_name size=30 type=text><br>\n  
(for instance, if you choose <i>authors</i> for a base<br> filename you
will get an option to be returned,<br> among others, 
the code for <i>authors-add.tcl</i>) "


ns_write "<p>
<input type=submit value=\"Proceed\">
</form>
<hr>
<address>rfrankel@athena.mit.edu</address>
</body>
</html>

" 

