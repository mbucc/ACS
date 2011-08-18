# $Id: set-view-nh.tcl,v 3.0 2000/02/06 03:47:13 ron Exp $
# File:     /homepage/set-view-nh.tcl
# Date:     Sat Jan 22 23:03:44 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Sets a cookie to determine user's preferred view

set_form_variables
# view, neighborhood_node

ns_write "HTTP/1.0 302 FOUND
MIME-Version: 1.0
Content-Type: text/html
Set-Cookie: neighborhood_view=$view; path=/; expires=05-Mar-2079 05:45:00 GMT
Location: neighborhoods.tcl?neighborhood_node=$neighborhood_node
"
