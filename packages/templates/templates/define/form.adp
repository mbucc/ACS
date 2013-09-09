<h1>Form Dictionary</h1>

<p><a href="/admin/template/form/form-template.tcl?url=<var name="spec.url">">
Generate the source</a> for a template in the standard style.</p>

<p><b>Title:</b> <var name="spec.title"></p>
<p><b>Comment:</b> <var name="spec.comment"></p>

<h3>Elements</h3>

<table cellpadding=5 cellspacing=0 border=1>

<tr bgcolor=#eeeeee>
<th>Name</th>
<th>Label</th>
<th>Widget</th>
<th>Data Type</th>
<th>Comments</th>
</tr>

<multiple name=elements>
<tr>
  <td><tt>&lt;formwidget name="<var name="elements.name">"&gt;</tt></td>
  <td>
    <if %elements.label% not nil><var name="elements.label"></if>
    <if %elements.label% nil>(None)</if>
  </td>
  <td><var name="elements.widget"></td>
  <td><var name="elements.datatype"></td>
  <td><var name="elements.comment"></td>
</tr>
</multiple>

</table>




