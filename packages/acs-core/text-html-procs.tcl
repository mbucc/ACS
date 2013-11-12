ad_library {
    Contains procs used to manipulate chunks of text and html,
    most notably converting between them.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
    @cvs-id text-html-procs.tcl,v 1.1.2.25 2000/11/13 23:03:58 lars Exp
}


####################
#
# text -> HTML
#
####################

ad_proc -public ad_text_to_html {
    -no_links:boolean
    text
} {
    Converts plaintext to html. Also translates any recognized
    email addresses or URLs into a hyperlink.

    @param no_links will prevent it from highlighting

    @author Branimir Dolicki (branimir@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {

    if { !$no_links_p } {
	# We start by putting a space in front so our URL/email highlighting will work
	# for URLs/emails right in the beginning of the text.
	set text " $text"

	# if something is " http://" or " https://"
	# we assume it is a link to an outside source.
	
	# (bd) The only purpose of thiese sTaRtUrL and
	# eNdUrL markers is to get rid of trailing dots,
	# commas and things like that.  Note that there
	# is a TAB before and after each marker.
	
	regsub -nocase -all {([^a-zA-Z0-9]+)(http://[^\(\)"<> 
	]+)} $text {\1	sTaRtUrL\2eNdUrL	} text
	regsub -nocase -all {([^a-zA-Z0-9]+)(https://[^\(\)"<> 
	]+)} $text {\1	sTaRtUrL\2eNdUrL	} text
	regsub -nocase -all {([^a-zA-Z0-9]+)(ftp://[^\(\)"<> 
	]+)} $text {\1	sTaRtUrL\2eNdUrL	} text
	
	# email links have the form xxx@xxx.xxx
	regsub -nocase -all {([^a-zA-Z0-9]+)([^\(\) 
	:;,@<>]+@[^\(\) 
	.:;,@<>]+[.][^\(\) 
	:;,@<>]+)} $text {\1	sTaRtEmAiL\2eNdEmAiL	} text

    }

    # At this point, before inserting some of our own <, >, and "'s
    # we quote the ones entered by the user:
    set text [ad_quotehtml $text]

    # turn CRLFCRLF into <P>
    if { [regsub -all "\015\012\015\012" $text "<p>" text] == 0 } {
	# try LFLF
	if { [regsub -all "\012\012" $text "<p>" text] == 0 } {
		# try CRCR
	    regsub -all "\015\015" $text "<p>" text
	}
    }

    if { !$no_links_p } {
	# Dress the links and emails with A HREF
	regsub -all {([]!?.:;,<>\(\)\}-]+)(eNdUrL	)} $text {\2\1} text
	regsub -all {([]!?.:;,<>\(\)\}-]+)(eNdEmAiL	)} $text {\2\1} text
	regsub -all {	sTaRtUrL([^	]*)eNdUrL	} $text {<a href="\1">\1</a>} text
	regsub -all {	sTaRtEmAiL([^	]*)eNdEmAiL	} $text {<a href="mailto:\1">\1</a>} text
	set text [string trimleft $text]
    }

    # Start text off with a paragraph tag so we can format text consistently
    # by styling a <p> tag.  Otherwise, we get this:
    #
    # 	<blockquote>
    # 		First para.
    # 		<p>
    # 		Second para.
    # 	</blockquote>
    #
    set text "<p>$text"
	
    return $text
}

proc_doc -public ad_quotehtml { arg } {

    Quotes ampersands, double-quotes, and angle brackets in $arg.
    Analogous to ns_quotehtml except that it quotes double-quotes (which
    ns_quotehtml does not).

} {
    # we have to do & first or we'll hose ourselves with the ones lower down
    regsub -all & $arg \\&amp\; arg
    regsub -all \" $arg \\&quot\; arg
    regsub -all < $arg \\&lt\; arg
    regsub -all > $arg \\&gt\; arg
    return $arg
}



####################
#
# HTML -> HTML
#
####################

#
# lars@pinds.com, 19 July 2000:
# Should this proc change name to something in line with the rest
# of the library?
#

