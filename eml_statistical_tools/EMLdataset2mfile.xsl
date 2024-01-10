<?xml version="1.0"?>
<!-- 
This stylesheet takes an EML document as input and creates a MATLAB m-file function to download and parse
data from all dataTable entities in simpleDelimited text format that contain download urls and attribute descriptors.

The m-file returns a struct variable (s) containing the following fields, with information for each
dataTable entity in a separate structure dimension:
   *  project = name of the project responsible for the data set (repeated for each dimension of s)
   *  packageid = data set package identifier (repeated for each dimension of s)
   *  title = data set title (repeated for each dimension of s)
   *  abstract = data set abstract (repeated for each dimension of s)
   *  keywords = data set keywords (repeated for each dimension of s)
   *  creator = data set creator information (repeated for each dimension of s)
   *  contact = data set contact information (repeated for each dimension of s)
   *  rights = data set intellectual rights information (repeated for each dimension of s)
   *  dates = data set temporal coverage information (repeated for each dimension of s)
   *  geography = data set geographic coverage (cell array of descriptions plus corresponding 
         numeric arrays of longitude/latitude pairs for NW, NE, SE, SW corners; repeated for each dimension of s)
   *  taxa = data set taxonomic coverage (species and common names only; repeated for each dimension of s)
   *  methods = data set methods and instrumentation (repeated for each dimension of s)
   *  sampling = data set sampling description (repeated for each dimension of s)
   *  entity = data table (entity) name
   *  url = data table (entity) download URL
   *  filename = data set file (object) name
   *  description = data  table (entity) description
   *  names = cell array of column (attribute) names
   *  units = cell array of column (attribute) units
   *  definitions = cell array of column (attribute) definitions
   *  datatypes = cell array of column (attribute) data types
   *  scales = cell array of column (attribute) measurement scales
   *  codes = cell array of column (attribute) codes and code definitions
   *  bounds = cell array of column (attribute) bounds (e.g. 'value > 0; value <= 10')
   *  data = cell array of column (attribute) data arrays (i.e. numeric arrays and cell arrays of strings)

Note that the output of the XSLT is a plain text file that must be saved as a file with a .m
extension to be called from MATLAB. The m-file also calls 'urlwrite' to download the data
objects, which requires MATLAB 6.5 (R13) or higher, and calls 'textscan.m' to parse the data,
which requires MATLAB 7 (R14) or higher. The XSLT must be rewritten to use the 'textread.m'
function or equivalent to parse files using MATLAB 6.5.

version 1.1 (22-Mar-2017)

