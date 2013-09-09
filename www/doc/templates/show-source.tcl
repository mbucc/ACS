ad_page_contract {
    This is file /www/doc/template/show-source.tcl
} {
    {url ""}
}

if [string match $url {}] {
    doc_return  200 text/html  "No url specified"
    return
}

if { [regexp {^/} $url] || [regexp {\.\.} $url] } {
    doc_return 200 text/html "Absolute or .. paths not allowed"
    return
}

doc_return 200 text/html [ad_util_get_source $url]