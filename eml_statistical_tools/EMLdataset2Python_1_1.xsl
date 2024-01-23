<?xml version="1.0"?>
<!-- 
    This stylesheet takes an EML document that includes attribute & physical modules and creates an
    Python program that can read data stored in either delimited or fixed
    text files.   
    
    Users of the Python program may need to substitute the path to their data file in the GET DATA statement.

    CHANGES Corrected header issue and added structure statement
    
    Things that still need work: 
           Multi-line data records
	   Titles and other comments with embedded newlines 
    
    Modified by John Porter, University of Virginia, 2015. 
    Modified version   Copyright 2015 University of Virginia
    original version: Copyright: 2003 Board of Reagents, Arizona State University
    
    This material is based upon work supported by the National Science Foundation 
    under Grant No. 9983132, 0080381, and 0219310. Any opinions, findings and conclusions or recommendation 
    expressed in this material are those of the author(s) and do not necessarily 
    reflect the views of the National Science Foundation (NSF).  
                  
    For Details: http://ces.asu.edu/bdi
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.
 
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text"/>
    <xsl:template match="/">
        <xsl:for-each select="*/dataset">
            <xsl:call-template name="dataset"/>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="partyName">
        <xsl:value-of select="individualName/salutation"/><xsl:text> </xsl:text> <xsl:value-of select="individualName/givenName"/> <xsl:text> </xsl:text> <xsl:value-of select="individualName/surName"/> <xsl:text> - </xsl:text>
        <xsl:value-of select="organizationName"/><xsl:text> </xsl:text>
    </xsl:template>
    
    <xsl:template name="partyNameEmail">
        <xsl:value-of select="individualName/salutation"/><xsl:text> </xsl:text> <xsl:value-of select="individualName/givenName"/> <xsl:text> </xsl:text> <xsl:value-of select="individualName/surName"/><xsl:text> - </xsl:text>
        <xsl:value-of select="positionName"/><xsl:text> </xsl:text>
        <xsl:value-of select="organizationName"/><xsl:text> </xsl:text>
        <xsl:text> - </xsl:text> <xsl:value-of select="electronicMailAddress"/>
    </xsl:template>

    <xsl:template name="dataset">
        <xsl:for-each select="../@packageId"># Package ID: <xsl:value-of
            select="../@packageId"/> Cataloging System:<xsl:value-of select="../@system"/>  <xsl:text>.</xsl:text>  
        </xsl:for-each>
        <xsl:variable name="oneLineTitle">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="title" />
                <xsl:with-param name="replace" select="'&#xA;'" />
                <xsl:with-param name="by" select="' '" />
            </xsl:call-template>
        </xsl:variable>
# Data set title: <xsl:value-of select="$oneLineTitle"/> <xsl:text>.</xsl:text>
        <xsl:for-each select="creator">
# Data set creator: <xsl:text></xsl:text>            
            <xsl:call-template name="partyName"/>
        </xsl:for-each>
        <xsl:for-each select="metadataProvider">
# Metadata Provider: <xsl:text></xsl:text>            
            <xsl:call-template name="partyName"/>
        </xsl:for-each>
        <xsl:for-each select="contact">
# Contact: <xsl:text></xsl:text>            
            <xsl:call-template name="partyNameEmail"/>
        </xsl:for-each>
        <xsl:if test="../access[1]/@system[. = 'https://pasta.lternet.edu']">
# Metadata Link: https://portal.lternet.edu/nis/metadataviewer?packageid=<xsl:value-of select="../@packageId"/>
        </xsl:if>
# Stylesheet v1.0 for metadata conversion into program: John H. Porter, Univ. Virginia, jporter@virginia.edu<xsl:text></xsl:text>      
#<xsl:text></xsl:text>
<xsl:text> 
# This program creates numbered PANDA dataframes named dt1,dt2,dt3...,
# one for each data table in the dataset. It also provides some basic
# summaries of their contents. NumPy and Pandas modules need to be installed
# for the program to run. 
</xsl:text>        
        

     <xsl:if test="dataTable[. !='']">
