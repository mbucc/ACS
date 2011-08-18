# $Id: index.tcl,v 3.0 2000/02/06 03:24:22 ron Exp $
ReturnHeaders

ns_write "
[ad_admin_header "Intranet administration"]
<h2>Intranet administration</h2>
[ad_context_bar_ws [list ../index.tcl "Admin Home"] "Intranet administration"]
<hr>

<ul>
  <li> <a href=[im_url_stub]/employees/admin/index.tcl>Employee administration</a>
  <li> <a href=[im_url_stub]/vacations/index.tcl>Work absences</a>
</ul>

[ad_admin_footer]
"
