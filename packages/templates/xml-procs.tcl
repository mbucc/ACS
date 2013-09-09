# /packages/templates/xml-procs.tcl
ad_library {

  A simple XML parser for AOLserver.

  @author Karl Goldstein (karlg@arsdigita.com)
  @cvs-id xml-procs.tcl,v 1.3.2.1 2000/07/18 21:53:31 seb Exp

}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Extended from Html_Parse by Stephen Uhler, as presented
# in Welch, Practical Programming in Tcl and Tk, page 131.

proc_doc ad_xml_parse {xml {parent {}}} "

  A simple xml parser that takes the body of an 
  element and places the value of each child element 
  into an ns_set.

" {

  # Define an internal proc to add an element value to the 
  # DOM tree

  proc put_element {name closing params value} {

    if { [string match $name {}] } { return }
    
    set name [string tolower $name]

    # Back substitute braces and backslashes for XML entities

    regsub -all {\&ob;} $value \{ value
    regsub -all {\&cb;} $value \} value
    regsub -all {\&bsl;} $value {\\} value

    regsub -all {\&lt;} $value < value
    regsub -all {\&gt;} $value > value
      
    upvar stack stack

    # get the last (innermost) container on the stack
    set DOM [lindex $stack end]

    if { $closing != "/" } {

      # if the value is null or the params are not null then we are
      # entering a child container, so create an ns_set, push 
      # it on the container stack, and save it as the value
      
      set value [string trim $value]
      set params [string trim $params]

      if { [string match $value {}] || ! [string match $params {}] } {

        # save character content

        set PCDATA $value
        set value [ns_set create $name]

	if { ! [string match $PCDATA {}] } {
          ns_set put $value text $PCDATA
        }

        if { ! [string match $params {}] } {

          # trim the trailing slash off empty elements
          regsub {/$} $params "\nset trailing /" params

          # save parameters by turning the parameter string into Tcl code
          # that sets an array variable for each parameter

          set w " \t\r\n"
          regsub -all (\[^$w=]+)\[$w]*= $params "\nset parray(\\1) " params
          eval $params

          foreach param [array names parray] {

            ns_set put $value $param $parray($param)
	  }
	}
        
        # push it onto the stack unless it is an empty element

        if { ! [info exists trailing] } {
          lappend stack $value
	}
      }

      # append the value to the current container so that the
      # ordering of different types of elements is preserved

      ns_set put $DOM $name $value

    } else {
      
      # if the element closing is the innermost container, then
      # pop it off the stack

      if [string match $name [ns_set name $DOM]] {

        set stack [lrange $stack 0 [expr [llength $stack] - 2]]
      }
    }
  }

  # Substitute braces and backslashes for XML entities

  regsub -all {\\<} $xml {\&lt;} xml
  regsub -all {\\>} $xml {\&gt;} xml

  regsub -all \{ $xml {\&ob;} xml
  regsub -all \} $xml {\&cb;} xml
  regsub -all {\\} $xml {\&bsl;} xml

  # Match the parts of an XML tag
  # This may be either an opening (i.e. <body>)
  # or closing (i.e. </body>) tag

  set w " \t\r\n"
  set exp <(/?)(\[^$w>]+)\[$w]*(\[^>]*)>

  # initialize the DOM stack

  set DOM [ns_set create $parent]
  set stack [list $DOM]

  # Replace each beginning and ending XML tag part with
  # a call to put_element to build the DOM tree

  # \1 is the leading slash, indicating a closing tag
  # \2 is the XML element name
  # \3 are the parameters to the tag

  # The curly braces at either end group the text
  # after the XML tag, which becomes the last arg to 
  # put_element

  set sub "\}\nput_element {\\2} {\\1} {\\3} \{"
  regsub -all $exp $xml $sub xml

  # parse the xml

  eval "put_element {} {} {} {$xml}"

  # if the parent was null then lop off the first level of the tree

  if [string match $parent {}] {
    set DOM [lindex [ns_set value $DOM 0] 0]
  }

  return $DOM
}

proc_doc ad_xml_get_nodes { DOM path { name "" } } "

  Retrieves a list of nodes with the specified name at the 
  specified path within the DOM.  The path within the DOM is given by a 
  slash.

" {

  # strip leading and trailing slashes.
  set path [string trim $path "/"]

  set node DOM

  foreach step [split $path "/"] {

    set node [ns_set get $DOM $step]

    if { $node == "" } { return [list] }
  }

  set nodes [ad_util_get_values $node $name]

  return $nodes
}