ad_proc -private util_close_html_tags {
    html_fragment
    {break_soft 0}
    {break_hard 0}
} {
    Given an HTML fragment, this procedure will close any tags that
    have been left open.  The optional arguments let you specify that
    the fragment is to be truncated to a certain number of displayable
    characters.  After break_soft, it truncates and closes open tags unless
    you're within non-breaking tags (e.g., Af).  After break_hard displayable
    characters, the procedure simply truncates and closes any open HTML tags
    that might have resulted from the truncation.
    <p>
    Note that the internal syntax table dictates which tags are non-breaking.
    The syntax table has codes:
    <ul>
    <li>  nobr --  treat tag as nonbreaking.
    <li>  discard -- throws away everything until the corresponding close tag.
    <li>  remove -- nuke this tag and its closing tag but leave contents.
    <li>  close -- close this tag if left open.
    </ul>

    @param break_soft the number of characters you want the html fragment
    truncated to. Will allow certain tags (A, ADDRESS, NOBR) to close first.

    @param break_hard the number of characters you want the html fragment
    truncated to. Will truncate, regardless of what tag is currently in action.

    @author Jeff Davis (davis@arsdigita.com)

} {
    set frag $html_fragment

    set syn(A) nobr
    set syn(ADDRESS) nobr
    set syn(NOBR) nobr
    #
    set syn(FORM) discard
    #
    set syn(BLINK) remove
    #
    set syn(TABLE) close
    set syn(FONT) close
    set syn(B) close
    set syn(BIG) close
    set syn(I) close
    set syn(S) close
    set syn(SMALL) close
    set syn(STRIKE) close
    set syn(SUB) close
    set syn(SUP) close
    set syn(TT) close
    set syn(U) close
    set syn(ABBR) close
    set syn(ACRONYM) close
    set syn(CITE) close
    set syn(CODE) close
    set syn(DEL) close
    set syn(DFN) close
    set syn(EM) close
    set syn(INS) close
    set syn(KBD) close
    set syn(SAMP) close
    set syn(STRONG) close
    set syn(VAR) close
    set syn(DIR) close
    set syn(DL) close
    set syn(MENU) close
    set syn(OL) close
    set syn(UL) close
    set syn(H1) close
    set syn(H2) close
    set syn(H3) close
    set syn(H4) close
    set syn(H5) close
    set syn(H6) close
    set syn(BDO) close
    set syn(BLOCKQUOTE) close
    set syn(CENTER) close
    set syn(DIV) close
    set syn(PRE) close
    set syn(Q) close
    set syn(SPAN) close

    set out {}
    set out_len 0

    # counts how deep we are nested in nonbreaking tags, tracks the nobr point
    # and what the nobr string length would be
    set nobr 0
    set nobr_out_point 0
    set nobr_tagptr 0
    set nobr_len 0

    set discard 0

    set tagptr -1

    # first thing we do is chop off any trailing unclosed tag
    # since when we substr blobs this sometimes happens

    # this should in theory cut any tags which have been cut open.
    while {[regexp {(.*)<[^>]*$} $frag match frag]} {}

    while { "$frag" != "" } {
        # here we attempt to cut the string into "pretag<TAG TAGBODY>posttag"
        # and build the output list.

        if {![regexp "(\[^<]*)(<(/?)(\[^ \r\n\t>]+)(\[^>]*)>)?(.*)" $frag match pretag fulltag close tag tagbody frag]} {
            # should never get here since above will match anything.
            # puts "NO MATCH: should never happen! frag=$frag"
            append out $frag
            set frag {}
        } else {
            # puts "\n\nmatch=$match\n pretag=$pretag\n fulltag=$fulltag\n close=$close\n tag=$tag\n tagbody=$tagbody\nfrag=$frag\n\n"
            if { ! $discard } {
                # figure out if we can break with the pretag chunk
                if { $break_soft } {
                    if {! $nobr && [expr [string length $pretag] + $out_len] > $break_soft } {
                        # first chop pretag to the right length
                        set pretag [string range $pretag 0 [expr $break_soft - $out_len]]
                        # clip the last word
                        regsub "\[^ \t\n\r]*$" $pretag {} pretag
                        append out [string range $pretag 0 $break_soft]
                        break
                    } elseif { $nobr &&  [expr [string length $pretag] + $out_len] > $break_hard } {
                        # we are in a nonbreaking tag and are past the hard break
                        # so chop back to the point we got the nobr tag...
                        set tagptr $nobr_tagptr
                        if { $nobr_out_point > 0 } {
                            set out [string range $out 0 [expr $nobr_out_point - 1]]
                        } else {
                            # here maybe we should decide if we should keep the tag anyway
                            # if zero length result would be the result...
                            set out {}
                        }
                        break
                    }
                }

                # tack on pretag
                append out $pretag
                incr out_len [string length $pretag]
            }

            # now deal with the tag if we got one...
            if  { $tag == "" } {
                # if the tag is empty we might have one of the bad matched that are not eating
                # any of the string so check for them
                if {[string length $match] == [string length $frag]} {
                    append out $frag
                    set frag {}
                }
            } else {
                set tag [string toupper $tag]
                if { ![info exists syn($tag)]} {
                    # if we don't have an entry in our syntax table just tack it on
                    # and hope for the best.
                    if { ! $discard } {
                        append  out $fulltag
                    }
                } else {
                    if { $close != "/" } {
                        # new tag
                        # "remove" tags are just ignored here
                        # discard tags
                        if { $discard } {
                            if { $syn($tag) == "discard" } {
                                incr discard
                                incr tagptr
                                set tagstack($tagptr) $tag
                            }
                        } else {
                            switch $syn($tag) {
                                nobr {
                                    if { ! $nobr } {
                                        set nobr_out_point [string length $out]
                                        set nobr_tagptr $tagptr
                                        set nobr_len $out_len
                                    }
                                    incr nobr
                                    incr tagptr
                                    set tagstack($tagptr) $tag
                                    append out $fulltag
                                }
                                discard {
                                    incr discard
                                    incr tagptr
                                    set tagstack($tagptr) $tag
                                }
                                close {
                                    incr tagptr
                                    set tagstack($tagptr) $tag
                                    append out $fulltag
                                }
                            }
                        }
                    } else {
                        # we got a close tag
                        if { $discard } {
                            # if we are in discard mode only watch for
                            # closes to discarded tags
                            if { $syn($tag) == "discard"} {
                                if {$tagptr > -1} {
                                    if { $tag != $tagstack($tagptr) } {
                                        #puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        incr discard -1
                                    }
                                }
                            }
                        } else {
                            if { $syn($tag) != "remove"} {
                                # if tag is a remove tag we just ignore it...
                                if {$tagptr > -1} {
                                    if {$tag != $tagstack($tagptr) } {
                                        # puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        if { $syn($tag) == "nobr"} {
                                            incr nobr -1
                                        }
                                        append out $fulltag
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # on exit of the look either we parsed it all or we truncated.
    # we should now walk the stack and close any open tags.

    for {set i $tagptr} { $i > -1 } {incr i -1} {
        # append out "<!-- autoclose --> </$tagstack($i)>"
        append out "</$tagstack($i)>"
    }

    return $out
}



ad_proc ad_html_security_check { html } {

    Returns a human-readable explanation if the user has used any HTML
    tag other than the ones marked allowed in antispam section of ad.ini.
    Otherwise returns an empty string.

    @return a human-readable explanation of what's wrong with the user's input.

    @author Lars Pind (lars@pinds.com)
    @creation-date 20 July 2000

} {
    if { [string first <% $html] > -1 } {
	return "For security reasons, you're not allowed to have the less-than-percent combination in your input."
    }

    array set allowed_attributes [list]
    set allowed_tags_list [ad_parameter_all_values_as_list AllowedTag antispam]
    set allowed_attributes_list [ad_parameter_all_values_as_list AllowedAttribute antispam]
    set allowed_url_attributes_list [ad_parameter_all_values_as_list AllowedURLAttribute antispam]
    set allowed_protocols_list [ad_parameter_all_values_as_list AllowedProtocol antispam]
    set all_allowed_attributes_list [concat $allowed_attributes_list $allowed_url_attributes_list]

    foreach tag $allowed_tags_list {
	set allowed_tag([string tolower $tag]) 1
    }
    foreach attribute $all_allowed_attributes_list {
	set allowed_attribute([string tolower $attribute]) 1
    }
    foreach attribute $allowed_url_attributes_list {
	set url_attribute([string tolower $attribute]) 1
    }
    foreach protocol $allowed_protocols_list {
	set allowed_protocol([string tolower $protocol]) 1
    }

    # loop over all tags
    for { set i [string first < $html] } { $i != -1 } { set i [string first < $html $i] } {
	# move past the tag-opening <
	incr i

	if { ![regexp -indices -start $i {\A/?([a-zA-Z_]+)\s*} $html match name_idx] } {
	    # The tag-opener isn't followed by USASCII letters (with or without optional slash)
	    # Not considered a tag. Shouldn't do any harm in browsers.
	    # (Tested with digits, with &#65; syntax, with whitespace)
	} else {
	    # The tag was valid ... now let's see if it's on the allowed list.
	    set tagname [string tolower [string range $html [lindex $name_idx 0] [lindex $name_idx 1]]]

	    if { ![info exists allowed_tag($tagname)] } {
		# Nope, this was a naughty tag.
		return "For security reasons we only accept the submission of HTML
		containing the following tags: <code>[join $allowed_tags_list " "]</code>.
		You have a &lt;$tagname&gt; tag in there."
	    } else {
		# Legal tag.
		
		# Make i point to the first character inside the tag, after the tag name and any whitespace
		set i [expr { [lindex $match 1] + 1}]
		
		# Loop over the attributes.
		# We maintain counter is so that we don't accidentally enter an infinite loop
		set count 0
		while { $i < [string length $html] && ![string equal [string index $html $i] {>}] } {
		    incr count
		    if { $count > 100 } {
			error "Infinite loop! There's a programming bug in ad_html_security_check."
		    }
		
		    # This regexp matches an attribute name and an equal sign, if present.
		    # Also eats whitespace before or after.
		    if { ![regexp -indices -start $i {\A\s*([^\s=>]+)\s*(=?)\s*} $html match attr_name_idx equal_sign_idx] } {
			# Apparantly, there's no attribute name here. Let's eat all whitespace and lonely equal signs.
			regexp -indices -start $i {\A[\s=]*} $html match
			set i [expr { [lindex $match 1] + 1 }]
		    } {
			set attr_name [string tolower [string range $html [lindex $attr_name_idx 0] [lindex $attr_name_idx 1]]]
			
			if { ![info exists allowed_attribute($attr_name)] } {
			    return "The attribute '$attr_name' is not allowed for &lt;$tagname&gt; tags"
			}
			
			# Move past the attribute name just found
			set i [expr { [lindex $match 1] + 1}]
			
			# If there is an equal sign, we're expecting the next token to be a value
			if { [lindex $equal_sign_idx 1] - [lindex $equal_sign_idx 0] >= 0 } {
			
			    # is there a single or double quote sign as the first character?
			    switch -- [string index $html $i] {
				{"} { set exp {\A"([^"]*)"\s*} }
				{'} { set exp {\A'([^']*)'\s*} }
				default { set exp {\A([^\s>]*)\s*} }
			    }
			    if { ![regexp -indices -start $i $exp $html match attr_value_idx] } {
				# No end quote.
				set attr_value [string range $html [expr {$i+1}] end]
				set i [string length $html]
			    } else {
				set attr_value [string range $html [lindex $attr_value_idx 0] [lindex $attr_value_idx 1]]
				set i [expr { [lindex $match 1] + 1}]
			    }
			
			    if { [info exists url_attribute($attr_name)] != -1 } {
				set attr_value [util_expand_numeric_entities $attr_value]
				
				if { [regexp {^\s*([^\s:]+):} $attr_value match protocol] } {
				    if { ![info exists allowed_protocol([string tolower $protocol])] } {
					return "Your URLs can only use these protocols: [join $allowed_protocols_list ", "].
					You have a '$protocol' protocol in there."
				    }
				}
				
			    }
			}
		    }
		}
	    }
	}
    }
    return {}
}




####################
#
# HTML -> Text
#
####################

ad_proc -public ad_html_to_text {
    {-maxlen 70}
    {-showtags:boolean}
    html
} {
    Returns a best-guess plain text version of an HTML fragment.
    Parses the HTML and does some simple formatting. The parser and
    formatting
    is pretty stupid, but it's better than nothing.

    @param maxlen the line length you want your output wrapped to.
    @param showtags causes any unknown (and uninterpreted) tags to get shown in the output.

    @author Lars Pind (lars@pinds.com)
    @author Aaron Swartz (aaron@swartzfam.com)
    @creation-date 19 July 2000
} {
    # convert curly braces into their HTML entity equivalents, so as
    # not to confuse Tcl into thinking they're list stuff.
    regsub -all \{ $html {\&ob;} html
    regsub -all \} $html {\&cb;} html

    set output(text) {}
    set output(linelen) 0
    set output(maxlen) $maxlen
    set output(pre) 0
    set output(p) 0
    set output(br) 0
    set output(blockquote) 0

    set length [string length $html]
    set last_tag_end 0

    # For showing the URL of links.
    set href_urls [list]
    set href_stack [list]

    for { set i [string first < $html] } { $i != -1 } { set i [string first < $html $i] } {
	# append everything up to and not including the tag-opening <
	ad_html_to_text_put_text output [string range $html $last_tag_end [expr {$i - 1}]]

	# we're inside a tag now. Find the end of it
	
	# make i point to the char after the <
	incr i
	set tag_start $i
	
	while 1 {
	    set quote [string first \" $html $i]
	    set gt [string first > $html $i]
	    if { $gt == -1 } {
		# missing tag-ending >
		set i $length
		break
	    }
	    if { $gt < $quote || $quote == -1 } {
		# we found the tag end
		set i $gt
		break
	    }
	    # skip past the end quote
	    set i [string first \" $html [incr quote]]
	    incr i
	}
	
	set full_tag [string range $html $tag_start [expr { $i - 1 }]]

	if { ![regexp {(/?)([^\s]+)[\s]*(\s.*)?} $full_tag match slash tagname attributes] } {
	    # A malformed tag -- just delete it
	} else {

	    switch -- [string tolower $tagname] {
		p - ul - ol - table {
		    set output(p) 1
		}
		br {
		    append output(text) \n
		    set output(linelen) 0
		}
		tr - td - th {
		    set output(br) 1
		}
		h1 - h2 - h3 - h4 - h5 - h6 {
		    set output(p) 1
		    if { [empty_string_p $slash] } {
			ad_html_to_text_put_text output [string repeat "*" [string index $tagname 1]]
		    }
		}
		li {
		    set output(br) 1
		    if { [empty_string_p $slash] } {
			ad_html_to_text_put_text output "- "
		    }
		}
		strong - b {
		    ad_html_to_text_put_text output "*"
		}
		em - i - cite {
		    ad_html_to_text_put_text output "_"
		}
		a {
		    if { [empty_string_p $slash] } {
			if { [regexp -nocase {\shref *= *"([^"]+)"} $attributes {} href] || \
				[regexp -nocase {\shref *= *([^ ]+)} $attributes {} href] } {
			    set href_no [expr [llength $href_urls] + 1]
			    lappend href_urls "\[$href_no\] $href"
			    lappend href_stack "\[$href_no\]"
			} else {
			    lappend href_stack {}
			}
		    } else {
			if { [llength $href_stack] > 0 } {
			    if { ![empty_string_p [lindex $href_stack end]] } {
				ad_html_to_text_put_text output [lindex $href_stack end]
			    }
			}
			set href_stack [lreplace $href_stack end end]
		    }
		}
		pre {
		    set output(p) 1
		    if { [empty_string_p $slash] } {
			incr output(pre)
		    } else {
			incr output(pre) -1
		    }
		}
		blockquote {
		    set output(p) 1
		    if { [empty_string_p $slash] } {
			incr output(blockquote)
		    } else {
			incr output(blockquote) -1
		    }
		}
		hr {
		    set output(p) 1
		    ad_html_to_text_put_text output [string repeat "-" [expr $maxlen]]
		    set output(p) 1
		}
		default {
		    # Other tag
		    if { $showtags_p } {
			ad_html_to_text_put_text output "&lt;$slash$tagname$attributes&gt;"
		    }
		}
	    }
	}
	
	# set end of last tag to the character following the >
	set last_tag_end [incr i]
    }
    # append everything after the last tag
    ad_html_to_text_put_text output [string range $html $last_tag_end end]

    # Close any unclosed PRE tags
    set output(pre) 0

    # write out URLs, if necessary:
    if { [llength $href_urls] > 0 } {
	set output(p) 1
	foreach url $href_urls {
	    set output(br) 1
	    ad_html_to_text_put_text output $url
	}
    }

    # expand all &foo;'s (or at least some of them)
    #set output(text) [util_expand_entities $output(text)]

    return $output(text)
}

ad_proc -private ad_html_to_text_put_text { output_var text_to_put } {
    Helper proc for ad_html_to_text

    @author Lars Pind (lars@pinds.com)
    @author Aaron Swartz (aaron@swartzfam.com)
    @creation-date 19 July 2000
} {
    upvar $output_var output

    set text_to_put [util_expand_entities $text_to_put]

    # output any pending paragraph or line breaks
    if { ( $output(p) || $output(br) ) && ![regexp {^[\s]*$} $text_to_put] } {
	if { ![empty_string_p $output(text)] } {
	    if { $output(p) } {
		append output(text) "\n\n"
	    } else {
		append output(text) "\n"
	    }
	}
	append output(text) [string repeat {    } $output(blockquote)]
	set output(linelen) [expr $output(blockquote) * 4]
	set output(p) 0
	set output(br) 0
    }

    # Now output the text.
    if { $output(pre) <= 0 } {
	# we're not inside a PRE tag
	while { [regexp {^([\s]*)([^\s]+)(.*)$} $text_to_put match prefix word text_to_put] || [regexp {^([\s]+)$} $text_to_put spaces]} {
	    if { [info exists spaces] } {
		if { ![regexp {^ *$} $output(text)] } {
		    append output(text) { }
		    incr output(linelen)
		}
		set text_to_put {}
	    } else {
		regsub -all {&nbsp;} $word { } word
		set wordlen [string length $word]
		if { $output(linelen) > 0 && ![empty_string_p $prefix] } {
		    if { $output(linelen) + 1 + $wordlen > $output(maxlen) } {
			append output(text) \n
			append output(text) [string repeat {    } $output(blockquote)]
			set output(linelen) [expr $output(blockquote) * 4]
		    } else {
			append output(text) { }
			incr output(linelen)
		    }
		}
		append output(text) $word
		incr output(linelen) $wordlen
	    }
	}
    } else {
	# we're inside a PRE tag
	while { ![empty_string_p $text_to_put] && [regexp {^([^\n]*)(\n?)(.*)$} $text_to_put match line newline text_to_put] } {
	    append output(text) $line$newline
	    if { [empty_string_p $newline] } {
		set output(linelen) [string length $line]
	    } else {
		append output(text) [string repeat {    } $output(blockquote)]
		set output(linelen) [expr $output(blockquote) * 4]
	    }
	}
    }
}

ad_proc -private util_expand_entities { html } {
    Replaces all occurrences of common HTML entities
    with their plaintext equivalents.
    Currently, the following entities are converted:
    &amp;lt;, &amp;gt;, &apm;quot; and &amp;amp;
} {
    regsub -all {&lt;} $html {<} html
    regsub -all {&gt;} $html {>} html
    regsub -all {&quot;} $html {"} html
    regsub -all {&ob;} $html \{ html
    regsub -all {&cb;} $html \} html
    regsub -all {&mdash;} $html {--} html
    regsub -all {&#151;} $html {--} html
    # Need to do the &amp; last, because otherwise it could interfere with the other expansions.
    regsub -all {&amp;} $html {\&} html
    return $html
}

ad_proc util_expand_numeric_entities { html } {
    Replaces all occurrences of &amp;#111; and &amp;x0f; type HTML character entities
    to their ASCII equivalents. It doesn't try to expand normal entities like lt, gt, amp, etc.

    <p>

    Note that you shouldn't use this in connection with
    <a href="/api-doc/proc-view?proc=util_expand_entities"><code>util_expand_entities</code></a>,
    because the expansion of &amp;amp; to &amp; will interfere with the other expansions.

    @author Lars Pind (lars@pinds.com)
    @creation-date October 17, 2000
} {
    # Expand HTML entities on the value
    for { set i [string first & $html] } \
	    { $i != -1 } \
	    { set i [string first & $html $i] } {
	
	switch -- [string index $html [expr $i+1]] {
	    # {
		switch -- [string index $html [expr $i+2]] {
		    x {
			regexp -indices -start [expr $i+3] {[0-9a-eA-E]*} $html hex_idx
			set hex [string range $html [lindex $hex_idx 0] [lindex $hex_idx 1]]
			set html [string replace $html $i [lindex $hex_idx 1] \
				[subst -nocommands -novariables "\\x$hex"]]
		    }
		    default {
			regexp -indices -start [expr $i+2] {[0-9]*} $html dec_idx
			set dec [string range $html [lindex $dec_idx 0] [lindex $dec_idx 1]]
			set html [string replace $html $i [lindex $dec_idx 1] \
				[format "%c" $dec]]
		    }
		}
	    }
	    default {
		# We don't try to expand non-numeric entities here.
	    }
	}
	incr i
	# remove trailing semicolon
	if { [string equal [string index $html $i] {;}] } {
	    set html [string replace $html $i $i]
	}
    }
    return $html
}



####################
#
# Text -> Text
#
####################


ad_proc wrap_string {input {threshold 80}} {
    wraps a string to be no wider than 80 columns by inserting line breaks
} {
    set result_rows [list]
    set start_of_line_index 0
    while 1 {
	set this_line [string range $input $start_of_line_index [expr $start_of_line_index + $threshold - 1]]
	if { $this_line == "" } {
	    return [join $result_rows "\n"]
	}
	set first_new_line_pos [string first "\n" $this_line]
	if { $first_new_line_pos != -1 } {
	    # there is a newline
	    lappend result_rows [string range $input $start_of_line_index [expr $start_of_line_index + $first_new_line_pos - 1]]
	    set start_of_line_index [expr $start_of_line_index + $first_new_line_pos + 1]
	    continue
	}
	if { [expr $start_of_line_index + $threshold + 1] >= [string length $input] } {
	    # we're on the last line and it is < threshold so just return it
		lappend result_rows $this_line
		return [join $result_rows "\n"]
	}
	set last_space_pos [string last " " $this_line]
	if { $last_space_pos == -1 } {
	    # no space found!  Try the first space in the whole rest of the string
	    set next_space_pos [string first " " [string range $input $start_of_line_index end]]
	    set next_newline_pos [string first "\n" [string range $input $start_of_line_index end]]
	    if {$next_space_pos == -1} {
		set last_space_pos $next_newline_pos
	    } elseif {$next_space_pos < $next_newline_pos} {
		set last_space_pos $next_space_pos
	    } else {
		set last_space_pos $next_newline_pos
	    }
	    if { $last_space_pos == -1 } {
		# didn't find any more whitespace, append the whole thing as a line
		lappend result_rows [string range $input $start_of_line_index end]
		return [join $result_rows "\n"]
	    }
	}
	# OK, we have a last space pos of some sort
	set real_index_of_space [expr $start_of_line_index + $last_space_pos]
	lappend result_rows [string range $input $start_of_line_index [expr $real_index_of_space - 1]]
	set start_of_line_index [expr $start_of_line_index + $last_space_pos + 1]
    }
}




####################
#
# Wrappers to make it easier to write generic code
#
####################

ad_proc -public ad_html_text_convert {
    {-from text}
    {-to html}
    text
} {
    Converts a chunk of text from text/html to text/html.
    Text to text does nothing, but html to html closes any unclosed html tags (see util_close_html_tags).
    Text to html does ad_text_to_html, and html to text does a ad_html_to_text.
    See those procs for details.

    @param from specify with html or text what type of text you're providing.
    @param to specify what format you want this translated into

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    switch $from {
	html {
	    switch $to {
		html {
		    ad_html_security_check $text
		    return [util_close_html_tags $text]
		}
		text {
		    return [ad_html_to_text -- $text]
		}
		default {
		    return -code error "Can only convert to text or html"
		}
	    }
	}
	text {
	    switch $to {
		html {
		    return [ad_text_to_html -- $text]
		}
		text {
		    return [wrap_string $text 70]
		}
		default {
		    return -code error "Can only convert to text or html"
		}
	    }
	}
	default {
	    return -code error "Can only convert from text or html"
	}
    }
}

ad_proc -public ad_convert_to_html {
    {-html_p f}
    text
} {
    Convenient interface to convert text or html into html.
    Does the same as <code><a href="/api-doc/proc-view?proc=ad_html_text_convert">ad_html_text_convert</a> -to html</code>.

    @param html_p specify <code>t</code> if the value of
    <code>text</code> is formatted in HTML, or <code>f</code> if <code>text</code> is plaintext.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if { [string equal $html_p t] } {
	set from html
    } else {
	set from text
    }
    return [ad_html_text_convert -from $from -to html -- $text]
}

ad_proc -public ad_convert_to_text {
    {-html_p t}
    text
} {
    Convenient interface to convert text or html into plaintext.
    Does the same as <code><a href="/api-doc/proc-view?proc=ad_html_text_convert">ad_html_text_convert</a> -to text</code>.

    @param html_p specify <code>t</code> if the value of
    <code>text</code> is formatted in HTML, or <code>f</code> if <code>text</code> is plaintext.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if { [string equal $html_p t] } {
	set from html
    } else {
	set from text
    }
    return [ad_html_text_convert -from $from -to text -- $text]
}


ad_proc -public ad_looks_like_html_p {
    text
} {
    Tries to guess whether the text supplied is text or html.

    @param text the text you want tested.
    @return 1 if it looks like html, 0 if not.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if { [regexp -nocase {<p>} $text] || [regexp -nocase {<br>} $text] || [regexp -nocase {</a} $text] } {
	return 1
    } else {
	return 0
    }
}

ad_proc util_remove_html_tags { html } {
    Removes everything between &lt; and &gt; from the string.
} {
    regsub -all {<[^>]*>} $html {} html
    return $html
}





####################
#
# Legacy stuff
#
####################


ad_proc -deprecated util_striphtml {html} {
    Use <a href="/api-doc/proc-view?proc=ad_html_to_text"><code>ad_html_to_text</code></a> instead.
} {
    return [ad_html_to_text -- $html]
}


ad_proc -deprecated util_convert_plaintext_to_html { raw_string } {

    Almost everything this proc does can be accomplished with the <a
    href="/api-doc/proc-view?proc=ad_text_to_html"><code>ad_text_to_html</code></a>.
    Use that proc instead.

    <p>

    Only difference is that ad_text_to_html doesn't check
    to see if the plaintext might in fact be HTML already by
    mistake. But we usually don't want that anyway,
    because maybe the user wanted a &lt;p&gt; tag in his
    plaintext. We'd rather let the user change our
    opinion about the text, e.g. html_p = 't'.

} {
    if { [regexp -nocase {<p>} $raw_string] || [regexp -nocase {<br>} $raw_string] } {
	# user was already trying to do this as HTML
	return $raw_string
    } else {
	return [ad_text_to_html -no_links -- $raw_string]
    }
}

ad_proc -deprecated util_maybe_convert_to_html {raw_string html_p} {

    This proc is deprecated. Use <a
    href="/api-doc/proc-view?proc=ad_convert_to_html"><code>ad_convert_to_html</code></a>
    instead.

}  {
    if { $html_p == "t" } {
	return $raw_string
    } else {
	return [util_convert_plaintext_to_html $raw_string]
    }
}

ad_proc -deprecated util_quotehtml { arg } {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>.
    Use that instead. This one will be deleted eventually.
} {
    return [ad_quotehtml $arg]
}

ad_proc -deprecated util_quote_double_quotes {arg} {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>.
    Use that instead. This one will be deleted eventually.
} {
    return [ad_quotehtml $arg]
}

ad_proc -deprecated philg_quote_double_quotes {arg} {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>.
    Use that instead. This one will be deleted eventually.
} {
    return [ad_quotehtml $arg]
}