import numpy as np<xsl:text></xsl:text>
import pandas as pd<xsl:text></xsl:text>

            <xsl:for-each select="dataTable">
<!-- List attributes --><xsl:text/> 

infile<xsl:value-of select="position()"/>  ="<xsl:value-of select="physical/distribution/online/url"></xsl:value-of>".strip()<xsl:text/><xsl:text></xsl:text> 
infile<xsl:value-of select="position()"/>  = infile<xsl:value-of select="position()"/>.replace("https://","http://")
                <xsl:choose>                           
                    <xsl:when test="physical/dataFormat/textFormat/complex/textFixed[. !='']">
                        <xsl:call-template name="readFixed"></xsl:call-template>
                    </xsl:when>
                    <xsl:when test="physical/dataFormat/textFormat/simpleDelimited[. !=''] ">
                        <xsl:call-template name="readCSV"></xsl:call-template>
                    </xsl:when>
                    </xsl:choose>
                    <xsl:variable name="tableNum">
                        <xsl:value-of select="position()"/>  
                    </xsl:variable>               
  
 
<!-- comment out               
# Convert Missing Values to NaN 
                <xsl:for-each select="attributeList">
                    <xsl:for-each select="attribute">  
                       <xsl:variable name="cleanAttribName">
                            <xsl:call-template name="cleanAttribNames">
                                <xsl:with-param name="text" select="attributeName" />
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="measurementScale/interval|measurementScale/ratio[. != '']">
                                <xsl:for-each select="missingValueCode">
                                    <xsl:if test="code[. != '']">
dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>= np.where((str(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>).strip()==str("<xsl:value-of select="code"/>").strip()),np.nan,dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>)<xsl:text></xsl:text>               
                                    </xsl:if> 
                                </xsl:for-each>
                            </xsl:when>
                            <xsl:when test="measurementScale/nominal[. != '']">
                                <xsl:for-each select="missingValueCode">
                                    <xsl:if test="code[. != '']">
dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>= np.where((str(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>).strip()==str("<xsl:value-of select="code"/>").strip()),np.nan,dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>)<xsl:text></xsl:text>               
                                    </xsl:if> 
                                </xsl:for-each> 
                            </xsl:when>
                        </xsl:choose>
                        </xsl:for-each>
                    </xsl:for-each>
                <xsl:text>
                        
                </xsl:text>
-->
                <xsl:call-template name="set_col_types">
                    <xsl:with-param name="tableNum" select="$tableNum"/>
                </xsl:call-template>
      
print("Here is a description of the data frame dt<xsl:value-of select="$tableNum"/> and number of lines\n")
print(dt<xsl:value-of select="$tableNum"/>.info())
print("--------------------\n\n")                
print("Here is a summary of numerical variables in the data frame dt<xsl:value-of select="$tableNum"/>\n")
print(dt<xsl:value-of select="$tableNum"/>.describe())
print("--------------------\n\n")                
                         
print("The analyses below are basic descriptions of the variables. After testing, they should be replaced.\n")                 
<!--  Generate some default statistical summaries for vectors in the data frame  -->       
                <xsl:for-each select="attributeList">
                    <xsl:for-each select="attribute">  
                        <xsl:variable name="cleanAttribName">
                            <xsl:call-template name="cleanAttribNames">
                                <xsl:with-param name="text" select="attributeName" />
                            </xsl:call-template>
                        </xsl:variable>
print(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>.describe())<xsl:text></xsl:text>               
print("--------------------\n\n")
                    </xsl:for-each>
                </xsl:for-each>     
                <xsl:text>
                    
                </xsl:text>
        </xsl:for-each>
     </xsl:if>  
        </xsl:template>

