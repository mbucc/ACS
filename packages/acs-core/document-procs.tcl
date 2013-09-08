ad_library {

    An API for managing documents.

    @creation-date 22 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $id$

}

proc_doc doc_init {} { Initializes the global environment for document handling. } {
    global doc_properties
    if { [info exists doc_properties] } {
	unset doc_properties
    }
    array set doc_properties {}
}

proc_doc doc_set_property { name value } { Sets a document property. } {
    global doc_properties
    set doc_properties($name) $value
}

proc_doc doc_property_exists_p { name } { Return 1 if a property exists, or 0 if not. } {
    global doc_properties
    return [info exists doc_properties($name)]
}

proc_doc doc_get_property { name } { Returns a property (or an empty string if no such property exists). } {
    global doc_properties
    if { [info exists doc_properties($name)] } {
	return $doc_properties($name)
    }
    return ""
}

proc_doc doc_body_append { str } { Appends $str to the body property. } {
    global doc_properties
    append doc_properties(body) $str
}

proc_doc doc_set_mime_type { mime_type } { Sets the mime-type property. } {
    doc_set_property mime_type $mime_type
}

proc_doc doc_exists_p {} { Returns 1 if there is a document in the global environment. } {
    global doc_properties
    if { [array size doc_properties] > 0 } {
	return 1
    }
    return 0
}

proc_doc doc_body_flush {} { Flushes the body (if possible). } {
    # Currently a no-op.
}

proc_doc doc_find_template { filename } { Finds a master.adp file which can be used as a master template, looking in the directory containing $filename and working our way down the directory tree. } {
    set path_root [acs_root_dir]

    set start [clock clicks]

    set dir [file dirname $filename]
    while { [string length $dir] > 1 && [string first $path_root $dir] == 0 } {
	# Only look in directories under the path root.
	if { [file isfile "$dir/master.adp"] } {
	    return "$dir/master.adp"
	}
	set dir [file dirname $dir]
    }

    if { [file exists "$path_root/templates/master.adp"] } {
	return "$path_root/templates/master.adp"
    }

    # Uhoh. Nada!
    return ""
}

proc_doc doc_serve_template { __template_path } { Serves the document in the environment using a particular template. } {
    upvar #0 doc_properties __doc_properties
    foreach __name [array names __doc_properties] {
	set $__name $__doc_properties($__name)
    }

    set adp [ns_adp_parse -file $__template_path]
    set content_type [ns_set iget [ns_conn outputheaders] "content-type"]
    if { [empty_string_p $content_type] } {
	set content_type "text/html"
    }
    doc_return  200 $content_type $adp
}

proc_doc doc_serve_document {} { Serves the document currently in the environment. } {
    if { ![doc_exists_p] } {
	error "No document has been built."
    }

    set mime_type [doc_get_property mime_type]
    if { [empty_string_p $mime_type] } {
	if { [doc_property_exists_p title] } {
	    set mime_type "text/html;content-pane"
	} else {
	    set mime_type "text/html"
	}
    }

    switch $mime_type {
	text/html;content-pane - text/x-html-content-pane {
	    # It's a content pane. Find the appropriate template.
	    set template_path [doc_find_template [ad_conn file]]
	    if { [empty_string_p $template_path] } {
		ns_returnerror 500 "Unable to find master template"
	    }
	    doc_serve_template $template_path
	}
	default {
	    # Return a complete document.
	    doc_return 200 $mime_type [doc_get_property body]
	}
    }
}

proc doc_tag_ad_document { contents params } {
    for { set i 0 } { $i < [ns_set size $params] } { incr i } {
	doc_set_property [ns_set key $params $i] [ns_set value $params $i]
    }
    doc_set_property _adp 1
    return [ns_adp_parse -string $contents]
}

proc doc_tag_ad_property { contents params } {
    set name [ns_set iget $params name]
    if { [empty_string_p $name] } {
	return "<em>No <tt>name</tt> property in <tt>AD-PROPERTY</tt> tag</em>"
    }
    doc_set_property $name $contents
}

