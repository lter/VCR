#!/usr/bin/python
# This loops through PASTA datasets within a given scope and creates a
# directory of XML reports, with files identified by files
# John Porter - jhp7e@virginia.edu - 2014

import urllib2
#import urllib  # for python3
import sys,argparse,os,tempfile
from datetime import datetime,timedelta,time
import xml.etree.ElementTree as ET
import lxml.etree as XSLT_ET
from getpass import getpass

DEBUG=0

# Give the path to your email program with options prior to who to send it to....
emailCmd='/bin/mailx -s "PASTA Download Report"  '

styleSheetNameHTML='/home/jhp7e/src/python/PASTAsummary2.xsl'

# set default values in case no command line values are given
pastaToTime=datetime.today()
pastaFromTime=(pastaToTime-timedelta(days=31)).strftime("%Y-%m-%dT%H:%M:%S")
pastaToTime=pastaToTime.strftime("%Y-%m-%dT%H:%M:%S")

# message to be sent to accompany HTML report attachments
emailMsgOut="The attached file has a web page summarizing downloads of datasets \nyou are the contact for. Login at: https://portal.lternet.edu/nis/dataPackageAudit.jsp \nif you want the specific date and time details. \n"

parser=argparse.ArgumentParser(prog=sys.argv[0],description='Produce reports on data usage for specified scope by contact',usage='%(prog)s [options --help]  PASTAscope')
parser.add_argument('PASTAscope', type=str,help='PASTA scope for report e.g. knb-lter-vcr')
parser.add_argument('--userid','-u',type=str,default='',required=False,dest='userId',help='user id for login')
parser.add_argument('--password','-p',type=str,default='',required=False,dest='pWord',help='password for login')
parser.add_argument('--authfile','-a',type=str,default='userdata.txt',required=False,dest='authFile',help='name of authorization file (if used) Default is userdata.txt')
parser.add_argument('--identifier','-i',type=int,default=-999,required=False,dest='identifier',help='PASTA identifier')
parser.add_argument('--revision','-r',type=int,default=-999,required=False,dest='revision',help='PASTA revision')
parser.add_argument('--fromdate','-f',type=str,dest='pastaFromTime',default=pastaFromTime,help='e.g., 2013-12-30, or 2013-11-18T13:05:00')
parser.add_argument('--todate','-t',type=str,dest='pastaToTime',default=pastaToTime,help='e.g., 2013-11-18T13:05:00')
parser.add_argument('--outputtype','-o',dest='argOutputType',choices=['html','xml'],default='html',type=str)
parser.add_argument('--create','-c',dest='createType',choices=['list','directory','email'],default='list',type=str)
parser.add_argument('--createdir','-d',dest='createDir',default='',type=str,help="name of directory in which to store results if --create=directory is chosen")
parser.add_argument('--maillist','-m',dest='mailList',default='',type=str,help="specify file to read email addresses (one per line) to be used for sending reports")
parser.add_argument('--genmaillist','-g',dest='genMailList',default='',type=str,help="generate a mailing list from contacts, specify file where contact email addresses will be stored. No other outputs will be produced.")
parser.add_argument('--quiet','-q',action="store_false",default='store_true',help="suppress messages during processing")

args=parser.parse_args()
argList=vars(args)
pastaScope=argList['PASTAscope']
# set or get username and password or authorization file
userId=argList['userId']
pWord=argList['pWord']
authFile=argList['authFile']

# if no username is specified, try opening the authorization file
userData='' 
if userId == '':
    try:
        authFileIn=open(authFile,"r")
        userData=authFileIn.readline()
        authFileIn.close()
    except:    
        userData='' 

if userData == '' and userId == '':
    userId=raw_input("Username: ")
    uName='uid='+userId+',o=LTER,dc=ecoinformatics,dc=org'
    if pWord == '':
        pWord=getpass("Password: ")
else:
    uName='uid='+userId+',o=LTER,dc=ecoinformatics,dc=org'
    if pWord == '' and userData == '':
        pWord=getpass("Password: ")

if userData == '':
    userData="Basic " + (uName + ":" + pWord).encode("base64").rstrip()
# to see the user string for saving to an authorization file, uncomment the following line
#print(userData)


if argList['identifier'] >= 0:
    pastaId=str(argList['identifier'])
else:
    pastaId=''
if argList['revision'] >= 0:
    pastaRev=str(argList['revision'])
else:
    pastaRev=''
pastaFromTime=argList['pastaFromTime']
pastaToTime=argList['pastaToTime']
genMailList=argList['genMailList']
mailList=argList['mailList']


