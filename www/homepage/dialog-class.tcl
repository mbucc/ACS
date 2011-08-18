# $Id: dialog-class.tcl,v 3.0 2000/02/06 03:46:39 ron Exp $
# File:     /homepage/dialog-class.tcl
# Date:     Tue Jan 18 19:36:14 EST 2000
# Location: 42Å∞21'N 71Å∞04'W
# Location: 80 PROSPECT ST CAMBRIDGE MA 02139 USA
# Author:   mobin@mit.edu (Usman Y. Mobin)
# Purpose:  Object Oriented Generic Dialog Class File.

set_the_usual_form_variables 0
# title, text, btn1, btn2, btn1target, btn2target, btn1keyvalpairs, btn2keyvalpairs

if {![info exists title] || [empty_string_p $title]} {
    set title "Generic Dialog Box"
}

if {![info exists text] || [empty_string_p $text]} {
    set text "Part of the Arsdigita Community System<br>by Usman Y. Mobin."
}

if {![info exists btn1] || [empty_string_p $btn1]} {
    set btn1 ""
}

if {![info exists btn2] || [empty_string_p $btn2]} {
    set btn2 ""
}

if {![info exists btn1target] || [empty_string_p $btn1target]} {
    set btn1target ""
}

if {![info exists btn2target] || [empty_string_p $btn2target]} {
    set btn2target ""
}

if {![info exists btn1keyvalpairs] || [empty_string_p $btn1keyvalpairs]} {
    set btn1keyvalpairs ""
}

if {![info exists btn2keyvalpairs] || [empty_string_p $btn2keyvalpairs]} {
    set btn2keyvalpairs ""
}


set btn1html ""
set btn2html ""

if {$btn1 != ""} {
    set btn1pass ""
    for {set cx 0} {$cx < [llength $btn1keyvalpairs]} {set cx [expr $cx+2]} {
	append btn1pass "
	<input type=hidden name=[lindex $btn1keyvalpairs $cx]
                           value=[lindex $btn1keyvalpairs [expr $cx+1]]>
	"
    }
    set btn1html "
    <td>
    <form method=get action=$btn1target>
    $btn1pass
    <input type=submit value=\"$btn1\">
    </form>
    </td>
    "
}

if {$btn2 != ""} {
    set btn2pass ""
    for {set cx 0} {$cx < [llength $btn2keyvalpairs]} {set cx [expr $cx+2]} {
	append btn2pass "
	<input type=hidden name=[lindex $btn2keyvalpairs $cx]
                           value=[lindex $btn2keyvalpairs [expr $cx+1]]>
	"
    }
    set btn2html "
    <td>
    <form method=get action=$btn2target>
    $btn2pass
    <input type=submit value=\"$btn2\">
    </form>
    </td>
    "
}

set btnhtml ""

if {"$btn1$btn2" != ""} {
    set btnhtml "
                                <table border=0
                                       cellspacing=0
                                       cellpadding=0>
                                         <tr align=center>
                                         $btn1html
                                         $btn2html
                                         </tr>
                                </table>
    "
}

ReturnHeaders

ns_write "
<html>

<head>
<title>$title</title>
<meta name=\"description\" content=\"Usman Y. Mobin's generic dialog class.\">
</head>

<body bgcolor=FFFFFF text=000000 link=FFCE00 vlink=842C2C alink=B0B0B0>
<div align=center><center>

<table border=0 
        cellspacing=0 
        cellpadding=0 
        width=100%
        height=100%>
                <tr>
                <td align=center valign=middle>

                <table border=0
                       cellspacing=0
                       cellpadding=0>
                        <tr bgcolor=000080>
                        <td>
                                <table border=0
                                       cellspacing=0
                                       cellpadding=6>
                                        <tr bgcolor=000080>
                                        <td>
                                               <font color=FFFFFF>
                                               $title
                                               </font>
                                        </td>
                                        </tr>
                                </table> 
                        </td>
                        </tr>
                        <tr bgcolor=C0C0C0>
                        <td align=center>
                                <table border=0
                                       cellspacing=0
                                       cellpadding=25>
                                         <tr align=center>
                                         <td>
                                                  $text
                                         </td>
                                         </tr>
                                </table>
                                         $btnhtml
                        </td>
                        </tr>
                </table>

                </td>
                </tr>
</table>

</center></div>
</body>
</html>
"





