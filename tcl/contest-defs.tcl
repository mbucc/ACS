# $Id: contest-defs.tcl,v 3.0 2000/02/06 03:13:05 ron Exp $
proc ad_contest_admin_footer {} {
    set owner [ad_parameter ContestAdminOwner contest [ad_admin_owner]]
    return "<hr>
<a href=\"mailto:$owner\"><address>$owner</address></a>
</body>
</html>"
}


