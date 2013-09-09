<%
ad_page_contract {
	@author ?
	@creation-date ?
	@cvs-id xml.adp,v 1.1.1.1 2000/08/08 07:24:59 ron Exp
}
%>

<html>
<head>
<title>
XML Parser for AOLServer
</title>

<link rel=stylesheet href="style.css" type="text/css">

</head>
<body>
<h1>
XML Parser for AOLServer
</h1>
Karl Goldstein (<a href="mailto:karlg@arsdigita.com">karlg@arsdigita.com</a>)
<hr>

<p>File: <tt>tcl/ad-xml.tcl</tt></p>

<h3>Overview</h3>

<p>XML can be a useful way to represent structured data as text, whether
stored in files or used as a method of exchange among different systems.
I have written a small package to parse XML documents into a 
Document Object Model (DOM), using AOLServer's <tt>ns_set</tt>
structure as an organizing principle.  Once an XML document has
been parsed, values can be extracted from the DOM and used
for any purpose.  The package also includes a procedure to print
a DOM as simple HTML.</p>

<h3>Parsing an XML Document</h3>

<p>Say you have a simple XML document:</p>

<pre>
&lt;book&gt;
  &lt;author&gt;Karl Goldstein&lt;/author&gt;
  &lt;publisher&gt;Harper & Collins&lt;/publisher&gt;
  &lt;year&gt;1999&lt;/year&gt;
  &lt;title&gt;How to Scramble Eggs&lt;/title&gt;
  &lt;chapter&gt;
      &lt;title&gt;Introduction&lt;/title&gt;
  &lt;/chapter&gt;
  &lt;chapter&gt;
      &lt;title&gt;Getting the Bowl&lt;/title&gt;
  &lt;/chapter&gt;
  &lt;chapter&gt;
      &lt;title&gt;Cracking the Egg&lt;/title&gt;
      &lt;footnote&gt;Types of Eggs&lt;/footnote&gt;
      &lt;footnote&gt;Types of Cracks&lt;/footnote&gt;
  &lt;/chapter&gt;
&lt;/book&gt;
</pre> 
  
<p>To parse this document into a DOM, use the <tt>ad_xml_parse</tt>
procedure:</p>

<pre>
set DOM [ad_xml_parse $document]
</pre>

<p>The procedure will return an <tt>ns_set</tt> named <tt>book</tt>.
The <tt>book</tt> ns_set will have keys corresponding to the XML
elements <tt>author</tt>, <tt>publisher</tt>, <tt>year</tt>
and <tt>title</tt>.  The values of these elements in the document
are stored in the DOM as string values in the <tt>ns_set</tt>.</p>

<p>In addition, the <tt>book</tt> ns_set will have a single key
named <tt>chapter</tt>.  The value of this key will be a list of
ns_sets, one for each chapter in the book.  Each chapter in turn
contains a key for <tt>title</tt>, and optionally a key for
<tt>footnote</tt>, which may return one or more string values as a list.</p>

<p>In general, if an element has child elements, then it is
represented as an <tt>ns_set</tt>.  Otherwise, it is represented as a
string.  If there are multiple instancess of a single type of element
in the same container, then the values are collected into a list.
(Actually this is true even when there is only one instance of an
element; the list just contains one entry).</p>

<h3>Printing a DOM</h3>

<p>To check the validity of the parsing job performed in the
previous step, you can use the <tt>ad_xml_print</tt> procedure to walk
the DOM tree recursively and generate a simple HTML representation of
the document:</p>

<pre>
set DOM [ad_xml_parse $document]
</pre>

<h3>How it Works</h3>

<p>The parser basically works by turning the xml document into a
program that is run through an <tt>eval</tt> statement.  Opening and
closing XML tags are replaced with calls to <tt>put_element</tt>, an
internal proc that maintains a stack frame to insert values into
their proper location in the DOM tree.</p>

<h3>Limitations</h3>

<p>The parser as it is written now is suitable only for simple XML
documents.  Its biggest limitation is that it probably cannot
handle elements that contain a mixture of child elements and
literal text, such as:</p>

<pre>
&lt;chapter&gt;
&lt;title&gt;How to Scramble&lt;/title&gt;
This chapter explains how to scramble.
&lt;/chapter&gt;
</pre>

<p>This would be an issue if you wanted to parse HTML, but it
is probably not a problem for most other document types.</p>

<p>The parser ignores DTD's and cannot be used to validate
documents.</p>

<p>The current edition of this parser ignores attributes.  This
would be easy to fix because they already are picked out
by the regexp.
</p>