<xsl:template name="readCSV"> 
dt<xsl:value-of select="position()"/> =pd.read_csv(infile<xsl:value-of select="position()"/><xsl:text> </xsl:text>
    <xsl:if test="physical/dataFormat/textFormat/numHeaderLines[.!='']">
          ,skiprows=<xsl:value-of select="physical/dataFormat/textFormat/numHeaderLines"/><xsl:text></xsl:text>
    </xsl:if>
    <xsl:choose>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='0x20']">
            ,sep=" " <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='#x20']">
            ,sep=" " <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='0x09']">
            ,sep="\t" <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='#x09']">
            ,sep="\t" <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='space']">
            ,sep=" " <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='Space']">
            ,sep=" " <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='SPACE']">
            ,sep=" " <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='tab']">
            ,sep="\t" <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='Tab']">
            ,sep="\t" <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='TAB']">
            ,sep="\t" <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='0x2c']">
            ,sep="," <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='comma']">
            ,sep="," <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='Comma']">
            ,sep="," <xsl:text/>
        </xsl:when>
        <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter[.='COMMA']">
            ,sep="," <xsl:text/>
        </xsl:when>
        <xsl:otherwise>
            ,sep="<xsl:value-of select="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter"/>" <xsl:text> </xsl:text>
        </xsl:otherwise>
    </xsl:choose>
    
    <xsl:if test="physical/dataFormat/textFormat/simpleDelimited/quoteCharacter[.!='']">
        <xsl:choose>
            <xsl:when test='physical/dataFormat/textFormat/simpleDelimited/quoteCharacter[.="&apos;"]'>
                ,quotechar="<xsl:value-of select="physical/dataFormat/textFormat/simpleDelimited/quoteCharacter"/>"<xsl:text> </xsl:text>
            </xsl:when>
            <xsl:when test="physical/dataFormat/textFormat/simpleDelimited/quoteCharacter[.='&quot;']">
                ,quotechar='<xsl:value-of select="physical/dataFormat/textFormat/simpleDelimited/quoteCharacter"/>'<xsl:text> </xsl:text>
            </xsl:when>
            <xsl:otherwise>
                ,quotechar="<xsl:value-of select="physical/dataFormat/textFormat/simpleDelimited/quoteCharacter"/>"<xsl:text> </xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:if>
    <xsl:for-each select="attributeList">
           , names=[<xsl:text></xsl:text>
        <xsl:for-each select="attribute">
<!--clean bad characters in attribute names -->
            <xsl:variable name="cleanAttribName">
                <xsl:call-template name="cleanAttribNames">
                    <xsl:with-param name="text" select="attributeName" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="position()!=last()">
                    "<xsl:value-of select="$cleanAttribName"/>",    <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="$cleanAttribName"/>"   <xsl:text> </xsl:text>                             
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        </xsl:for-each>
    <xsl:text>]</xsl:text>
    <xsl:call-template name="col_types">
        <xsl:with-param name="attributeList"/>
    </xsl:call-template>
    <xsl:call-template name="parseDates">
        <xsl:with-param name="attributeList"/>
    </xsl:call-template>
    <xsl:call-template name="addMissingList">
        <xsl:with-param name="attributeList"/>
    </xsl:call-template>
    )<xsl:text></xsl:text>
</xsl:template>
    
    <xsl:template name="readFixed">
