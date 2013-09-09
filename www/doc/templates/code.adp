<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id code.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>
<head>
<title>
Dynamic Publishing System
</title>
</head>
<body>

<h2>
Source Code
</h2>

of the <a href="index">ArsDigita Publishing System</a>
by <a href="mailto:karlg@arsdigita.com">Karl Goldstein</a>

<hr>

<h3>Core Procedures</h3>

<table border=1 cellspacing=0 cellpadding=6 width=95%>
<tr>

<td width=50%>
<p><a href="show-source.tcl?url=../tcl/ad-publish.tcl">ad-publish.tcl</a></p>

Main page filter and error handling procedures.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-publish-spec.tcl">
ad-publish-spec.tcl</a></p>

General procedures for handling any type of specification file.
</td>

</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-template.tcl">ad-template.tcl</a></p>

Template processing filter and supporting procedures.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-template-data.tcl">
ad-template-data.tcl</a></p>

Procedures for processing template data sources.
</td>
</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-template-dict.tcl">
ad-template-dict.tcl</a></p>

Procedures for generating template data dictionaries.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-template-style.tcl">
ad-template-style.tcl</a></p>

Template style processor and supporting procedures.
</td>
</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-template-tags.tcl">
ad-template-tags.tcl</a></p>

Handler procedures for template markup tags.
</td>
</tr>

</table>

<h3>Form Manager</h3>

<table border=1 cellspacing=0 cellpadding=6 width=95%>

<tr>
<td width=50%>
<p><a href="show-source.tcl?url=../tcl/ad-form.tcl">
ad-form.tcl</a></p>

Main handler for form preparation and submission and suppoting procedures.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-form-dict.tcl">
ad-form-dict.tcl</a></p>

Procedures for generating form data dictionaries.
</td>
</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-form-prepare.tcl">
ad-form-prepare.tcl</a></p>

Procedures for form template preparation.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-form-process.tcl">
ad-form-process.tcl</a></p>

Procedures for processing form submissions.
</td>
</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-form-tags.tcl">
ad-form-tags.tcl</a></p>

Form style processor and supporting procedures.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-form-validate.tcl">
ad-form-validate.tcl</a></p>

General validation procedures by data type for form submissions.
</td>
</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-form-widget.tcl">
ad-form-widget.tcl</a></p>

Procedures for generating markup for form elements.

</td>
</tr>
</table>

<h3>General Utilities</h3>

<table border=1 cellspacing=0 cellpadding=6 width=95%>

<tr>
<td width=50%>
<p><a href="show-source.tcl?url=../tcl/ad-database-util.tcl">ad-database-util.tcl</a></p>

Database query and manipulation procedures.
</td>

<td>
<p><a href="show-source.tcl?url=../tcl/ad-general-util.tcl">ad-general-util.tcl</a></p>

General utility procedures.
</td>
</tr>

<tr>
<td>
<p><a href="show-source.tcl?url=../tcl/ad-xml.tcl">ad-xml.tcl</a></p>

Simple XML parser.
</td>
</tr>
</table>

<hr>

<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>
