# /www/bookmarks/tree-frame.tcl

ad_page_contract {
    @author  unknown
    @created unknown
    @cvs-id  tree-frame.tcl,v 3.0.12.5 2000/09/22 01:37:03 kevin Exp
} {
}

set page_content "
<html>

<head>
<link rel=stylesheet href=tree.css>
<script src=tree-static.js></script>
<script src=tree-dynamic?time=\"[ns_time]\"></script>
</head>

<body bgcolor=#f3f3f3>

<script>
initializeDocument()
</script>

</html>
"

doc_return  200 text/html "$page_content"











