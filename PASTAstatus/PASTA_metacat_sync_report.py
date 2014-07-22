#!/usr/bin/python
# Compares a Metacat HarvestList with PASTA holdings and produces a
# XML or HTML report
# John Porter - jhp7e@virginia.edu - 2014

import urllib2
#import urllib  # for python3
import sys,argparse,os,tempfile
import xml.etree.ElementTree as ET

DEBUG=0

# set things up so we can format the help text
class SmartFormatter(argparse.HelpFormatter):

    def _split_lines(self, text, width):
        # this is the RawTextHelpFormatter._split_lines
        if text.startswith('R|'):
            return text[2:].splitlines()  
        return argparse.HelpFormatter._split_lines(self, text, width)

parser=argparse.ArgumentParser(prog=sys.argv[0],description='Compare a metacat harvestlist with PASTA holdings',usage='%(prog)s [options --help] -l harvestListUrl ',formatter_class=SmartFormatter)
parser.add_argument('-l',dest='harvestListUrl',type=str,default='',help='URL of EML harvest list',required=False)
parser.add_argument('--outputtype','-o',dest='argOutputType',choices=['csv','urlList','urlListUpdate','urlListNew'],default='csv',type=str,help="R|Output type: \n\
csv (default) - Generates a comma-separated-value listing for all data packages in the harvestList\n\
urlList - lists metadata URLs for all data packages not currently in PASTA \n          \
or where PASTA revisions are older than the current revision\n\
urlListUpdate - lists metadata URLs for data packages already in PASTA, that have an older revision\n\
urlListNew - lists metadata URLs for data packages not in PASTA, regardless of revision", required=False)

args=parser.parse_args()
argList=vars(args)
harvestListUrl=argList['harvestListUrl']
outputType=argList['argOutputType']
if (harvestListUrl==""):
    print('Compare a metacat harvestlist with PASTA holdings\n Usage= PASTA_metacat_sync_report.py [options --help] -l harvestListUrl') 
    harvestListUrl=raw_input("What is the URL of the EML harvestList you wish to check?\n")
    if (outputType=='csv'):
        outputType="xxx"
    while (outputType != "csv" and outputType != "urlList" and outputType != "urlListUpdate" and outputType != "urlListNew" and outputType != ""):
           outputType=raw_input("What output do you want (csv, urlList, urlListUpdate or urlListNew) (blank for CSV)?\n")
    if (outputType==""):
        outputType="csv"
    
# START MAIN PROGRAM
# create output ElementTree XML structure
xRoot=ET.Element('PASTA_Metacat_Summary')
harvestListUrlX=ET.SubElement(xRoot,"harvestListUrl")
harvestListUrlX.text=harvestListUrl

# Get the harvest list to be compared
harvestListReq=urllib2.Request(harvestListUrl)    
harvestSock=urllib2.urlopen(harvestListReq,timeout=60)
harvestListXml=harvestSock.read()
if (DEBUG <> 0):
    print(harvestListXml)

# Fetch the scope, identifier and revision of data in the harvest list
emlListRoot=ET.fromstring(harvestListXml)
if (DEBUG <> 0):
    print emlListRoot.tag

if (outputType=='csv'):
    print("packageId,pastaStatus,currentPastaRevision,emlUrl")
# loop through the list 
for emlDoc1 in emlListRoot.findall('document'):
    emlUrl=emlDoc1.find('documentURL').text
    for emlDoc in emlDoc1.findall('docid'):
        pastaScope=emlDoc.find('scope').text
        pastaId=emlDoc.find('identifier').text
        pastaRev=emlDoc.find('revision').text

        pastaUrl="http://pasta.lternet.edu/package/eml/"+pastaScope+"/"+pastaId+"/"+pastaRev 
        if (DEBUG <> 0):
            print(pastaUrl)
        pastaReq=urllib2.Request(pastaUrl)   
        try:
            pastaSock=urllib2.urlopen(pastaReq,timeout=60)
            pastaMsg=pastaSock.read()
            if (DEBUG <> 0):
                print(pastaMsg)
            inPasta="Current_revision_in_PASTA"
            if (outputType == 'csv'):
                print(pastaScope+"."+pastaId+"."+pastaRev+","+inPasta+","+pastaRev+","+emlUrl)
        except urllib2.HTTPError:
            inPasta="not_in_PASTA"
            if (outputType == 'urlList'): 
                print(emlUrl)
            else:
                pastaUrl="http://pasta.lternet.edu/package/eml/"+pastaScope+"/"+pastaId
                pastaReq=urllib2.Request(pastaUrl)   
                try:
                    pastaSock=urllib2.urlopen(pastaReq,timeout=60)
                    pastaMsg=pastaSock.read()
                    revList=pastaMsg.split()
                    currentRev=revList[len(revList)-1]
                    inPasta="Needs_upgrade"
                    if (outputType == 'urlListUpdate'):
                        print(emlUrl)
                    elif (outputType == 'csv'):
                        print(pastaScope+"."+pastaId+"."+pastaRev+","+inPasta+","+currentRev+","+emlUrl)
                except urllib2.HTTPError:
                    if (outputType == 'urlListNew'):
                        print(emlUrl)
                    elif (outputType == 'csv'):
                        print(pastaScope+"."+pastaId+"."+pastaRev+","+inPasta+",none,"+emlUrl)






    