dt<xsl:value-of select="position()"/> =pd.read_fwf(infile<xsl:value-of select="position()"/><xsl:text/>
        <xsl:for-each select="attributeList">       
        ,colspecs=[<xsl:text></xsl:text>
            <xsl:for-each select="attribute">
            <!--clean bad characters in attribute names -->
            <xsl:variable name="cleanAttribName">
                <xsl:call-template name="cleanAttribNames">
                    <xsl:with-param name="text" select="attributeName" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:if test="../../physical/dataFormat/textFormat/complex/textFixed[. !='']">
                <xsl:variable name="nodeNum" select="position()"/>
                <xsl:variable name="prevNode" select="position() - 1"/>
                <xsl:choose>
                <xsl:when test="$nodeNum=last() ">
          (<xsl:value-of select="../../physical/dataFormat/textFormat/complex/textFixed[$nodeNum]/fieldStartColumn -1"/>,<xsl:value-of select="../../physical/dataFormat/textFormat/complex/textFixed[$nodeNum]/fieldStartColumn + ../../physical/dataFormat/textFormat/complex/textFixed[$nodeNum]/fieldWidth -1"/>)<xsl:text></xsl:text>
                </xsl:when>
                <xsl:otherwise>
          (<xsl:value-of select="../../physical/dataFormat/textFormat/complex/textFixed[$nodeNum]/fieldStartColumn -1"/>,<xsl:value-of select="../../physical/dataFormat/textFormat/complex/textFixed[$nodeNum]/fieldStartColumn + ../../physical/dataFormat/textFormat/complex/textFixed[$nodeNum]/fieldWidth -1"/>),<xsl:text></xsl:text>
                </xsl:otherwise>
                </xsl:choose>
            </xsl:if> 
            <xsl:text> </xsl:text> 
        </xsl:for-each>  
            ]<xsl:text></xsl:text>
        </xsl:for-each>  
  <xsl:for-each select="attributeList">        
         ,names=[<xsl:text></xsl:text>
            <xsl:for-each select="attribute">
                <!--clean bad characters in attribute names -->
                <xsl:variable name="cleanAttribName">
                    <xsl:call-template name="cleanAttribNames">
                        <xsl:with-param name="text" select="attributeName" />
                    </xsl:call-template>
                </xsl:variable>

                <xsl:choose>
                    <xsl:when test="position()!=last()">
          "<xsl:value-of select="$cleanAttribName"/>",   <xsl:text/> 
                    </xsl:when>
                    <xsl:otherwise>
          "<xsl:value-of select="$cleanAttribName"/>"<xsl:text/>                            
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            ]<xsl:text></xsl:text>  
  </xsl:for-each>
  <xsl:call-template name="col_types">
     <xsl:with-param name="attributeList"/>
   </xsl:call-template>
   <xsl:call-template name="parseDates">
       <xsl:with-param name="attributeList"/>
    </xsl:call-template>
    <xsl:call-template name="addMissingList">
        <xsl:with-param name="attributeList"/>
     </xsl:call-template>
        ,skiprows=<xsl:value-of select="physical/dataFormat/textFormat/numHeaderLines"/><xsl:text></xsl:text>
        )<xsl:text></xsl:text>
# This creates a data.frame named:  dt<xsl:value-of select="position()"/>     
    
    </xsl:template>
    <xsl:template name="cleanAttribNames">
        <xsl:param name="text"/>
        <xsl:variable name="a1">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$text"/>
                <xsl:with-param name="replace" select="' '"/>
                <xsl:with-param name="by" select="'_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a2">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a1"/>
                <xsl:with-param name="replace" select="'('"/>
                <xsl:with-param name="by" select="'_paren_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a3">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a2"/>
                <xsl:with-param name="replace" select="')'"/>
                <xsl:with-param name="by" select="'_paren_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a4">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a3"/>
                <xsl:with-param name="replace" select="'%'"/>
                <xsl:with-param name="by" select="'_percent_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a5">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a4"/>
                <xsl:with-param name="replace" select="'/'"/>
                <xsl:with-param name="by" select="'_per_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a6">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a5"/>
                <xsl:with-param name="replace" select="'+'"/>
                <xsl:with-param name="by" select="'_plus_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a7">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a6"/>
                <xsl:with-param name="replace" select="'-'"/>
                <xsl:with-param name="by" select="'_hyphen_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a8">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a7"/>
                <xsl:with-param name="replace" select="'*'"/>
                <xsl:with-param name="by" select="'_astrix_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a9">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a8"/>
                <xsl:with-param name="replace" select="'^'"/>
                <xsl:with-param name="by" select="'_carat_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a10">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a9"/>
                <xsl:with-param name="replace" select="'.'"/>
                <xsl:with-param name="by" select="'_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a11">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a10"/>
                <xsl:with-param name="replace" select="'['"/>
                <xsl:with-param name="by" select="'_bracket_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a12">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a11"/>
                <xsl:with-param name="replace" select="']'"/>
                <xsl:with-param name="by" select="'_bracket_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a13">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a12"/>
                <xsl:with-param name="replace" select="':'"/>
                <xsl:with-param name="by" select="'_colon_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a14">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a13"/>
                <xsl:with-param name="replace" select="';'"/>
                <xsl:with-param name="by" select="'_semicolon_'"/>
            </xsl:call-template>
        </xsl:variable>
	        <xsl:variable name="a15">
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="$a14"/>
                <xsl:with-param name="replace" select="'='"/>
                <xsl:with-param name="by" select="'_equals_'"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:variable name="a16">
            <xsl:call-template name="string-add-v-to-leading-numbers">
                <xsl:with-param name="text" select="$a15"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="$a16"/>
    </xsl:template>
    
    <xsl:template name="string-replace-all">
        <xsl:param name="text"/>
        <xsl:param name="replace"/>
        <xsl:param name="by"/>
        <xsl:choose>
            <xsl:when test="contains($text, $replace)">
                <xsl:value-of select="substring-before($text,$replace)"/>
                <xsl:value-of select="$by"/>
                <xsl:call-template name="string-replace-all">
                    <xsl:with-param name="text" select="substring-after($text,$replace)"/>
                    <xsl:with-param name="replace" select="$replace"/>
                    <xsl:with-param name="by" select="$by"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="string-add-v-to-leading-numbers">
        <xsl:param name="text"/>
        <xsl:choose>
            <xsl:when test="contains('0123456789', substring($text,1,1))">
                <xsl:value-of select="concat('v_',$text)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
