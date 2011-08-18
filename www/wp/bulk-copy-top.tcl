# $Id: bulk-copy-top.tcl,v 3.0 2000/02/06 03:54:50 ron Exp $
# File:        bulk-copy.tcl
# Date:        28 Nov 1999
# Author:      Jon Salz <jsalz@mit.edu>
# Description: Displays a prompt for bulk copying. It's white-on-black to be
#              a little more obvious.
# Inputs:      presentation_id

set_the_usual_form_variables

ReturnHeaders
ns_write "
<html>
<head>
<title>Bulk Copy</title>
</head>
<body bgcolor=black text=white link=white vlink=white alink=gray>
<center>
<font size=+1>
<br>
<b>Please select a presentation below to copy slides from,
<br>or <a href=\"presentation-top.tcl?presentation_id=$presentation_id\" target=\"_parent\">cancel and return to your presentation</a>.</b>
</body>
</html>
"
