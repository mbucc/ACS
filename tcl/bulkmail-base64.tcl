# /tcl/bulkmail-base64.tcl

ad_library {

    Copyright 1995-8 Sun Microsystems Laboratories All rights reserved.
    Copyright 1995 Xerox Corporation All rights reserved.
    License is granted to copy, to use, and to make and to use derivative
    works for any purpose, provided that the copyright notice and this
    license notice is included in all copies and any derivatives works and
    in all  related documentation.  Xerox and Sun grant no other licenses
    expressed or implied and the licensee acknowledges that Xerox and Sun
    have no  liability for licensee's use or for any derivative works  made
    by licensee. The Xerox and Sun names shall not be used in any
    advertising or the like without their written permission.
    This software is provided AS IS.
    
    XEROX CORPORATION AND SUN MICROSYSTEMS DISCLAIM AND LICENSEE
    AGREES THAT ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
    NOTWITHSTANDING ANY OTHER PROVISION CONTAINED HEREIN, ANY LIABILITY FOR DAMAGES
    RESULTING FROM THE SOFTWARE OR ITS USE IS EXPRESSLY DISCLAIMED, INCLUDING
    CONSEQUENTIAL OR ANY OTHER INDIRECT DAMAGES, WHETHER ARISING IN CONTRACT, TORT
    (INCLUDING NEGLIGENCE) OR STRICT LIABILITY, EVEN IF XEROX CORPORATION OR
    SUN MICROSYSTEMS IS ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
    
    The enclosed code is derived from base64.tcl, which is part of the exmh
    distribution, covered by the copyrights and license above.
    
    share globals for base64 encoding, so we don't do it everytime.

    @cvs-id bulkmail-base64.tcl,v 3.2.2.1 2000/09/14 07:36:29 ron Exp
}

ns_share bulkmail_base64 bulkmail_base64_en
set i 0
foreach char {A B C D E F G H I J K L M N O P Q R S T U V W X Y Z \
	a b c d e f g h i j k l m n o p q r s t u v w x y z \
	0 1 2 3 4 5 6 7 8 9 + /} {
    set bulkmail_base64($char) $i
    set bulkmail_base64_en($i) $char
    incr i
}

proc_doc bulkmail_base64_encode { string } "Encode a string in base64" {

    ns_share bulkmail_base64_en

    set result {}
    set state 0
    set length 0
    foreach {c} [split $string {}] {
	scan $c %c x
	switch [incr state] {
	    1 {	append result $bulkmail_base64_en([expr {($x >>2) & 0x3F}]) }
	    2 { append result $bulkmail_base64_en([expr {(($old << 4) & 0x30) | (($x >> 4) & 0xF)}]) }
	    3 { append result $bulkmail_base64_en([expr {(($old << 2) & 0x3C) | (($x >> 6) & 0x3)}])
	    append result $bulkmail_base64_en([expr {($x & 0x3F)}])
	    set state 0}
	}
	set old $x
	incr length
	if {$length >= 72} {
	    append result \n
	    set length 0
	}
    }
    set x 0
    switch $state {
	0 { # OK }
	1 { append result $bulkmail_base64_en([expr {(($old << 4) & 0x30)}])== }
	2 { append result $bulkmail_base64_en([expr {(($old << 2) & 0x3C)}])=               }
    }
    return $result
}

proc_doc bulkmail_base64_decode { string } "Decode a base64-encoded string" {
    ns_share bulkmail_base64

    set output {}
    set group 0
    set j 18
    foreach char [split $string {}] {
	if [string compare $char "="] {
	    set bits $bulkmail_base64($char)
	    set group [expr {$group | ($bits << $j)}]
	}

	if {[incr j -6] < 0} {
		scan [format %06x $group]] %2x%2x%2x a b c
		append output [format %c%c%c $a $b $c]
		set group 0
		set j 18
	}
    }
    return $output
}
