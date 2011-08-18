# $Id: set-view.tcl,v 3.0 2000/02/06 03:47:14 ron Exp $
# File:     /homepage/set-view.tcl
# Date:     Sat Jan 22 23:03:44 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Sets a cookie to determine user's preferred view

set_form_variables
# view, filesystem_node

ns_write "HTTP/1.0 302 FOUND
MIME-Version: 1.0
Content-Type: text/html
Set-Cookie: homepage_view=$view; path=/; expires=05-Mar-2079 05:45:00 GMT
Location: index.tcl?filesystem_node=$filesystem_node
"
