<!-- Begid grid layout, i.e. <table> -->
<table>

<grid name="datasource" cols="n">

  <if %datasource.col% eq 1>
    <!-- Begin row, i.e. <tr> -->
    <tr>
  </if>

  <!-- Cell layout, i.e. <td>...</td> -->
  <td>

    <!-- Cells may be unoccupied at the end. -->
    <if %datasource.rownum% le %datasource.rowcount%>
      ...
      <var name="datasource.variable">
      ...
    </if>

    <else>
      <!-- Placeholder to retain cell formatting -->
      &nbsp;
    </else>

  </td>

  <if %datasource.col% eq "n">
    <!-- End row, i.e. </tr> -->
    </tr>
  </if>

</grid>