##if len(sys.argv) > 1:
##    packageIdParts=sys.argv[1].split('.')
##    #print(len(packageIdParts))
##    if len(packageIdParts)>= 1:
##        pastaScope=packageIdParts[0]
##    if len(packageIdParts)>= 2:
##        pastaId=packageIdParts[1]
##    if len(packageIdParts)>= 3:
##        pastaRev=packageIdParts[2]
##if len(sys.argv) > 3:    
##    pastaFromTime=sys.argv[2]
##    pastaToTime=sys.argv[3]

## Define functions for later
def metadataUseCount(pastaScope,pastaId,pastaVersion):
    pastaUrl="http://pasta.lternet.edu/audit/report"
    pastaResource="https://pasta.lternet.edu/package/metadata/eml/"+pastaScope+"/"+str(pastaId)+"/"+str(pastaVersion)
 
    if pastaToTime == '':
    #    pastaToTime=datetime.today().strftime("%Y-%m-%dT%H:%M:%S")
    #    print pastaToTime
        pastaQueryString=pastaUrl+'/?resourceId='+pastaResource+'&fromTime='+pastaFromTime
    else:
            pastaQueryString=pastaUrl+'/?resourceId='+pastaResource+'&fromTime='+pastaFromTime+'&toTime='+pastaToTime
    if DEBUG:
        print(pastaQueryString)
    req=urllib2.Request(pastaQueryString)
    #req=urllib2.Request('https://pasta.lternet.edu/audit/report/?resourceId=https://pasta.lternet.edu/package/data/eml/knb-lter-vcr/26/15/VCR97019&fromTime=2012-09-01T00:00:00')

    req.add_header('Authorization', userData)

    usock=urllib2.urlopen(req,timeout=160)
    if(DEBUG==1):
        print("\nMETADATA ------------")
        print("url: "+str(usock.geturl()))
        print("HTML return code: "+str(usock.getcode()))
        print(usock.info())
        print(usock.readlines())
        usock.close()
        usock=urllib2.urlopen(req,timeout=160)
        
    xmlTree = ET.parse(usock)
    xmlRoot=xmlTree.getroot()
    auditRecords=xmlRoot.findall('.//auditRecord')
    return(len(auditRecords))
## uncomment this to print out list of metadata downloads
##        for nodeA in auditRecords:
##            print("Metadata Download: "+nodeA.find('./entryTime').text+" user "+nodeA.find('./user').text)
##        

def entityReport(pastaScope,pastaId,pastaVersion,pastaEntity):
    pastaUrl="http://pasta.lternet.edu/audit/report"
    pastaResource="https://pasta.lternet.edu/package/data/eml/"+pastaScope+"/"+str(pastaId)+"/"+str(pastaVersion)+"/"+pastaEntity
    #print pastaResource

    if pastaToTime == '':
    #    pastaToTime=datetime.today().strftime("%Y-%m-%dT%H:%M:%S")
    #    print pastaToTime
        pastaQueryString=pastaUrl+'/?serviceMethod=readDataEntity&resourceId='+pastaResource+'&fromTime='+pastaFromTime
    else:
            pastaQueryString=pastaUrl+'/?serviceMethod=readDataEntity&resourceId='+pastaResource+'&fromTime='+pastaFromTime+'&toTime='+pastaToTime
    if DEBUG:
        print(pastaQueryString)

    req=urllib2.Request(pastaQueryString)
        
    req.add_header('Authorization', userData)

    try:
        usock=urllib2.urlopen(req)
        if(DEBUG==1):
            print("\nDATA ------------")
            print("url: "+str(usock.geturl()))
            print("HTML return code: "+str(usock.getcode()))
            print(usock.info())
            print(usock.readlines())
            usock.close()
            usock=urllib2.urlopen(req,timeout=160)
    except:
        entityDownloadCountX=ET.SubElement(entitiesX,"entityDownloadCount")
        entityDownloadCountX.text="0"
        return(0)
    #print raw XML output for debug
    #print(usock.read())
    xmlTree = ET.parse(usock)
    xmlRoot=xmlTree.getroot()
    blist=xmlRoot.findall('.//auditRecord')
    #print(blist)
    entityDownloadCountX=ET.SubElement(entityX,"entityDownloadCount")
    entityDownloadCountX.text=str(len(blist))
    #print("Number of Downloads: "+str(len(blist)))
    myCount=0
    userArray={'public':0}
    for b in blist:
        responseStatus=b.find('./responseStatus').text
        user=b.find('./user').text