<xsl:template name="getDateFormat">
    <xsl:param name="text"/>
    <xsl:variable name="d1">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$text" />
            <xsl:with-param name="replace" select="'YYYY'" />
            <xsl:with-param name="by" select="'%Y'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d2">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d1" />
            <xsl:with-param name="replace" select="'yyyy'" />
            <xsl:with-param name="by" select="'%Y'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d3">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d2" />
            <xsl:with-param name="replace" select="'yy'" />
            <xsl:with-param name="by" select="'%y'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d4">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d3" />
            <xsl:with-param name="replace" select="'YY'" />
            <xsl:with-param name="by" select="'%y'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d5">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d4" />
            <xsl:with-param name="replace" select="'MM'" />
            <xsl:with-param name="by" select="'%m'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d6">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d5" />
            <xsl:with-param name="replace" select="'dd'" />
            <xsl:with-param name="by" select="'%d'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d7">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d6" />
            <xsl:with-param name="replace" select="'DD'" />
            <xsl:with-param name="by" select="'%d'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d8">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d7" />
            <xsl:with-param name="replace" select="'hh'" />
            <xsl:with-param name="by" select="'%H'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d9">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d8" />
            <xsl:with-param name="replace" select="'HH'" />
            <xsl:with-param name="by" select="'%H'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d10">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d9" />
            <xsl:with-param name="replace" select="'mm.mm'" />
            <xsl:with-param name="by" select="'%M'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d11">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d10" />
            <xsl:with-param name="replace" select="'mm'" />
            <xsl:with-param name="by" select="'%M'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d12">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d11" />
            <xsl:with-param name="replace" select="'ss.sss'" />
            <xsl:with-param name="by" select="'%S'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d13">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d12" />
            <xsl:with-param name="replace" select="'ss'" />
            <xsl:with-param name="by" select="'%S'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d14">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d13" />
            <xsl:with-param name="replace" select="'www'" />
            <xsl:with-param name="by" select="'%b'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d15">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d14" />
            <xsl:with-param name="replace" select="'WWW'" />
            <xsl:with-param name="by" select="'%b'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d16">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d15" />
            <xsl:with-param name="replace" select="'A/P'" />
            <xsl:with-param name="by" select="'%p'" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d17">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d16" />
            <xsl:with-param name="replace" select="'Z'" />
            <xsl:with-param name="by" select="''" />
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d18">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d17"/>
            <xsl:with-param name="replace" select="'MON'"/>
            <xsl:with-param name="by" select="'%b'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="d19">
        <xsl:call-template name="string-replace-all">
            <xsl:with-param name="text" select="$d18"/>
            <xsl:with-param name="replace" select="'mon'"/>
            <xsl:with-param name="by" select="'%b'"/>
        </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="$d19"/>
