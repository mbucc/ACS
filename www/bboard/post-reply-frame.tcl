# $Id: post-reply-frame.tcl,v 3.0 2000/02/06 03:34:07 ron Exp $
set_form_variables

# refers_to

ns_return 200 text/html "

<HTML><BASE F0NTSIZE=3>

<HEAD>

<TITLE>Bulletin Board System</TITLE>

</HEAD>


<FRAMESET ROWS=\"25%,*\">

<FRAME SCROLLING=\"yes\" NAME=\"subject\" SRC=\"post-reply-top.tcl?refers_to=$refers_to\">

<FRAME SCROLLING=\"yes\" NAME=\"main\" SRC=\"post-reply-form.tcl?refers_to=$refers_to\">

</FRAMESET>

<NOFRAME>

<BODY BGCOLOR=\"#FFFFFF\" TEXT=\"#000000\">

This bulletin board system can only be used with a frames-compatible
browser.

<p>

Perhaps you should consider running Netscape 2.0?


</BODY></HTML>

</NOFRAME>

</FRAMESET>


"