# only count if download didn't fail with 401 code
        if responseStatus != '401':
            myCount=myCount+1
            if user in userArray:
                userArray[user]=userArray[user]+1
            else:
                userArray[user]=1
    #print("myCount= "+str(myCount)+"\n")
    sortedUsers= sorted(userArray.keys(),key=lambda i: userArray[i])
    sortedUsers.reverse()
    entityUserCountX=ET.SubElement(entityX,"entityUserCount")
    entityUserCountX.text=str(len(sortedUsers))
    entityUsersX=ET.SubElement(entityX,"entityUsers")
    for myKey in sortedUsers:
            entityUserX=ET.SubElement(entityUsersX,"entityUser")
            entityUserIdX=ET.SubElement(entityUserX,"entityUserId")
            entityUserIdX.text=myKey
            entityUserDownloadCountX=ET.SubElement(entityUserX,"entityUserDownloadCount")
            entityUserDownloadCountX.text=str(userArray[myKey])

            #print("user= "+myKey+ "   downloads="+str(userArray[myKey])
    return(myCount)        
       

# START MAIN PROGRAM
# Read input email address file
if mailList <> '':
    fIn=open(mailList,'r')
    inMailList=fIn.read().splitlines()
    fIn.close()
# create output ElementTree XML structure
xRoot=ET.Element('pastaSummaries')
fromTimeX=ET.SubElement(xRoot,"fromTime")
fromTimeX.text=pastaFromTime
toTimeX=ET.SubElement(xRoot,"toTime")
toTimeX.text=pastaToTime

if pastaId == '':
    pastaUrl="http://pasta.lternet.edu/package/eml/"+pastaScope                      
    pastaReq=urllib2.Request(pastaUrl)    
    pastaReq.add_header('Authorization', userData)
    pastaSock=urllib2.urlopen(pastaReq,timeout=60)
    pastaIds=pastaSock.read()
else:
    pastaIds=pastaId
    #print pastaString

# set up a list to hold contact emails    
contactEmailArray={}   
for pastaId in pastaIds.split():
    if pastaRev == '':
        pastaUrl="http://pasta.lternet.edu/package/eml/"+pastaScope+"/"+pastaId                      
        pastaReq=urllib2.Request(pastaUrl)    
        pastaReq.add_header('Authorization', userData)
        pastaSock=urllib2.urlopen(pastaReq,timeout=60)
        #produce a list of versions
        pastaVersions=pastaSock.read().split()
        # most recent version first so reverse order of versions
        pastaVersions.reverse()
    else:
        pastaVersions=[pastaRev]
    for pastaVersion in pastaVersions:
        pastaSummaryX=ET.SubElement(xRoot,"pastaSummary")    
        if args.quiet:
             sys.stderr.write("processing package: "+pastaScope+"/"+str(pastaId)+"/"+str(pastaVersion)+"\n")
        # Get the data package metadata to extract dataset title and entities
        # liburl2 truncates downloaded data at 32768 bytes if HTTPS used
        emlUrl="http://pasta.lternet.edu/package/metadata/eml/"+pastaScope+"/"+str(pastaId)+"/"+str(pastaVersion)
        emlReq=urllib2.Request(emlUrl)
        emlReq.add_header('Authorization', userData)
        emlSock=urllib2.urlopen(emlReq,timeout=60)
        emlString=emlSock.read()
        if(DEBUG==1):
            print("url: "+str(emlSock.geturl()))
            print("HTML return code: "+str(emlSock.getcode()))
            print(emlSock.info())
            print(emlString)
        emlRoot=ET.fromstring(emlString)
        packageIdX=ET.SubElement(pastaSummaryX,"packageId")
        packageIdX.text=pastaScope+"."+str(pastaId)+"."+str(pastaVersion)
        titleX=ET.SubElement(pastaSummaryX,"title")
        titleX.text=emlRoot.find('./dataset/title').text
        contactsX=ET.SubElement(pastaSummaryX,"contacts")
 
        contactEmails=emlRoot.findall('./dataset/contact/electronicMailAddress')
        contactNumber=0
        for contactEmail in contactEmails:
            if contactEmail.text != "tech-support@lternet.edu":
                contactX=ET.SubElement(contactsX,"contact")
                electronicMailAddressX=ET.SubElement(contactX,"electronicMailAddress>")
                electronicMailAddressX.text=contactEmail.text
                contactEmailArray[contactEmail.text]=1
            contactNumber=contactNumber+1

        #print contactEmails
        
        #print(emlString)
    # Set up a list of entity names for use later
        entityRecords=emlRoot.findall('.//entityName')
        ##print("contains "+str(len(entityRecords))+" data entities");
        ##for entityRecord in entityRecords:
        ##    print(entityRecord.text)
        metadataDownloadCountX=ET.SubElement(pastaSummaryX,"metadataDownloadCount")
        metadataDownloadCountX.text=str(metadataUseCount(pastaScope,pastaId,pastaVersion))
        entityCounter=0
        pastaUrl="http://pasta.lternet.edu/package/data/eml/"+pastaScope+"/"+str(pastaId)+"/"+str(pastaVersion)
        #print(pastaUrl)
        req1=urllib2.Request(pastaUrl)
        req1.add_header('Authorization', userData)
        usock=urllib2.urlopen(req1)
        pastaEntitiesId=usock.read()
        entitiesX=ET.SubElement(pastaSummaryX,"entities")
        dataDownloadTotalCount=0
        for pastaEntity in pastaEntitiesId.split():
            entityX=ET.SubElement(entitiesX,"entity")
            entityName=entityRecords[entityCounter].text
            entityNameX=ET.SubElement(entityX,"entityName")
            entityNameX.text=entityName
            entityIdX=ET.SubElement(entityX,"entityId")
            entityIdX.text=pastaEntity
            entityCounter=entityCounter+1
            #print("\nEntity",entityCounter,entityName)
            dataDownloadTotalCount=dataDownloadTotalCount+entityReport(pastaScope,pastaId,pastaVersion,pastaEntity)
        dataDownloadTotalCountX=ET.SubElement(pastaSummaryX,"dataDownloadTotalCount")
        dataDownloadTotalCountX.text=str(dataDownloadTotalCount)        