</xsl:template>
    <xsl:template name="attributeInfo">
        <xsl:param name="tableNum"/>
        <xsl:for-each select="attributeList"> 
            dataInfodt<xsl:value-of select="$tableNum"/> &lt;- data.frame("attributeName"=c(<xsl:call-template name="attributeNameList"/>
            <xsl:if test="attribute//attributeLabel[. !='']"  >
                ,"attributeLabel"=c(<xsl:call-template name="attributeLabelList"/>
            </xsl:if>
            ,"attributeDefinition"=c(<xsl:call-template name="attributeDefinitionList"/>
            ,"attributeMeasurementScale"=c(<xsl:call-template name="attributeMeasurementScaleList"/>
            ,"attributeUnit"=c(<xsl:call-template name="attributeUnitList"/>
            ,stringsAsFactors=F)        
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="attributeNameList">
        <xsl:for-each select="attribute">
            <xsl:variable name="cleanAttribName">
                <xsl:call-template name="cleanAttribNames">
                    <xsl:with-param name="text" select="attributeName" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="position()!=last()"> 
                    "<xsl:value-of select="$cleanAttribName" />", <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="$cleanAttribName" />") <xsl:text> </xsl:text>
                </xsl:otherwise>
            </xsl:choose>         
        </xsl:for-each>       
    </xsl:template>
    <xsl:template name="attributeLabelList">
        <xsl:for-each select="attribute">
            <xsl:choose>
                <xsl:when test="position()!=last()"> 
                    "<xsl:value-of select="attributeLabel" />", <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="attributeLabel" />") <xsl:text> </xsl:text>
                </xsl:otherwise>
            </xsl:choose>         
        </xsl:for-each>       
    </xsl:template>
    <xsl:template name="attributeDefinitionList">
        <xsl:for-each select="attribute">
            <xsl:choose>
                <xsl:when test="position()!=last()"> 
                    "<xsl:value-of select="attributeDefinition" />", <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="attributeDefinition" />") <xsl:text> </xsl:text>
                </xsl:otherwise>
            </xsl:choose>         
        </xsl:for-each>       
    </xsl:template>
    <xsl:template name="attributeMeasurementScaleList">
        <xsl:for-each select="attribute">
            <xsl:choose>
                <xsl:when test="position()=last()">
                    <xsl:choose>
                        <xsl:when test="measurementScale/nominal[. !='']">
                            "nominal")<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/ordinal[. !='']">
                            "ordinal")<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/interval[. !='']">
                            "interval")<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/ratio[. !='']">
                            "ratio")<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/dateTime[. !='']">
                            "dateTime")<xsl:text> </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="measurementScale/nominal[. !='']">
                            "nominal",<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/ordinal[. !='']">
                            "ordinal",<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/interval[. !='']">
                            "interval",<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/ratio[. !='']">
                            "ratio",<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/dateTime[. !='']">
                            "dateTime",<xsl:text> </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>         
        </xsl:for-each>       
    </xsl:template>
    <xsl:template name="attributeUnitList">
        <xsl:for-each select="attribute">
            <xsl:choose>
                <xsl:when test="position()=last()">
                    <xsl:choose>
                        <xsl:when test="measurementScale/nominal[. !='']">
                            NA)<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/ordinal[. !='']">
                            NA)<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/interval[. !='']">
                            <xsl:choose>
                                <xsl:when test="measurementScale/interval/unit/standardUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/interval/unit/standardUnit"/>")<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="measurementScale/interval/unit/customUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/interval/unit/customUnit"/>")<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    NA)<xsl:text> </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="measurementScale/ratio[. !='']">
                            <xsl:choose>
                                <xsl:when test="measurementScale/ratio/unit/standardUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/ratio/unit/standardUnit"/>")<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="measurementScale/ratio/unit/customUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/ratio/unit/customUnit"/>")<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    NA,<xsl:text> </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="measurementScale/dateTime[. !='']">
                            "<xsl:value-of select="measurementScale/dateTime/formatString"/>")<xsl:text> </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:choose>
                        <xsl:when test="measurementScale/nominal[. !='']">
                            NA,<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/ordinal[. !='']">
                            NA,<xsl:text> </xsl:text>
                        </xsl:when>
                        <xsl:when test="measurementScale/interval[. !='']">
                            <xsl:choose>
                                <xsl:when test="measurementScale/interval/unit/standardUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/interval/unit/standardUnit"/>",<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="measurementScale/interval/unit/customUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/interval/unit/customUnit"/>",<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    NA,<xsl:text> </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="measurementScale/ratio[. !='']">
                            <xsl:choose>
                                <xsl:when test="measurementScale/ratio/unit/standardUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/ratio/unit/standardUnit"/>",<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:when test="measurementScale/ratio/unit/customUnit[. !='']">
                                    "<xsl:value-of select="measurementScale/ratio/unit/customUnit"/>",<xsl:text> </xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    NA,<xsl:text> </xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="measurementScale/dateTime[. !='']">
                            "<xsl:value-of select="measurementScale/dateTime/formatString"/>",<xsl:text> </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </xsl:otherwise>
            </xsl:choose>        
        </xsl:for-each>       
    </xsl:template>
    <xsl:template name="codeInfo">
        <xsl:param name="tableNum"/>
        <xsl:for-each select="attributeList"> 
