<!-- geneSNPDisplayer.jsp -->
<%@ page language="java" contentType="text/html; charset=US-ASCII"
    pageEncoding="US-ASCII"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>
<%@ taglib uri="/WEB-INF/struts-tiles.tld" prefix="tiles" %>

<div id="protein_displayer" class="collection-table">

<c:choose>
  <c:when test="${!empty list}">
    <div>
    <div class="header">
    <h3>${fn:length(list)} Proteins</h3>
    <p>Data Source: <a target="_blank" href="/${WEB_PROPERTIES['webapp.path']}/portal.do?class=DataSet&externalids=Protein+Sequence+FASTA">Araport11</a>,&nbsp;
    <a target="_blank" href="/${WEB_PROPERTIES['webapp.path']}/portal.do?class=DataSet&externalids=Swiss-Prot+data+set">UniProt</a></p>
    </div>

    <c:set var="geneList" value="${geneName}" />
    <table>
      <thead>
       <tr>
         <th>DB Identifier</th>
         <th>Araport</th>
         <th>UniProt</th>
         <th>Length</th>
       </tr>
    </thead>
    <tbody>
      <c:forEach var="row" items="${list}">
        <tr>
           <td> <a href="report.do?id=${row.id}" title="go to Thalemine protein page"> ${row.primaryIdentifier} </a></td>
           <td> <c:choose>
               <c:when test="${!empty row.araportTranscripts}"> ${row.araportTranscripts} </c:when>
               <c:otherwise> N/A </c:otherwise>
           </c:choose> </td>
           <td> <c:choose>
               <c:when test="${!empty row.primaryAccession}"> <a class="extlink" href="http://www.uniprot.org/uniprot/${row.primaryAccession}" title="go to UniProt" target="_blank"> ${row.primaryAccession} </a> </c:when>
               <c:otherwise> N/A </c:otherwise>
           </c:choose> </td>
           <td> <span class="value"> ${row.length} </span> <a target="_new" href="sequenceExporter.do?object=${row.id}"><img class="fasta" title="FASTA" src="model/images/fasta.gif"></img></a>
        </td>
        </tr>
      </c:forEach>
    </tbody>
    </table>

    </div>
   </div>
  </c:when>
  <c:otherwise>
    No protein data available
  </c:otherwise>
</c:choose>

<script type="text/javascript">
        numberOfTableRowsToShow=100000
        trimTable('#protein_displayer');
</script>


</div>