xTree=ET.ElementTree(xRoot)
xString=ET.tostring(xRoot)
xml1=XSLT_ET.fromstring(xString)
if genMailList <> '':
    fOut=open(genMailList,'w')
    contactEmailList=sorted(contactEmailArray.keys())
    for contactEmail in contactEmailList:
        fOut.write(contactEmail+"\n")
    fOut.close()
    if args.quiet:
        sys.stderr.write("List of contact emails written to "+genMailList+"\n")
else:    
    if argList['argOutputType']=='xml':
        print(xString)
    else:
        xslt=XSLT_ET.parse(styleSheetNameHTML)
        contactEmailList=sorted(contactEmailArray.keys())
        if mailList <> '':
            contactEmailList=inMailList
        if args.quiet :
            sys.stderr.write("email list: "+str(contactEmailList)+"\n")
        if argList['createType']=='directory' :
            if argList['createDir']=='' :
                outDirName="./PASTAReport_"+datetime.today().strftime("%Y%m%d%H%M")
            else:
                outDirName=argList['createDir']
            os.mkdir(outDirName)
        for contactEmail in contactEmailList:
            if args.quiet:
                sys.stderr.write("processing "+contactEmail+"\n")
            if argList['createType']=='list' :
                transform=XSLT_ET.XSLT(xslt)
                newdom=transform(xml1,contactEmail="'"+contactEmail+"'")
                print(XSLT_ET.tostring(newdom,pretty_print=True))
            if argList['createType']=='directory' :
                contactEmailStripped=contactEmail.strip()    # get rid of leading and trailing spaces
                contactFileName=contactEmailStripped.replace("@","_at_")+".html"
                fileOut=open(outDirName+"/"+contactFileName,mode='w')
                transform=XSLT_ET.XSLT(xslt)
                newdom=transform(xml1,contactEmail="'"+contactEmail+"'")
                fileOut.write(str(XSLT_ET.tostring(newdom,pretty_print=True)))
                fileOut.close()
            if argList['createType']=='email' :
                fileOut=tempfile.NamedTemporaryFile(suffix=".html",delete=True)
                msgOut=tempfile.NamedTemporaryFile(suffix=".txt",delete=True)
                msgOut.write(emailMsgOut)
                transform=XSLT_ET.XSLT(xslt)
                newdom=transform(xml1,contactEmail="'"+contactEmail+"'")
                fileOut.write(XSLT_ET.tostring(newdom,pretty_print=True))
                #print(fileOut.name)
                fileOut.seek(0)
                msgOut.seek(0)
                os.system(emailCmd+" -a "+fileOut.name+" "+contactEmail+" <"+msgOut.name)
                fileOut.close()
                msgOut.close()



    


