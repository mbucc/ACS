# File:     /homepage/dialog-class.tcl

ad_page_contract {
    Object Oriented Generic Dialog Class File.

    @param title Title of the dialog box
    @param text Text to be included in the dialog box
    @param btn1 Display on first button
    @param btn2 Display on second button
    @param btn1target Target of first button
    @param btn2target Target of second button
    @param btn1keyvalpairs Any other hidden inputs for first button
    @param btn2keyvalpairs Any other hidden inputs for second button

    @author Usman Y. Mobin (mobin@mit.edu)
    @creation-date Tue Jan 18 19:36:14 EST 2000
    @cvs-id dialog-class.tcl,v 3.1.2.6 2000/09/22 01:38:16 kevin Exp
} {
    {title "Generic Dialog Box"}
    {text:allhtml "Part of the Arsdigita Community System<br>by Usman Y. Mobin."}
    {btn1 ""}
    {btn2 ""}
    {btn1target ""}
    {btn2target ""}
    {btn1keyvalpairs ""}
    {btn2keyvalpairs ""}
}

set btn1html ""
set btn2html ""

if {![empty_string_p $btn1]} {
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

if {![empty_string_p $btn2]} {
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

set page_content "
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

# Return the page for viewing
doc_return  200 text/html $page_content


