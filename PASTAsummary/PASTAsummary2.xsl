<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
<xsl:param name="contactEmail"/>
    <xsl:output method="html"/>
<xsl:template name="root" match="/">
    <xsl:for-each select="/pastaSummaries/pastaSummary/contacts/contact/electronicMailAddress">
        <xsl:if test="contains(.,$contactEmail)='true'">
       <html>
       <center>
        <h1>PASTA Download Summary for <xsl:value-of select="$contactEmail"/></h1>
        <h2><xsl:value-of select="/pastaSummaries/fromTime"/> through <xsl:value-of select="/pastaSummaries/toTime"/></h2>
        </center>
    <xsl:for-each select="/pastaSummaries/pastaSummary">
        <xsl:call-template name="pastaSummary"/>
    </xsl:for-each>
       </html>
        </xsl:if>
    </xsl:for-each>
         
</xsl:template>
    <xsl:template name="pastaSummary">
        <xsl:for-each select="./contacts/contact/electronicMailAddress">
        <xsl:if test="contains(.,$contactEmail)='true'">
        <xsl:if test="../../../dataDownloadTotalCount > 0">
            <hr>
                <p><b> <xsl:value-of select="../../../packageId"/> - <xsl:value-of select="../../../title"/></b><br></br>
                Metadata Downloads: <xsl:value-of select="../../../metadataDownloadCount"/>,     Data Downloads: <xsl:value-of select="../../../dataDownloadTotalCount"/> 
                <xsl:for-each select="../../../entities/entity">
                    <xsl:call-template name="entity"/>
                </xsl:for-each>
            </p>
        </hr>
        </xsl:if>
        </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template  name="entity">
            <p>Data Entity: <xsl:value-of select="./entityName"/> had <xsl:value-of select="./entityDownloadCount"/> downloads by <xsl:value-of select="./entityUserCount"/> distinct users<br></br>
                <table border='0'>
                <xsl:for-each select="./entityUsers/entityUser">
                    <xsl:call-template name="entityUser"/>
                </xsl:for-each>
                </table>
            </p>
          
    </xsl:template>
    <xsl:template  name="entityUser">
        <tr><td>user: <xsl:value-of select="./entityUserId"/></td> <td align="right"><xsl:value-of select="./entityUserDownloadCount"/> downloads</td></tr>
    </xsl:template>
</xsl:stylesheet>