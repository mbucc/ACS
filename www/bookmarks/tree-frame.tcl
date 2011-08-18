# $Id: tree-frame.tcl,v 3.0 2000/02/06 03:35:44 ron Exp $
ReturnHeadersNoCache

ns_write "
<html>

<head>
<link rel=\"stylesheet\" href=\"tree.css\">
<script src=\"tree-static.js\"></script>
<script src=\"tree-dynamic.tcl?time=[ns_time]\"></script>
</head>

<body bgcolor=#f3f3f3>

<script>
initializeDocument()
</script>

</html>
"