proc_doc ad_xml_get_node { DOM path name } "

  Retrieves a single node with the specified name at the 
  specified path within the DOM.  The path within the DOM is given by a 
  slash.

" {

  set nodes [ad_xml_get_nodes $DOM $path $name]

  return [lindex $nodes 0]
}

proc_doc ad_xml_match_nodes { DOM path name attribute value } "

  Retrieves a list of nodes with the specified name at the 
  specified path within the DOM.  The path within the DOM is given by a 
  slash.  The list is restricted to nodes with an attribute with
  the specified value.

" {

  set nodes [list]

  foreach node [ad_xml_get_nodes $DOM $path $name] {

    set matchval [ns_set get $node $attribute]
    if { [string match $matchval $value] } { lappend nodes $node }
  }

  return $nodes
}

proc_doc ad_xml_match_node { DOM path name attribute value } "

  Retrieves a single node with the specified name at the 
  specified path within the DOM.  The path within the DOM is given by a 
  slash.

" {

  set nodes [ad_xml_match_nodes $DOM $path $name $attribute $value]

  return [lindex $nodes 0]
}

proc_doc ad_xml_print { DOM } "

  Returns an HTML representation of a DOM whose elements are
  represented as nested ns_sets (as generated by ad_xml_parse).

" {

  set out "
    <p><b>[ns_set name $DOM]</b></p>
    <blockquote>
  "

  for { set i 0 } { $i < [ns_set size $DOM] } { incr i } {

    set key [ns_set key $DOM $i]
    set values [ns_set value $DOM $i]

    foreach value $values {

      # test if an ns_set and if so descend the DOM tree recursively

      if [catch { set name [ns_set name $value] } errMsg] {

        append out "$key=$value<br></br>\n"

      } else {

        append out [ad_xml_print $value]
      }
    }
  }

  append out "</blockquote>\n"

  return $out
}

proc_doc ad_xml_print { DOM } "

  Returns an HTML representation of a DOM whose elements are
  represented as nested ns_sets (as generated by ad_xml_parse).

" {

    set out "
    <p><b>[ns_set name $DOM]</b></p>
    <blockquote>
  "


    for { set i 0 } { $i < [ns_set size $DOM] } { incr i } {

        set key [ns_set key $DOM $i]
        set values [ns_set value $DOM $i]

        if [catch { set name [ns_set name $values] } errMsg] {

            if {[regsub -all "\n" $values "\n" dummy] < 2} { 
                append out "$key : $values<br>\n"
            } else { 
                append out "$key : <pre>$values</pre>\n"
            }
            

        } else {
            append out "$key->[ad_xml_print $values]"
        }
    }

    append out "</blockquote>\n"

    return $out
}

proc_doc ad_xml_process { DOM outvar } "

  Returns a dynamic xml document based on data sources.

" {

  upvar $outvar out

  set element_name [ns_set name $DOM]

  set datasource [ns_set get $DOM datasource]

  # If there is a data source then we need to generate a new element 
  # for each row in the data source.  Otherwise just create a dummy
  # list of one element.

  if { ! [empty_string_p $datasource] } {

    upvar #0 $datasource sets
    
    foreach set $sets {
      ad_xml_process_element $element_name $set out
    }

  } else {

    ad_xml_process_element $element_name $DOM out

  }
}

proc ad_xml_process_element { element_name element outvar } {

  upvar $outvar out

  append out "<$element_name>\n"
  
  for { set i 0 } { $i < [ns_set size $element] } { incr i } {

    set key [ns_set key $element $i]
    set value [ns_set value $element $i]

    if { [ad_util_is_set $value] } {
      ad_xml_process $value out
    } else {
      append out "<$key>$value</$key>\n"
    }
  }

  append out "</$element_name>\n"
}

proc ad_xml_filter { why } {

  set url [ns_conn url]

  if { [catch {

    global errorSet
    set errorSet [ns_set create]

    regsub {\.xml} $url {.data} spec_url

    set spec [ad_publish_get_spec $spec_url status]

    if { $spec != "" } { 

      ad_template_get_all_data $spec
      set xml [ad_publish_get_spec -novalidate $url status]
set output "<?xml version=\"1.0\"?>\n"
      ad_xml_process $xml output

ns_write "HTTP/1.0 200 OK\nMIME-Version: 1.0\n"
ns_write "Content-Type: text/xml\n\n"
ns_startcontent -type $content_type
ns_write $output

    }
    
  } errCode] } {

    ad_publish_error_message $errCode
  }

  if { $spec != "" } { 
    return "filter_return"
  } else {
    return "filter_ok"
  }
}