codeInfodt<xsl:value-of select="$tableNum"/> &lt;- data.frame("attributeName"=c(<xsl:call-template name="codeNameList"/>
            ,"code"=c(<xsl:call-template name="codeList"/>
            ,"definition"=c(<xsl:call-template name="codeDefinitionList"/>
            ,stringsAsFactors=F)
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="codeNameList">
        <xsl:for-each select="attribute/measurementScale/*/nonNumericDomain/enumeratedDomain/codeDefinition">
            <xsl:variable name="cleanAttribName">
                <xsl:call-template name="cleanAttribNames">
                    <xsl:with-param name="text" select="../../../../../attributeName" />
                </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="position()!=last()"> 
                    "<xsl:value-of select="$cleanAttribName" />", <xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="$cleanAttribName" />") <xsl:text> </xsl:text>
                </xsl:otherwise>
            </xsl:choose>                   
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="codeList">
        <xsl:for-each select="attribute/measurementScale/*/nonNumericDomain/enumeratedDomain/codeDefinition">
            <xsl:choose>
                <xsl:when test="position()=last()">
                    "<xsl:value-of select="code"/>")<xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="code"/>",<xsl:text> </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="codeDefinitionList">
        <xsl:for-each select="attribute/measurementScale/*/nonNumericDomain/enumeratedDomain/codeDefinition">
            <xsl:choose>
                <xsl:when test="position()=last()">
                    "<xsl:value-of select="definition"/>")<xsl:text> </xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    "<xsl:value-of select="definition"/>",<xsl:text> </xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    <xsl:template name="col_types">
# data type checking is commented out because it may cause data
# loads to fail if the data contains inconsistent values. Uncomment 
# the following lines to enable data type checking
        <xsl:for-each select="attributeList"> 
#            ,dtype={<xsl:text> </xsl:text>
            <xsl:for-each select="attribute">
                <xsl:variable name="cleanAttribName">
                    <xsl:call-template name="cleanAttribNames">
                        <xsl:with-param name="text" select="attributeName"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="measurementScale/interval|measurementScale/ratio[. != '']">
                        <xsl:choose>
                            <xsl:when test="measurementScale/*/numericDomain/numberType[. != 'real']">
#             '<xsl:value-of select="$cleanAttribName"/>':'int' <xsl:if test="position()!=last()"
                 >,</xsl:if><xsl:text> </xsl:text> 
                            </xsl:when>
                            <xsl:otherwise>
#             '<xsl:value-of select="$cleanAttribName"/>':'float' <xsl:if test="position()!=last()">,</xsl:if><xsl:text> </xsl:text>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="measurementScale/nominal[. != '']"> 
#             '<xsl:value-of select="$cleanAttribName"/>':'str' <xsl:if test="position()!=last()">,</xsl:if><xsl:text> </xsl:text>
                    </xsl:when>
                    <xsl:when test="measurementScale/dateTime[. != '']">
                        <!-- read dates as strings - for now -->
#             '<xsl:value-of select="$cleanAttribName"/>':'str' <xsl:if test="position()!=last()">,</xsl:if><xsl:text> </xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
#             '<xsl:value-of select="$cleanAttribName"/>':'str'<xsl:if test="position()!=last()">,</xsl:if><xsl:text> </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>               
            </xsl:for-each>
        </xsl:for-each>
#        <xsl:text>}</xsl:text><xsl:text></xsl:text>
    </xsl:template>
    <xsl:template name="parseDates">
        <xsl:for-each select="attributeList">
            <xsl:if test="attribute/measurementScale/dateTime/formatString[. != '']">
          ,parse_dates=[<xsl:text></xsl:text>
                <xsl:for-each select="attribute">
                    <xsl:variable name="cleanAttribName">
                        <xsl:call-template name="cleanAttribNames">
                            <xsl:with-param name="text" select="attributeName"/>
                        </xsl:call-template>
                    </xsl:variable>  
                    <xsl:if test="measurementScale/dateTime/formatString[. != '']">
                        '<xsl:value-of select="$cleanAttribName"/>',<xsl:text></xsl:text>
                    </xsl:if>
                </xsl:for-each>
                ]<xsl:text> </xsl:text>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
<xsl:template name="set_col_types">
    <xsl:param name="tableNum"/>
# Coerce the data into the types specified in the metadata <xsl:text></xsl:text>
            <xsl:for-each select="attributeList"> 
                <xsl:for-each select="attribute">
                    <xsl:variable name="cleanAttribName">
                        <xsl:call-template name="cleanAttribNames">
                            <xsl:with-param name="text" select="attributeName"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="measurementScale/interval|measurementScale/ratio[. != '']">
                            <xsl:choose>
                                <xsl:when test="measurementScale/*/numericDomain/numberType[. != 'real']">
dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>=pd.to_numeric(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>,errors='coerce',downcast='integer')<xsl:text> </xsl:text> 
                                </xsl:when>
                                <xsl:otherwise>
dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>=pd.to_numeric(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>,errors='coerce')<xsl:text> </xsl:text> 
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="measurementScale/nominal[. != '']"> 
dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>=dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>.astype('category')<xsl:text> </xsl:text> 
                        </xsl:when>
                        <xsl:when test="measurementScale/dateTime[. != '']">
# Since date conversions are tricky, the coerced dates will go into a new column with _datetime appended
# This new column is added to the dataframe but does not show up in automated summaries below. 
dt<xsl:value-of select="$tableNum"/>=dt<xsl:value-of select="$tableNum"/>.assign(<xsl:value-of select="$cleanAttribName"/>_datetime=pd.to_datetime(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>,errors='coerce'))<xsl:text> </xsl:text> 
                        </xsl:when>
                        <xsl:otherwise>
dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>=str(dt<xsl:value-of select="$tableNum"/>.<xsl:value-of select="$cleanAttribName"/>)<xsl:text> </xsl:text> 
                        </xsl:otherwise>
                    </xsl:choose>               
                </xsl:for-each>
            </xsl:for-each>
<xsl:text></xsl:text>
        </xsl:template>
    <xsl:template name="addMissingList">
        <xsl:for-each select="attributeList"> 
            <xsl:if test="attribute/missingValueCode[. != '']">
            ,na_values={<xsl:text/>
            <xsl:for-each select="attribute">
                <!--change spaces to . in attribute names -->
                <xsl:variable name="cleanAttribName">
                    <xsl:call-template name="cleanAttribNames">
                        <xsl:with-param name="text" select="attributeName"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:if test="missingValueCode[. !='']">
                  '<xsl:value-of select="$cleanAttribName"/>':[<xsl:text></xsl:text>
                 <xsl:for-each select="missingValueCode">
                          '<xsl:value-of select="code"/>'<xsl:text>,</xsl:text>
                 </xsl:for-each>],<xsl:text></xsl:text>
                </xsl:if>
            </xsl:for-each>} 
            </xsl:if>
        </xsl:for-each> <xsl:text/>
    </xsl:template>
    
</xsl:stylesheet>