Copyright 2012-2017 Wade M. Sheldon and the Georgia Coastal Ecosystems LTER Program

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
   
   <!-- set options for text output, stripping extra whitespace globally -->
   <xsl:output method="text" indent="no"/>
   <xsl:strip-space elements="*"/>
   
   <!-- master template -->
   <xsl:template match="/">
      <xsl:for-each select="*/dataset">
         <xsl:call-template name="dataset"/>
      </xsl:for-each>
   </xsl:template>
   
   <!-- parse data set info -->
   <xsl:template name="dataset">
      
      <!-- check for at least one dataTable entity with a download url -->
      <xsl:if test="dataTable/physical/distribution/online/url[@function='download'] != '' or dataTable/physical/distribution/online/url[not(@function)] != ''">
         <xsl:call-template name="code">
            <xsl:with-param name="packageId">
               <xsl:value-of select="../@packageId"/>
            </xsl:with-param>
         </xsl:call-template>
         <xsl:call-template name="metadata">   
            <xsl:with-param name="packageId">
               <xsl:value-of select="../@packageId"/>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:if>
      
      <!-- call template to add subfunction for download the data objects -->
      <xsl:call-template name="get_file"/>
      
   </xsl:template>
   
   <!-- generate function code -->
   <xsl:template name="code">
      
      <!-- get packageId parameter from template parameter -->
      <xsl:param name="packageId"/>
      
      <!-- generate function header -->
      <xsl:text>function [s,msg] = </xsl:text><xsl:value-of select="translate($packageId,'-.','__')"/><xsl:text>(pn,cachedata,username,password,entities)&#xD;</xsl:text>
      <xsl:text>%Retrieves and loads EML-described data tables for data package </xsl:text><xsl:value-of select="$packageId"/><xsl:text>&#xD;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%syntax: [s,msg] = </xsl:text><xsl:value-of select="translate($packageId,'-.','__')"/><xsl:text>(pn,cachedata,username,password,entities)&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>      
      <xsl:text>%input:&#xD;&#xA;</xsl:text>
      <xsl:text>%   pn = file system path for saving temporary files (default = pwd)&#xD;&#xA;</xsl:text>
      <xsl:text>%   cachedata = option to use cached entity files if they exist in pn (0 = no/default, 1 = yes)&#xD;&#xA;</xsl:text>
      <xsl:text>%   username = username for HTTPS authentication (default = '')&#xD;&#xA;</xsl:text>
      <xsl:text>%   password = password for HTTPS authentication (default = '')&#xD;&#xA;</xsl:text>
      <xsl:text>%   entities = cell array of entities to retrieve (default = '' for all)&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%output:&#xD;&#xA;</xsl:text>
      <xsl:text>%   s = 1xn structure containing metadata and data arrays for each downloadable data table, with fields:&#xD;&#xA;</xsl:text>
      <xsl:text>%      project = name of the project responsible for the data set (string; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      packageid = data set packageID (string; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      title = data set title (string; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      abstract = data set abstract (string; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      keywords = data set keywords (string; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      creator = data set creator information (cell array; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      contact = data set contact information (cell array; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      rights = data set intellectual rights information (cell array; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      dates = data set temporal coverage (cell array; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      geography = data set geographic coverage (cell array; cell array of descriptions plus corresponding&#xD;&#xA;</xsl:text> 
      <xsl:text>%         numeric arrays of longitude/latitude pairs for NW, NE, SE, SW corners; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      taxa = data set taxonomic coverage (cell array; species and common names only; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      methods = data set methods and instrumentation (cell array; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      sampling = data set sampling description (cell array; repeated for each dimension of s)&#xD;&#xA;</xsl:text>
      <xsl:text>%      entity = data set table (entity) name (string) &#xD;&#xA;</xsl:text>
      <xsl:text>%      url = data table (entity) download URL (string)&#xD;&#xA;</xsl:text>
      <xsl:text>%      filename = data set file (object) name (string)&#xD;&#xA;</xsl:text>
      <xsl:text>%      description = data table (entity) description (string)&#xD;&#xA;</xsl:text>
      <xsl:text>%      names = cell array of column names&#xD;&#xA;</xsl:text>
      <xsl:text>%      units = cell array of column units&#xD;&#xA;</xsl:text>
      <xsl:text>%      definitions = cell array of column definitions&#xD;&#xA;</xsl:text>
      <xsl:text>%      datatypes = cell array of column data types&#xD;&#xA;</xsl:text>
      <xsl:text>%      scales = cell array of column measurement scale types&#xD;&#xA;</xsl:text>
      <xsl:text>%      codes = cell array of column codes and code definitions&#xD;&#xA;</xsl:text>
      <xsl:text>%      bounds = cell array of column bounds (e.g. 'value &gt; 0; value &lt; 10')&#xD;&#xA;</xsl:text>
      <xsl:text>%      data = cell array of column data arrays (i.e. typed numeric arrays and cell arrays of strings)&#xD;&#xA;</xsl:text>
      <xsl:text>%   msg = text of any error message&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%notes:&#xD;&#xA;</xsl:text>
      <xsl:text>%   1) This m-file calls 'urlwrite' to download EML-described data objects,&#xD;&#xA;</xsl:text>
      <xsl:text>%      which requires MATLAB 6.5 (R13) or higher, and calls 'textscan.m' to parse&#xD;&#xA;</xsl:text>
      <xsl:text>%      the downloaded data files, which requires MATLAB 7 (R14) or higher.&#xD;&#xA;</xsl:text>
      <xsl:text>%   2) If HTTPS downloads fail (e.g. due to SSL errors), cURL with SSL libraries will be used if available in the system path (see http://curl.haxx.se/)&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%auto-generated by EMLdataset2mfile.xsl v1.1 (https://gce-lter.marsci.uga.edu/public/xsl/toolbox/EMLdataset2mfile.xsl)&#xD;&#xA;</xsl:text>
      <xsl:text>%by Wade Sheldon &lt;sheldon@uga.edu&gt;, Georgia Coastal Ecosystems LTER&#xD;&#xA;</xsl:text>
      <xsl:text>&#xD;&#xA;</xsl:text>
      <xsl:text>%check for omitted path, set working directory&#xD;&#xA;</xsl:text>
      <xsl:text>if exist('pn','var') ~= 1&#xD;&#xA;</xsl:text>
      <xsl:text>   pn = pwd;&#xD;&#xA;</xsl:text>
      <xsl:text>elseif ~isdir(pn)&#xD;&#xA;</xsl:text>
      <xsl:text>   pn = pwd;&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%check for omitted cachedata argument, set default to 0 (no) to force new download&#xD;&#xA;</xsl:text>
      <xsl:text>if exist('cachedata','var') ~= 1&#xD;&#xA;</xsl:text>
      <xsl:text>   cachedata = 0;&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%check for omitted username argument, set default to '' for none&#xD;&#xA;</xsl:text>
      <xsl:text>if exist('username','var') ~= 1&#xD;&#xA;</xsl:text>
      <xsl:text>   username = '';&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%check for omitted password argument, set default to '' for none&#xD;&#xA;</xsl:text>
      <xsl:text>if exist('password','var') ~= 1&#xD;&#xA;</xsl:text>
      <xsl:text>   password = '';&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%check for omitted entities argument, set default to '' for all&#xD;&#xA;</xsl:text>
      <xsl:text>if exist('entities','var') ~= 1 || isnumeric(entities)&#xD;&#xA;</xsl:text>
      <xsl:text>   entities = '';&#xD;&#xA;</xsl:text>
      <xsl:text>elseif ischar(entities)&#xD;&#xA;</xsl:text>
      <xsl:text>   entities = cellstr(entities);&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%initialize output and runtime variables&#xD;&#xA;</xsl:text>      
      <xsl:text>s = [];&#xD;&#xA;</xsl:text>      
      <xsl:text>msg = '';&#xD;&#xA;</xsl:text>      
      <xsl:text>fn = '';&#xD;&#xA;&#xD;&#xA;</xsl:text>      
      
      <!-- call template to generate file download and parsing for each dataTable element -->
      <xsl:for-each select="dataTable">
         <xsl:call-template name="download">
            <xsl:with-param name="packageId"/>
         </xsl:call-template>
      </xsl:for-each>
      
   </xsl:template>
   
   <!-- generate download data code -->
   <xsl:template name="download">
      
      <xsl:param name="packageId"/>
      
      <!-- check for download url for simple-delimited text file before parsing attributes -->
      <xsl:if test="physical/distribution/online/url != '' and physical/dataFormat/textFormat/simpleDelimited != ''">
         <xsl:text>%download file </xsl:text><xsl:value-of select="physical/objectName"/><xsl:text> or load from cache if entity is specified&#xD;&#xA;</xsl:text>
         <xsl:text>if isempty(entities) || sum(strcmpi('</xsl:text><xsl:value-of select="entityName"/><xsl:text>',entities)) > 0&#xD;&#xA;</xsl:text>
         <xsl:text>   fn = '</xsl:text><xsl:value-of select="physical/objectName"/><xsl:text>';  %assign filename based on objectName&#xD;&#xA;</xsl:text>
         <xsl:text>   url = '</xsl:text><xsl:value-of select="physical/distribution/online/url"/><xsl:text>';&#xD;&#xA;</xsl:text>
         <xsl:text>   if isempty(fn)&#xD;&#xA;</xsl:text>
         <xsl:text>      fn = '</xsl:text><xsl:value-of select="entityName"/><xsl:text>.txt';  %use entityName if objectName element empty&#xD;&#xA;</xsl:text>
         <xsl:text>   end&#xD;&#xA;</xsl:text>
         <xsl:text>   if cachedata == 0 || exist([pn,filesep,fn],'file') ~= 2&#xD;&#xA;</xsl:text>
         <xsl:text>      [fn,msg] = get_file(url,fn,pn,username,password);&#xD;&#xA;</xsl:text>
         <xsl:text>   end&#xD;&#xA;</xsl:text>   
         <xsl:text>else&#xD;&#xA;</xsl:text>
         <xsl:text>   fn = '';&#xD;&#xA;</xsl:text>
         <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
         <xsl:text>%check for successful file download&#xD;&#xA;</xsl:text>
         <xsl:text>if ~isempty(fn)&#xD;&#xA;&#xD;&#xA;</xsl:text>
         <xsl:call-template name="parse"/>
         <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      </xsl:if>
      
   </xsl:template>
   
   <!-- generate data parsing command and attribute info arrays -->
   <xsl:template name="parse">
      
      <!-- get entity name, entity description and filename -->
      <xsl:text>   %declare entity title and description&#xD;&#xA;</xsl:text>
      <xsl:text>   entityname = '</xsl:text>
      <xsl:call-template name="doubleApostrophe">
         <!-- escape apostrophes -->
         <xsl:with-param name="string" select="entityName"/>
      </xsl:call-template>
      <xsl:text>';&#xD;&#xA;</xsl:text>
      <xsl:text>   filename = '</xsl:text><xsl:value-of select="physical/objectName"/><xsl:text>';&#xD;&#xA;</xsl:text>
      <xsl:text>   entitydesc = '</xsl:text>
      <xsl:call-template name="doubleApostrophe">
         <!-- escape apostrophes -->
         <xsl:with-param name="string" select="normalize-space(entityDescription)"/>
      </xsl:call-template>
      <xsl:text>';&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get physical file characteristics for parsing -->
      <xsl:text>   %declare parameters for textcan function&#xD;&#xA;</xsl:text>
      <xsl:choose>
         <xsl:when test="physical/dataFormat/textFormat/numHeaderLines != ''">
            <xsl:text>   headerlines = </xsl:text><xsl:value-of select="physical/dataFormat/textFormat/numHeaderLines"/><xsl:text>;&#xD;&#xA;</xsl:text>                     
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>   headerlines = 0;&#xD;&#xA;</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:text>   terminator = '</xsl:text><xsl:value-of select="physical/dataFormat/textFormat/recordDelimiter"/><xsl:text>';&#xD;&#xA;</xsl:text>
      <xsl:text>   terminator = strrep(strrep(terminator,'#x0A','\n'),'#x0D','\r'); %convert entity references to conventional symbols&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   delimiter = '</xsl:text><xsl:value-of select="physical/dataFormat/textFormat/simpleDelimited/fieldDelimiter"/><xsl:text>';&#xD;&#xA;</xsl:text>
      <xsl:text>   delimiter = strrep(delimiter,'#x20',' ');  %convert space entity reference to space literal&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   collapse_delim = '</xsl:text><xsl:value-of select="physical/dataFormat/textFormat/simpleDelimited/collapseDelimiters"/><xsl:text>';&#xD;&#xA;</xsl:text>
      <xsl:text>   if strcmpi('yes',collapse_delim) == 1&#xD;&#xA;</xsl:text>
      <xsl:text>      collapse = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>   else&#xD;&#xA;</xsl:text>
      <xsl:text>      collapse = 0;&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- generate formatted input string -->
      <xsl:text>   %declare format string for textscan function&#xD;&#xA;</xsl:text>   
      <xsl:text>   fstr = '</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:choose>
            <xsl:when test="storageType != ''">
               <xsl:choose>
                  <xsl:when test="storageType = 'integer' or storageType = 'int' or storageType = 'long' or storageType = 'short'">
                     <!-- integer variant -->
                     <xsl:text>%d</xsl:text>
                  </xsl:when>
                  <xsl:when test="storageType = 'float' or storageType = 'double' or storageType = 'decimal' or substring(storageType,1,7) = 'numeric'">
                     <!-- floating-point variant -->
                     <xsl:text>%f</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                     <!-- default to string (possibly double quoted) for any other type -->
                     <xsl:text>%q</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
               <!-- no storageType - infer type from measurementScale -->
               <xsl:choose>
                  <xsl:when test="measurementScale/ratio != '' or measurementScale/interval != ''">
                     <xsl:text>%f</xsl:text>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:text>%q</xsl:text>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
      <xsl:text>';&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- generate string and numeric missing value code lists -->
      <xsl:text>   %declare arrays of distinct string and numeric missing value codes&#xD;&#xA;</xsl:text>
      <xsl:text>   missingvals = {''</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:if test="missingValueCode != ''">
            <xsl:text>,'</xsl:text><xsl:value-of select="missingValueCode/code"/><xsl:text>'</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>};&#xD;&#xA;</xsl:text>      
      <xsl:text>   missingvals = strrep(missingvals,'NaN','');  %convert NaN to empty (native missing value code)&#xD;&#xA;</xsl:text>
      <xsl:text>   missingvals = missingvals(~cellfun('isempty',missingvals));  %remove empty cells&#xD;&#xA;</xsl:text>
      <xsl:text>   Inumeric = ~isnan(str2double(missingvals)); %get index of numeric missing value codes&#xD;&#xA;</xsl:text>
      <xsl:text>   missingvals_num = unique(str2double(missingvals(Inumeric))); %convert numeric missing value codes to double array&#xD;&#xA;</xsl:text>
      <xsl:text>   Istring = ~Inumeric;  %get index of string missing value codes&#xD;&#xA;</xsl:text>
      <xsl:text>   missingvals = unique(missingvals(Istring));  %generate string missing value codes for textscan function&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- generate attribute name array -->
      <xsl:text>   %declare array of attribute names&#xD;&#xA;</xsl:text>
      <xsl:text>   att_names = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:text>      '</xsl:text>
         <xsl:call-template name="doubleApostrophe">
            <!-- escape apostrophes -->
            <xsl:with-param name="string" select="normalize-space(attributeName)"/>
         </xsl:call-template>
         <xsl:text>'</xsl:text>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   };&#xD;&#xA;&#xD;&#xA;</xsl:text>      
      
      <!-- generate attribute descriptions array -->
      <xsl:text>   %declare array of attribute descriptions&#xD;&#xA;</xsl:text>
      <xsl:text>   att_desc = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:text>      '</xsl:text>
         <xsl:call-template name="doubleApostrophe">
            <!-- escape apostrophes -->
            <xsl:with-param name="string" select="normalize-space(attributeDefinition)"/>
         </xsl:call-template>
         <xsl:text>'</xsl:text>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   };&#xD;&#xA;&#xD;&#xA;</xsl:text>      

      <!-- generate attribute type array -->
      <xsl:text>   %declare array of attribute types&#xD;&#xA;</xsl:text>
      <xsl:text>   att_types = lower({ ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:text>      '</xsl:text>
         <xsl:call-template name="doubleApostrophe">
            <!-- escape apostrophes -->
            <xsl:with-param name="string" select="normalize-space(storageType)"/>
         </xsl:call-template>
         <xsl:text>'</xsl:text>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   });&#xD;&#xA;&#xD;&#xA;</xsl:text>      

      <!-- generate attribute units array -->
      <xsl:text>   %declare array of attribute units&#xD;&#xA;</xsl:text>
      <xsl:text>   att_units = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:choose>
            <xsl:when test="measurementScale//standardUnit != ''">
               <xsl:text>      '</xsl:text>
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(measurementScale//standardUnit)"/>
               </xsl:call-template>
               <xsl:text>'</xsl:text>               
            </xsl:when>
            <xsl:when test="measurementScale//customUnit != ''">
               <xsl:text>      '</xsl:text>
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(measurementScale//customUnit)"/>
               </xsl:call-template>
               <xsl:text>'</xsl:text>               
            </xsl:when>
            <xsl:when test="measurementScale//formatString != ''">
               <xsl:text>      '</xsl:text>
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(measurementScale//formatString)"/>
               </xsl:call-template>
               <xsl:text>'</xsl:text>               
            </xsl:when>
            <xsl:otherwise>
               <!-- no unit -->
               <xsl:text>      ''</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   };&#xD;&#xA;&#xD;&#xA;</xsl:text>      
      
      <!-- generate measurement scale array -->
      <xsl:text>   %declare array of measurement scales&#xD;&#xA;</xsl:text>
      <xsl:text>   att_scales = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:choose>
            <xsl:when test="measurementScale/nominal != ''">
               <xsl:text>      'nominal'</xsl:text>               
            </xsl:when>
            <xsl:when test="measurementScale/ordinal != ''">
               <xsl:text>      'ordinal'</xsl:text>               
            </xsl:when>
            <xsl:when test="measurementScale/ratio != ''">
               <xsl:text>      'ratio'</xsl:text>               
            </xsl:when>
            <xsl:when test="measurementScale/interval != ''">
               <xsl:text>      'interval'</xsl:text>               
            </xsl:when>
            <xsl:when test="measurementScale/dateTime != ''">
               <xsl:text>      'datetime'</xsl:text> 
            </xsl:when>
            <xsl:otherwise>
               <!-- no scale -->
               <xsl:text>      ''</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   };&#xD;&#xA;&#xD;&#xA;</xsl:text>      
      
      <!-- generate code definition array -->
      <xsl:text>   %declare array of code definitions&#xD;&#xA;</xsl:text>
      <xsl:text>   att_codes = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:choose>
            <xsl:when test="measurementScale//codeDefinition != ''">
               <xsl:text>      '</xsl:text>
               <xsl:for-each select="measurementScale//codeDefinition">
                  <xsl:call-template name="doubleApostrophe">
                     <!-- escape apostrophes -->
                     <xsl:with-param name="string" select="normalize-space(code)"/>
                  </xsl:call-template>
                  <xsl:text> = </xsl:text>
                  <xsl:call-template name="doubleApostrophe">
                     <!-- escape apostrophes -->
                     <xsl:with-param name="string" select="normalize-space(definition)"/>
                  </xsl:call-template>
                  <xsl:if test="position()!=last()">
                     <xsl:text>, </xsl:text>
                  </xsl:if>                  
               </xsl:for-each>
               <xsl:text>'</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <!-- no codes -->
               <xsl:text>      ''</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   };&#xD;&#xA;&#xD;&#xA;</xsl:text>      
      
      <!-- generate value bounds array -->
      <xsl:text>   %declare array of value bounds&#xD;&#xA;</xsl:text>
      <xsl:text>   att_bounds = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="attributeList/attribute">
         <xsl:choose>
            <xsl:when test="measurementScale//bounds != ''">
               <xsl:text>      '</xsl:text>
               <xsl:for-each select="measurementScale//bounds/minimum">
                  <xsl:choose>
                     <xsl:when test="./@exclusive='true'">
                        <xsl:text>value &gt; </xsl:text><xsl:value-of select="."/><xsl:text>; </xsl:text>
                     </xsl:when>
                     <xsl:when test="./@exclusive='false'">
                        <xsl:text>value &gt;= </xsl:text><xsl:value-of select="."/><xsl:text>; </xsl:text>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:text>value &gt; </xsl:text><xsl:value-of select="."/><xsl:text>; </xsl:text>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
               <xsl:for-each select="measurementScale//bounds/maximum">
                  <xsl:choose>
                     <xsl:when test="./@exclusive='true'">
                        <xsl:text>value &lt; </xsl:text><xsl:value-of select="."/><xsl:text>; </xsl:text>
                     </xsl:when>
                     <xsl:when test="./@exclusive='false'">
                        <xsl:text>value &lt;= </xsl:text><xsl:value-of select="."/><xsl:text>; </xsl:text>
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:text>value &lt; </xsl:text><xsl:value-of select="."/><xsl:text>; </xsl:text>
                     </xsl:otherwise>
                  </xsl:choose>
               </xsl:for-each>
               <xsl:text>'</xsl:text>
            </xsl:when>
            <xsl:otherwise>
               <!-- no bounds -->
               <xsl:text>      ''</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:if test="position()!=last()">
            <xsl:text>, ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text> ...&#xD;&#xA;   };&#xD;&#xA;&#xD;&#xA;</xsl:text>      
      
      <!-- init structure fields or calculate next dimension to add -->
      <xsl:text>   %initialize structure dimension for first data table&#xD;&#xA;</xsl:text>
      <xsl:text>   if isempty(s)&#xD;&#xA;</xsl:text>
      <xsl:text>      dim = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>      s = struct('packageid','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'project','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'title','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'abstract','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'keywords','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'creator','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'contact','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'rights','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'dates','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'geography','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'taxa','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'methods','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'sampling','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'entity','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'url','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'filename','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'description','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'names','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'units','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'definitions','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'datatypes','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'scales','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'codes','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'bounds','', ...&#xD;&#xA;</xsl:text>
      <xsl:text>         'data','');&#xD;&#xA;</xsl:text>
      <xsl:text>   else&#xD;&#xA;</xsl:text>
      <xsl:text>      dim = length(s) + 1;&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- populate structure with parsed info -->
      <xsl:text>   %populate structure fields for current data table&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).entity = entityname;&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).url = url;&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).filename = filename;&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).description = entitydesc;&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).names = att_names';&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).units = att_units';&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).definitions = att_desc';&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).datatypes = att_types';&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).scales = att_scales';&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).codes = att_codes';&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).bounds = att_bounds';&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- try to parse downloaded file and add to structure -->
      <xsl:text>   %parse downloaded file&#xD;&#xA;</xsl:text>
      <xsl:text>   err = [];  %initialize error object&#xD;&#xA;</xsl:text>
      <xsl:text>   try&#xD;&#xA;</xsl:text>
      <xsl:text>      fid = fopen(fn,'r');  %open file for read&#xD;&#xA;</xsl:text>
      <xsl:text>      if ~isempty(missingvals) &amp;&amp; ~isempty(delimiter) &amp;&amp; ~isempty(terminator)&#xD;&#xA;</xsl:text>
      <xsl:text>         %run textscan with missing value codes&#xD;&#xA;</xsl:text>
      <xsl:text>         ar = textscan(fid,fstr,'Delimiter',delimiter,'EndOfLine',terminator,'Headerlines',headerlines, ...&#xD;&#xA;</xsl:text>
      <xsl:text>            'TreatAsEmpty',missingvals,'MultipleDelimsAsOne',collapse,'ReturnOnError',0);&#xD;&#xA;</xsl:text>
      <xsl:text>      elseif ~isempty(delimiter) &amp;&amp; ~isempty(terminator)&#xD;&#xA;</xsl:text>
      <xsl:text>         %run textscan without missing value codes&#xD;&#xA;</xsl:text>
      <xsl:text>         ar = textscan(fid,fstr,'Delimiter',delimiter,'EndOfLine',terminator,'Headerlines',headerlines, ...&#xD;&#xA;</xsl:text>
      <xsl:text>            'MultipleDelimsAsOne',collapse,'ReturnOnError',0);&#xD;&#xA;</xsl:text>
      <xsl:text>      elseif ~isempty(delimiter)&#xD;&#xA;</xsl:text>
      <xsl:text>         %run textscan without missing value codes or explicit line terminator&#xD;&#xA;</xsl:text>
      <xsl:text>         ar = textscan(fid,fstr,'Delimiter',delimiter,'Headerlines',headerlines,'MultipleDelimsAsOne',collapse,'ReturnOnError',0);&#xD;&#xA;</xsl:text>
      <xsl:text>      else&#xD;&#xA;</xsl:text>
      <xsl:text>         %run textscan without missing value codes or explicit terminator or delimiters&#xD;&#xA;</xsl:text>
      <xsl:text>         ar = textscan(fid,fstr,'Headerlines',headerlines,'ReturnOnError',0);&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>      fclose(fid);  %close file handle&#xD;&#xA;</xsl:text>
      <xsl:text>   catch err&#xD;&#xA;</xsl:text>
      <xsl:text>      ar = [];  %return empty array on error&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;</xsl:text>
      <xsl:text>   if ~isempty(err)&#xD;&#xA;</xsl:text>
      <xsl:text>      msg = err.message;&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %extract data arrays from single cell, add to output structure&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- convert numeric values matching numeric missing values codes to NaN (note: textscan only supports string missing value codes) -->
      <xsl:text>   %convert numeric values matching numeric missing values codes to NaN&#xD;&#xA;</xsl:text>
      <xsl:text>   if ~isempty(ar) &amp;&amp; ~isempty(missingvals_num)&#xD;&#xA;</xsl:text>
      <xsl:text>      for col = 1:length(ar)&#xD;&#xA;</xsl:text>
      <xsl:text>         vals = ar{col};&#xD;&#xA;</xsl:text>
      <xsl:text>         if isnumeric(vals)&#xD;&#xA;</xsl:text>
      <xsl:text>            Inull = zeros(length(vals),1);  %init index of missing values&#xD;&#xA;</xsl:text>
      <xsl:text>            for missval = 1:length(missingvals_num)&#xD;&#xA;</xsl:text>
      <xsl:text>               Inull(vals == missingvals_num(missval)) = 1;  %update index for any values matching a missing value code&#xD;&#xA;</xsl:text>
      <xsl:text>            end&#xD;&#xA;</xsl:text>
      <xsl:text>            Inull = find(Inull);&#xD;&#xA;</xsl:text>
      <xsl:text>            if ~isempty(Inull)&#xD;&#xA;</xsl:text>
      <xsl:text>               vals(Inull) = NaN;&#xD;&#xA;</xsl:text>
      <xsl:text>               ar{col} = vals;&#xD;&#xA;</xsl:text>
      <xsl:text>            end&#xD;&#xA;</xsl:text>
      <xsl:text>         end&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- add arrays to structure -->
      <xsl:text>   %add data arrays to structure field&#xD;&#xA;</xsl:text>
      <xsl:text>   s(dim).data = ar(:);&#xD;&#xA;&#xD;&#xA;</xsl:text>

   </xsl:template>
   
   <!-- generate general metadata array -->
   <xsl:template name="metadata">    
      
      <!-- start metadata section -->
      <xsl:text>%check for successful file download and parsing&#xD;&#xA;</xsl:text>
      <xsl:text>if ~isempty(s)&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get basic metadata -->
      <xsl:text>   %set basic metadata contents from document&#xD;&#xA;</xsl:text>      
      <xsl:text>   packageid = '</xsl:text><xsl:value-of select="/*/@packageId"/><xsl:text>';&#xD;&#xA;</xsl:text>

      <xsl:text>   titlestr = '</xsl:text>
      <xsl:call-template name="doubleApostrophe">
         <!-- escape apostrophes -->
         <xsl:with-param name="string" select="normalize-space(/*/dataset/title)"/>
      </xsl:call-template>
      <xsl:text>';&#xD;&#xA;</xsl:text>

      <xsl:text>   abstract = '</xsl:text>
      <xsl:call-template name="doubleApostrophe">
         <!-- escape apostrophes -->
         <xsl:with-param name="string" select="normalize-space(/*/dataset/abstract)"/>
      </xsl:call-template>
      <xsl:text>';&#xD;&#xA;&#xD;&#xA;</xsl:text>

      <!-- get project title and funding -->
      <xsl:text>   %set project title and funding&#xD;&#xA;</xsl:text>
      <xsl:text>   project = '</xsl:text>
      <xsl:call-template name="doubleApostrophe">
         <!-- escape apostrophes -->
         <xsl:with-param name="string" select="normalize-space(/*/dataset/project/title)"/>
      </xsl:call-template>
      <xsl:if test="/*/dataset/project/funding != ''">
         <xsl:text> (funding: </xsl:text>
         <xsl:call-template name="doubleApostrophe">
            <!-- escape apostrophes -->
            <xsl:with-param name="string" select="normalize-space(/*/dataset/project/funding)"/>
         </xsl:call-template>
         <xsl:text>)</xsl:text>         
      </xsl:if>
      <xsl:text>';&#xD;&#xA;</xsl:text>
      
      <!-- get creator info for individuals and positions -->
      <xsl:text>   %build cell array of creator contact information with labeled fields&#xD;&#xA;</xsl:text>
      <xsl:text>   creators = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset/creator">
         <xsl:if test="individualName != '' or positionName != ''">
            <xsl:call-template name="party"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>

      <!-- get contact info for individuals and positions -->
      <xsl:text>   %build cell array of dataset contact information with labeled fields&#xD;&#xA;</xsl:text>
      <xsl:text>   contacts = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset/contact">
         <xsl:if test="individualName != '' or positionName != ''">
            <xsl:call-template name="party"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get usage rights -->
      <xsl:text>   %build character array of dataset usage rights&#xD;&#xA;</xsl:text>
      <xsl:text>   rights = { ...&#xD;&#xA;</xsl:text>
      <xsl:choose>
         <xsl:when test="/*/dataset/intellectualRights != ''">
            <xsl:for-each select="/*/dataset/intellectualRights">
               <xsl:call-template name="rights"/>               
            </xsl:for-each> 
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>''</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:text>      };&#xD;&#xA;</xsl:text>
      
      <!-- get keywords -->
      <xsl:text>   %build character array of keywords&#xD;&#xA;</xsl:text>
      <xsl:text>   keywords = '</xsl:text>
      <xsl:for-each select="/*/dataset/keywordSet/keyword">
         <xsl:value-of select="."/>
         <xsl:if test="position() != last()">
            <xsl:text>, </xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>';&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get temporal coverage info -->
      <xsl:text>   %build cell array of study dates&#xD;&#xA;</xsl:text>
      <xsl:text>   dates = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset/coverage/temporalCoverage">
         <xsl:if test="rangeOfDates != ''">
            <xsl:call-template name="dates"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get geographic coverage info -->
      <xsl:text>   %build cell array of geographic names and bounding box coordinates (NW, NE, SE, SW)&#xD;&#xA;</xsl:text>
      <xsl:text>   geography = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset//coverage/geographicCoverage">
         <xsl:if test="boundingCoordinates != ''">
            <xsl:call-template name="geography"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get taxonomic coverage info -->
      <xsl:text>   %build cell array of taxa&#xD;&#xA;</xsl:text>
      <xsl:text>   taxa = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset/coverage/taxonomicCoverage">
         <xsl:if test="taxonomicClassification != ''">
            <xsl:call-template name="taxa"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get methods -->
      <xsl:text>   %build cell array of methods and instruments&#xD;&#xA;</xsl:text>
      <xsl:text>   methods = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset/methods">
         <xsl:if test="methodStep/description != ''">
            <xsl:call-template name="methods"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- get sampling description -->
      <xsl:text>   %build cell array of sampling description information&#xD;&#xA;</xsl:text>
      <xsl:text>   sampling = { ...&#xD;&#xA;</xsl:text>
      <xsl:for-each select="/*/dataset/methods/sampling">
         <xsl:if test="samplingDescription != ''">
            <xsl:call-template name="sampling"/>
         </xsl:if>
      </xsl:for-each>
      <xsl:text>      };&#xD;&#xA;&#xD;&#xA;</xsl:text>
      
      <!-- add parsed metadata to output structure -->
      <xsl:text>    %add document-level metadata to all structure dimensions&#xD;&#xA;</xsl:text>
      <xsl:text>    for cnt = 1:length(s)&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).project = project;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).packageid = packageid;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).title = titlestr;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).abstract = abstract;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).keywords = keywords;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).creator = creators;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).contact = contacts;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).rights = rights;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).dates = dates;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).geography = geography;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).taxa = taxa;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).methods = methods;&#xD;&#xA;</xsl:text>
      <xsl:text>       s(cnt).sampling = sampling;&#xD;&#xA;</xsl:text>
      <xsl:text>    end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>else&#xD;&#xA;</xsl:text>
      <xsl:text>   msg = 'no compatible data tables were successfully downloaded';&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>return&#xD;&#xA;&#xD;&#xA;&#xD;&#xA;</xsl:text>
   </xsl:template>     
   
   <!-- template for adding 'get_file' subfunction for retrieving entities from disk or url -->
   <xsl:template name="get_file">
      
      <xsl:text>%----------------------------------------------------------------&#xD;&#xA;</xsl:text>
      <xsl:text>%subfunction to download or copy a file to a local directory path&#xD;&#xA;</xsl:text>
      <xsl:text>%----------------------------------------------------------------&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>function [fqfn,msg] = get_file(url,fn,pn,username,password)&#xD;&#xA;</xsl:text>
      <xsl:text>%Fetches a file from an HTTP, HTTPS, FTP or file system URL&#xD;&#xA;</xsl:text>
      <xsl:text>%and returns a fully qualified local filename for loading or transformation&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%syntax: [fqfn,msg] = get_file(url,fn,pn,username,password)&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%input:&#xD;&#xA;</xsl:text>
      <xsl:text>%   url = http, https, ftp or file system address of the file&#xD;&#xA;</xsl:text>
      <xsl:text>%   fn = filename for downloaded file&#xD;&#xA;</xsl:text>
      <xsl:text>%   pn = pathname for downloading or copying file&#xD;&#xA;</xsl:text>
      <xsl:text>%   username = username for HTTPS authentication (default = '')&#xD;&#xA;</xsl:text>
      <xsl:text>%   password = password for HTTPS authentication (default = '')&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%output:&#xD;&#xA;</xsl:text>
      <xsl:text>%   fqfn = fully-qualified local filename&#xD;&#xA;</xsl:text>
      <xsl:text>%   msg = text of any error message&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%notes:&#xD;&#xA;</xsl:text>
      <xsl:text>%   2) HTTPS downloads depend on access to cURL with SSL libraries in the system path (see http://curl.haxx.se/)&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%contact:&#xD;&#xA;</xsl:text>
      <xsl:text>%  Wade Sheldon&#xD;&#xA;</xsl:text>
      <xsl:text>%  GCE-LTER Project&#xD;&#xA;</xsl:text>
      <xsl:text>%  Department of Marine Sciences&#xD;&#xA;</xsl:text>
      <xsl:text>%  University of Georgia&#xD;&#xA;</xsl:text>
      <xsl:text>%  Athens, GA 30602-3636&#xD;&#xA;</xsl:text>
      <xsl:text>%  sheldon@uga.edu&#xD;&#xA;</xsl:text>
      <xsl:text>%&#xD;&#xA;</xsl:text>
      <xsl:text>%last modified: 18-Jun-2013&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%init output&#xD;&#xA;</xsl:text>
      <xsl:text>fqfn = '';&#xD;&#xA;</xsl:text>
      <xsl:text>msg = '';&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>%check for nonempty string url&#xD;&#xA;</xsl:text>
      <xsl:text>if nargin >= 2 &amp;&amp; ischar(url) &amp;&amp; ~isempty(url) &amp;&amp; ~isempty(fn)&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %validate path&#xD;&#xA;</xsl:text>
      <xsl:text>   if exist('pn','var') ~= 1;&#xD;&#xA;</xsl:text>
      <xsl:text>      pn = pwd;  %default to working directory if path omitted&#xD;&#xA;</xsl:text>
      <xsl:text>   elseif ~isdir(pn)&#xD;&#xA;</xsl:text>
      <xsl:text>      pn = pwd;  %default to working directory if path invalid&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %check for omitted username argument, set default to '' for none&#xD;&#xA;</xsl:text>
      <xsl:text>   if exist('username','var') ~= 1&#xD;&#xA;</xsl:text>
      <xsl:text>      username = '';&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %check for omitted password argument, set default to '' for none&#xD;&#xA;</xsl:text>
      <xsl:text>   if exist('password','var') ~= 1&#xD;&#xA;</xsl:text>
      <xsl:text>      password = '';&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %init error flag&#xD;&#xA;</xsl:text>
      <xsl:text>   err = 0;&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %download file using appropriate command based on protocol&#xD;&#xA;</xsl:text>
      <xsl:text>   if strncmpi(url,'https',5)&#xD;&#xA;</xsl:text>
      <xsl:text>      %try urlwrite for https first&#xD;&#xA;</xsl:text>
      <xsl:text>      try&#xD;&#xA;</xsl:text>
      <xsl:text>         urlwrite(url,[pn,filesep,fn]);&#xD;&#xA;</xsl:text>
      <xsl:text>      catch errmsg&#xD;&#xA;</xsl:text>
      <xsl:text>         err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>      %try cUrl if urlwrite fails&#xD;&#xA;</xsl:text>
      <xsl:text>      if err == 1&#xD;&#xA;</xsl:text>
      <xsl:text>         err = 0;&#xD;&#xA;</xsl:text>
      <xsl:text>         %generate curl command to evaluate&#xD;&#xA;</xsl:text>
      <xsl:text>         if isempty(username)&#xD;&#xA;</xsl:text>
      <xsl:text>            cmd = ['curl -s -X GET "',url,'" -o "',pn,filesep,fn,'"'];&#xD;&#xA;</xsl:text>
      <xsl:text>            cmd_insecure = ['curl -k -s -X GET "',url,'" -o "',pn,filesep,fn,'"'];&#xD;&#xA;</xsl:text>
      <xsl:text>         else&#xD;&#xA;</xsl:text>
      <xsl:text>            cmd = ['curl -s -u ',username,':',password,' -X GET "',url,'" -o "',pn,filesep,fn,'"'];&#xD;&#xA;</xsl:text>
      <xsl:text>            cmd_insecure = ['curl -k -s -u ',username,':',password,' -X GET "',url,'" -o "',pn,filesep,fn,'"'];&#xD;&#xA;</xsl:text>
      <xsl:text>         end&#xD;&#xA;</xsl:text>
      <xsl:text>         %run curl command, checking for system or cURL errors&#xD;&#xA;</xsl:text>
      <xsl:text>         try&#xD;&#xA;</xsl:text>
      <xsl:text>            [status,res] = system(cmd);&#xD;&#xA;</xsl:text>
      <xsl:text>         catch errmsg&#xD;&#xA;</xsl:text>
      <xsl:text>            err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>         end&#xD;&#xA;</xsl:text>
      <xsl:text>         if err == 1 || status > 0&#xD;&#xA;</xsl:text>
      <xsl:text>            try&#xD;&#xA;</xsl:text>
      <xsl:text>               %fall back to insecure SSL on certificate error&#xD;&#xA;</xsl:text>
      <xsl:text>               [status,res] = system(cmd_insecure);&#xD;&#xA;</xsl:text>
      <xsl:text>               if status > 0&#xD;&#xA;</xsl:text>
      <xsl:text>                  err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>               end&#xD;&#xA;</xsl:text>
      <xsl:text>            catch errmsg&#xD;&#xA;</xsl:text>
      <xsl:text>               err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>            end&#xD;&#xA;</xsl:text>
      <xsl:text>         end&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>   elseif strncmpi(url,'http',4)&#xD;&#xA;</xsl:text>
      <xsl:text>      %use urlwrite for http&#xD;&#xA;</xsl:text>
      <xsl:text>      try&#xD;&#xA;</xsl:text>
      <xsl:text>         urlwrite(url,[pn,filesep,fn]);&#xD;&#xA;</xsl:text>
      <xsl:text>      catch errmsg&#xD;&#xA;</xsl:text>
      <xsl:text>         err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>   elseif strncmpi(url,'ftp',3)&#xD;&#xA;</xsl:text>
      <xsl:text>      %use urlwrite for ftp&#xD;&#xA;</xsl:text>
      <xsl:text>      try&#xD;&#xA;</xsl:text>
      <xsl:text>         urlwrite(url,[pn,filesep,fn]);&#xD;&#xA;</xsl:text>
      <xsl:text>      catch errmsg&#xD;&#xA;</xsl:text>
      <xsl:text>         err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>   elseif exist(url,'file') == 2&#xD;&#xA;</xsl:text>
      <xsl:text>      %copy file from local system or UNC path to specified directory&#xD;&#xA;</xsl:text>
      <xsl:text>      try&#xD;&#xA;</xsl:text>
      <xsl:text>         copyfile(url,[pn,filesep,fn]);&#xD;&#xA;</xsl:text>
      <xsl:text>      catch errmsg&#xD;&#xA;</xsl:text>
      <xsl:text>         err = 1;&#xD;&#xA;</xsl:text>
      <xsl:text>      end&#xD;&#xA;</xsl:text>
      <xsl:text>   else&#xD;&#xA;</xsl:text>
      <xsl:text>      err = 1; %unsupported option or invalid file url&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>   %check for errors&#xD;&#xA;</xsl:text>
      <xsl:text>   if err == 0 &amp;&amp; exist([pn,filesep,fn],'file') == 2&#xD;&#xA;</xsl:text>
      <xsl:text>      fqfn = [pn,filesep,fn];&#xD;&#xA;</xsl:text>
      <xsl:text>   else&#xD;&#xA;</xsl:text>
      <xsl:text>      msg = ['failed to retrieve the file from the specified url (',errmsg.message,')'];&#xD;&#xA;</xsl:text>
      <xsl:text>   end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>end&#xD;&#xA;&#xD;&#xA;</xsl:text>
      <xsl:text>return&#xD;&#xA;</xsl:text>
      
   </xsl:template>

   <!-- template for formatting individual names -->
   <xsl:template name="party">
      <xsl:if test="individualName != '' or positionName != ''">
         <xsl:choose>
            <xsl:when test="individualName != ''">
               <xsl:text>         'Name: </xsl:text>
               <xsl:if test="individualName/salutation != ''"><xsl:value-of select="individualName/salutation"/><xsl:text> </xsl:text></xsl:if>
               <xsl:if test="individualName/givenName != ''"><xsl:value-of select="individualName/givenName"/><xsl:text> </xsl:text></xsl:if>
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(individualName/surName)"/>
               </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>         'Position: </xsl:text>     
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(positionName)"/>
               </xsl:call-template>
            </xsl:otherwise>
         </xsl:choose>
         <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         <xsl:if test="address != ''">
            <xsl:text>         '   Address: </xsl:text>
            <xsl:for-each select="address/deliveryPoint">
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="."/>
               </xsl:call-template>
               <xsl:text>, </xsl:text>
            </xsl:for-each>
            <xsl:if test="address/city != ''">
                <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="address/city"/>
               </xsl:call-template>
               <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:if test="address/administrativeArea != ''">
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="address/administrativeArea"/>
               </xsl:call-template>
               <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:if test="address/postalCode != ''">
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="address/postalCode"/>
               </xsl:call-template>
               <xsl:text>, </xsl:text>
            </xsl:if>
            <xsl:if test="address/country != ''">
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="address/country"/>
               </xsl:call-template>
            </xsl:if>
            <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         </xsl:if>
         <xsl:if test="electronicMailAddress != ''">
            <xsl:text>         '   Email: </xsl:text>
            <xsl:value-of select="electronicMailAddress"/>
            <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         </xsl:if>
         <xsl:if test="organizationName != ''">
            <xsl:text>         '   Organization: </xsl:text>
            <xsl:call-template name="doubleApostrophe">
               <!-- escape apostrophes -->
               <xsl:with-param name="string" select="organizationName"/>
            </xsl:call-template>
            <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         </xsl:if>
         <xsl:if test="onlineUrl != ''">
            <xsl:text>         '   Website: </xsl:text>
            <xsl:value-of select="onlineUrl"/>
            <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         </xsl:if>
      </xsl:if>
   </xsl:template>
   
   <!-- template for formatting intellectual rights text -->
   <xsl:template name="rights">
      <xsl:for-each select="para">
         <xsl:choose>
            <xsl:when test="itemizedlist != '' or orderedlist != ''">
               <xsl:for-each select="*//para">
                  <xsl:text>         '   * </xsl:text>
                  <xsl:call-template name="doubleApostrophe">
                     <!-- escape apostrophes -->
                     <xsl:with-param name="string" select="normalize-space(.)"/>
                  </xsl:call-template>
                  <xsl:text>'; ...&#xD;&#xA;</xsl:text>
               </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
               <xsl:text>         '</xsl:text>
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(.)"/>
               </xsl:call-template>
               <xsl:text>'; ...&#xD;&#xA;</xsl:text>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:for-each>
   </xsl:template>
   
   <!-- template for formatting study dates -->
   <xsl:template name="dates">
      <xsl:for-each select="rangeOfDates">
         <xsl:text>         'BeginDate: </xsl:text><xsl:value-of select="beginDate/calendarDate"/><xsl:text>'; ...&#xD;&#xA;</xsl:text>
         <xsl:text>         'EndDate: </xsl:text><xsl:value-of select="endDate/calendarDate"/><xsl:text>'; ...&#xD;&#xA;</xsl:text>
      </xsl:for-each>
   </xsl:template>
   
   <!-- template for building numeric array of bounding box coordinates (NW, NE, SE, SW) -->
   <xsl:template name="geography">
      
      <!-- add geographic description and opening numeric array bracket -->
      <xsl:text>         '</xsl:text>
      <xsl:call-template name="doubleApostrophe">
         <!-- escape apostrophes -->
         <xsl:with-param name="string" select="normalize-space(geographicDescription)"/>
      </xsl:call-template>
      <xsl:text>',[</xsl:text>
      
      <!-- add bounding lon/lat pairs as numeric array -->
      <xsl:for-each select="boundingCoordinates">
         <xsl:value-of select="westBoundingCoordinate"/><xsl:text>,</xsl:text><xsl:value-of select="northBoundingCoordinate"/><xsl:text>;</xsl:text>
         <xsl:value-of select="eastBoundingCoordinate"/><xsl:text>,</xsl:text><xsl:value-of select="northBoundingCoordinate"/><xsl:text>;</xsl:text>
         <xsl:value-of select="eastBoundingCoordinate"/><xsl:text>,</xsl:text><xsl:value-of select="southBoundingCoordinate"/><xsl:text>;</xsl:text>
         <xsl:value-of select="westBoundingCoordinate"/><xsl:text>,</xsl:text><xsl:value-of select="southBoundingCoordinate"/>
      </xsl:for-each>
      
      <!-- close numeric array and add line continuation character -->
      <xsl:text>]; ...&#xD;&#xA;</xsl:text>     
      
   </xsl:template>
   
   <!-- template for building cell array of species and common names -->
   <xsl:template name="taxa">
      <!-- loop through taxonomicClassification elements with taxonRankName = Genus -->
      <xsl:for-each select=".//taxonomicClassification[taxonRankName='Genus']">
         <xsl:text>         '</xsl:text>
         <xsl:choose>
            <!-- check for corresponding species binomial based on space character in normalized species name -->
            <xsl:when test="contains(normalize-space(taxonomicClassification[taxonRankName='Species']/taxonRankValue),' ')">
               <xsl:value-of select="taxonomicClassification[taxonRankName='Species']/taxonRankValue"/>
            </xsl:when>
            <xsl:otherwise>
               <!-- combine genus and species names to form species binomial -->
               <xsl:value-of select="taxonRankValue"/>
               <xsl:text> </xsl:text>
               <xsl:value-of select="taxonomicClassification[taxonRankName='Species']/taxonRankValue"/>
            </xsl:otherwise>
         </xsl:choose>
         <!-- check for common name and add in parentheses after species binomial -->
         <xsl:if test="taxonomicClassification[taxonRankName='Species']/commonName != ''">
            <xsl:text> (</xsl:text>
            <xsl:call-template name="doubleApostrophe">
               <!-- escape apostrophes -->
               <xsl:with-param name="string" select="taxonomicClassification[taxonRankName='Species']/commonName"/>
            </xsl:call-template>
            <xsl:text>)</xsl:text>
         </xsl:if>
         <xsl:text>'; ...&#xD;&#xA;</xsl:text>
      </xsl:for-each>
   </xsl:template>

   <!-- template for building cell array of methods and instruments -->
   <xsl:template name="methods">
      <xsl:for-each select="methodStep">
         <xsl:if test="description/section != ''">
            <xsl:text>         'method: </xsl:text>
            <xsl:if test="description/section/title != ''">
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(description/section/title)"/>
               </xsl:call-template>
               <xsl:text> -- </xsl:text>
            </xsl:if>
            <xsl:for-each select="description/section/para">
               <xsl:call-template name="para"/>
               <xsl:text> </xsl:text>
            </xsl:for-each>
            <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         </xsl:if>
         <xsl:if test="description/para != ''">
            <xsl:text>         'method: </xsl:text>
            <xsl:for-each select="description/para">
               <xsl:call-template name="para"/>
               <xsl:text> </xsl:text>
            </xsl:for-each>
            <xsl:text>'; ...&#xD;&#xA;</xsl:text>
         </xsl:if>
         <xsl:for-each select="instrumentation">
            <xsl:text>         '   instrument: </xsl:text>
            <xsl:call-template name="doubleApostrophe">
               <!-- escape apostrophes -->
               <xsl:with-param name="string" select="normalize-space(.)"/>
            </xsl:call-template>
            <xsl:text>)'; ...&#xD;&#xA;</xsl:text>            
         </xsl:for-each>
      </xsl:for-each>
   </xsl:template>
   
   <!-- template for building cell array of sampling descriptions -->
   <xsl:template name="sampling">
      <xsl:for-each select="samplingDescription">
         <xsl:if test="section != ''">
            <xsl:if test="section/title != ''">
               <xsl:text>         '</xsl:text>
               <xsl:call-template name="doubleApostrophe">
                  <!-- escape apostrophes -->
                  <xsl:with-param name="string" select="normalize-space(section/title)"/>
               </xsl:call-template>
               <xsl:text> -- '; ...&#xD;&#xA;</xsl:text>
            </xsl:if>
            <xsl:for-each select="section/para">
               <xsl:text>         '</xsl:text>
               <xsl:call-template name="para"/>
               <xsl:text>'; ...&#xD;&#xA;</xsl:text>
            </xsl:for-each>
          </xsl:if>
         <xsl:if test="para != ''">
            <xsl:for-each select="para">
               <xsl:text>         '</xsl:text>
               <xsl:call-template name="para"/>
               <xsl:text>'; ...&#xD;&#xA;</xsl:text>
            </xsl:for-each>
         </xsl:if>
      </xsl:for-each>
   </xsl:template>
   
   <!-- template for adding paragraph contents -->
   <xsl:template name="para">
      <xsl:choose>
         <xsl:when test="literalLayout != ''">
            <xsl:call-template name="doubleApostrophe">
               <!-- escape apostrophes -->
               <xsl:with-param name="string" select="normalize-space(literalLayout)"/>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:call-template name="doubleApostrophe">
               <!-- escape apostrophes -->
               <xsl:with-param name="string" select="normalize-space(.)"/>
            </xsl:call-template>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- template for escaping apostrophes in variable contents to prevent MATLAB syntax errors -->
   <xsl:template name="doubleApostrophe">
     <xsl:param name="string" />
     <xsl:variable name="apostrophe">'</xsl:variable>
     <xsl:choose>
       <xsl:when test="contains($string,$apostrophe)">
         <xsl:value-of select="concat(substring-before($string,$apostrophe), $apostrophe,$apostrophe)" disable-output-escaping="yes" />
         <xsl:call-template name="doubleApostrophe">
           <xsl:with-param name="string" select="substring-after($string,$apostrophe)" />
         </xsl:call-template>
       </xsl:when>
       <xsl:otherwise>
         <xsl:value-of select="$string" disable-output-escaping="yes" />
       </xsl:otherwise>
     </xsl:choose>
   </xsl:template>

</xsl:stylesheet>