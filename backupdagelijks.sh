#!/bin/sh
#Dagelijkse backup van alle systemen van Zetadisplay NL.

###################################################################################################################
###################################################################################################################
#wijzigingen in dit script ALLEEN op de QA-Backup maken.
#De QA-Backup stuurt elke dag de hele script directory naar de QR-Backup ruim voor backup start.
#Dit is dan meteen de backup van dit backup script.
###################################################################################################################
###################################################################################################################

#Variable declareren
BACKUPROOT=/backup
BASEDIR="$BACKUPROOT/script"

DAYOFWEEK=$(date +"%u")
WEEKDAGEN=( "7zondag" "1maandag" "2dinsdag" "3woensdag" "4donderdag" "5vrijdag" "6zaterdag" "7zondag" )

DAYNAME[0]=${WEEKDAGEN[$DAYOFWEEK]} 	#huidige dag
DAYNAME[1]=${WEEKDAGEN[$DAYOFWEEK-1]}	#vorige dag

INPUTFILE=( "$BASEDIR/hostlist.csv" "$BASEDIR/hostlisttest.csv" )
CENTRALLOGFILE=$BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/backup.log
[ -f $CENTRALLOGFILE ] && rm $CENTRALLOGFILE
	
#Functions laden
###################################################################################################################
#Als functions file niet bestaat dan exit program
if [ -f $BASEDIR/functions/fn-backup.sh ] ; then
		#Inlezen van file met functions dmv ". " (punt spatie)
		. $BASEDIR/functions/fn-backup.sh
		#Tweede mogelijkheid is file in te lezen met commando "source"
		#source $BASEDIR/functions/fn-backup.sh || exit
	else
		date +"%d-%m-%y  %T  ERROR functions/Pbackup.sh file not found"
		exit 99
fi
###################################################################################################################


#Start Dagelijkse backup procedure
###################################################################################################################
###################################################################################################################
###################################################################################################################
#Testrun ja of nee
case "${1^^}" in
	"")
		TESTRUN=0
		HOSTLIST=${INPUTFILE[$TESTRUN]}
	;;
	"TEST")
		TESTRUN=1
		HOSTLIST=${INPUTFILE[$TESTRUN]}
	;;
esac	

#Directory struktuur maken indien nodig
if [ ! -d $BACKUPROOT/${HOSTNAME:1:1} ] ; then mkdir $BACKUPROOT/${HOSTNAME:1:1} ; fi #Dir aanmaken.
if [ ! -d $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]} ] ; then mkdir $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]} ; fi #Dir aanmaken.

#melding naar logfile en bij testrun ook naar scherm
log="**********************************************************************************" ; fn_CentralLOG
log="**********************************************************************************" ; fn_CentralLOG
log="DAGELIJKSE backup TESTRUN=$TESTRUN" ; fn_CentralLOG
log="**********************************************************************************" ; fn_CentralLOG
log="**********************************************************************************" ; fn_CentralLOG

#DEBUG meldingen.....
###################################################################################################################
###################################################################################################################
###################################################################################################################
#echo "TESTRUN is: $TESTRUN"
#echo "DAYNAME is: ${DAYNAME[0]}"
#echo "INPUTFILE is: ${INPUTFILE[@]}"
#echo "HOSTLIST is: $HOSTLIST"

#Lees CSV file met velden PUNT COMMA gescheiden (GEEN SPATIES erin!!!)	
#[ ! -f $HOSTLIST ] && { date +"%d-%m-%y  %T  ERROR $HOSTLIST file not found"; exit 99; } #compacte vorm werkt ook
if [ ! -f $HOSTLIST ] ; then 
	TESTRUN=1	#status wijzigen ik wil altijd melding zien als op scherm als bij deze error
	log="ERROR $HOSTLIST file not found" ; fn_CentralLOG
	exit 99
fi

log="**********************************************************************************" ; fn_CentralLOG
log="**********************************************************************************" ; fn_CentralLOG
log="Backup maken van backupsever $HOSTNAME server starten" ; fn_CentralLOG
log="**********************************************************************************" ; fn_CentralLOG
log="**********************************************************************************" ; fn_CentralLOG
#/root
#/etc
#/backup/scipts ($BASEDIR)
###################################################################################################################
###################################################################################################################
###################################################################################################################
if [ ! -d $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME ] ; then mkdir $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME ; fi #Dir aanmaken	

if [ ! -d $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/root ] ; then mkdir $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/root ; fi #Dir aanmaken	
rsync -avzr -e ssh --delete /root/ /$BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/root/ >> /dev/hull 2>&1

if [ ! -d $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/etc ] ; then mkdir $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/etc ; fi #Dir aanmaken	
rsync -avzr -e ssh --delete --exclude=proc /etc/ /$BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/etc/ >> /dev/hull 2>&1

if [ ! -d $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/script ] ; then mkdir $BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/script ; fi #Dir aanmaken	
rsync -avzr -e ssh --delete $BASEDIR/ /$BACKUPROOT/${HOSTNAME:1:1}/${DAYNAME[0]}/$HOSTNAME/script/ >> /dev/hull 2>&1
log="Backup van $HOSTNAME is klaar" ; fn_CentralLOG

###################################################################################################################
###################################################################################################################
###################################################################################################################
for i in `cat $HOSTLIST` ; do
	#als eerste teken van string is '#' OF ' ' (spatie) dan, continue
	if [[ $i = '#'* ]] || [[ $i = ' '* ]]; then continue ; fi
    #als regel geen ";" bevat dan continue
	if echo "$i" | grep -v -q ';'; then continue ; fi

	TYPE=`echo $i | cut -d\; -f1`
	LOKATIE=`echo $i | cut -d\; -f2`
	SYSTEM=`echo $i | cut -d\; -f3`
	JOBNAME=`echo $i | cut -d\; -f4`
	DIRS=`echo $i | cut -d\; -f5`
	EXCL=`echo $i | cut -d\; -f6`
	DBNAME=`echo $i | cut -d\; -f7`
	DBPORTNR=`echo $i | cut -d\; -f8`
	DBPASSW=`echo $i | cut -d\; -f9`
	
	#Variable declareren, op basis van ingelezen gegevens
	if [[ ${LOKATIE^^} ==  'A' ]] ; then
		SRVIP=$(host $SYSTEM.cc.qyn.nl | grep -o '\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)\.\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)\.\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)\.\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)')
	else
		SRVIP=$(host $SYSTEM.science.local | grep -o '\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)\.\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)\.\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)\.\(25[0-5]\|2[0-4][0-9]\|[01][0-9][0-9]\|[0-9][0-9]\)')
	fi
	
	#Control of laatste teken "/" is in variable $DIRS
	LENGTE=${#DIRS}-1						#geeft lengte van string terug
	#echo ${DIRS:$LENGTE} 					#Geeft substing terug
	if [ ! "${DIRS:$LENGTE}" = "/" ] ; then #Als laatste teken in $DIRS geen '/' is dan, toevoegen.
		DIRS=$DIRS/
	fi

	#Backup alleen maken naar 'lokale' backup server dus testen
	x=$(echo $HOSTNAME | cut -d'-' -f 1) 

	#voor test systeem van Emile onderstaande regel ingebouwd
	if [[ $HOSTNAME == "linuxhome" ]] ; then x=QA ; fi

	LOK=Q$LOKATIE 

	#als systeem niet "lokaal" is dan naar volgende
	if [[ ! $LOK == $x ]] 
		then
		log="************************************************************************" ; fn_CentralLOG
		log="'$JOBNAME', SKIP systeem, geen lokaal systeem voor Backuphost $HOSTNAME" ; fn_CentralLOG
		log="************************************************************************" ; fn_CentralLOG
		continue
	fi
		
	ping -c 2 $SYSTEM > /dev/null 2>&1	#Als SYSTEM niet te pingen is, dan systeem overslaan
	rc=$?
	if [[ $rc -eq 0 ]]; then
				
		#Directory struktuur maken indien nodig
		if [ ! -d $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM ] 			; then mkdir $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM ; fi #Dir aanmaken.
		if [ ! -d $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME ]	; then mkdir $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME ; fi #Dir aanmaken
	
		#Job logfile maken
		JOBLOGFILE=$BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME.log
		[ -f $JOBLOGFILE ] && rm $JOBLOGFILE

		#toevoeging Emile 27-2-2017, zodat we niet een verschil van 7 dagen maar van 1 dag kopieren van live systeem
		#wijziging Emile 30-10-2018 Alleen voor windows backups Content manager is grootste server die backup duurt erg lang
		if [[ ${TYPE^^} ==  'W' ]] ; then
			log="$SYSTEM, '$JOBNAME' begin sync met vorige dag" ; fn_JobLOG ; fn_CentralLOG
			log="************************************************************************" ; fn_JobLOG ; fn_CentralLOG
			log="comando: rsync -tvzr --delete $BACKUPROOT/${LOKATIE^^}/${DAYNAME[1]}/$SYSTEM/$JOBNAME/ $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
			rsync -tvzr --delete $BACKUPROOT/${LOKATIE^^}/${DAYNAME[1]}/$SYSTEM/$JOBNAME/ $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
			log="$SYSTEM, '$JOBNAME' einde sync met vorige dag" ; fn_JobLOG ; fn_CentralLOG
			log="************************************************************************" ; fn_JobLOG ; fn_CentralLOG
			log="************************************************************************" ; fn_JobLOG ; fn_CentralLOG
		fi
	else
		log="$SYSTEM, '$JOBNAME' ERROR: DNS naam NIET beschikbaar, met een PING!" ; fn_CentralLOG
		log="************************************************************************" ; fn_CentralLOG
		log="************************************************************************" ; fn_CentralLOG
		#Critical melding verzenden met NSCA
		error=2
		log="PING naar server werkt NIET!" ; fn_SendNSCA
		continue
	fi

	#**********************************************************************************************************************
	#Restore jobs voorbereiden 
	#**********************************************************************************************************************	
	fn_restore

	#**********************************************************************************************************************
	#Soort job dat gestart moet worden
	#**********************************************************************************************************************	
	case ${TYPE^^} in	#$TYPE omzetten naar Uppercase
		'L'*)			#Linux systeem backup
			log="een ${TYPE^^} Linux backup $SYSTEM $JOBNAME naar backuphost: $HOSTNAME" ; fn_JobLOG ; fn_CentralLOG
			if [ -f $BACKUPROOT/script/$SYSTEM-$JOBNAME.exclude ] ; then
				log="Linux systeem, met exclusions from file" ; fn_JobLOG
				log="COMMANDO:rsync -avzr -e ssh --delete --exclude-from $BACKUPROOT/script/$SYSTEM-$JOBNAME.exclude root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
							  rsync -avzr -e ssh --delete --exclude-from $BACKUPROOT/script/$SYSTEM-$JOBNAME.exclude root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME  >> $JOBLOGFILE 2>&1
							  rc=$?
			else
				if [ -n "$EXCL" ] ; then
					log="Linux systeem, met exclusions" ; fn_JobLOG
					log="COMMANDO:rsync -avzr -e ssh --delete --exclude=$EXCL root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
								  rsync -avzr -e ssh --delete --exclude=$EXCL root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
								  #rsync -avzr -e "ssh -i /root/.ssh/id_rsa" --delete --exclude=$EXCL root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
								  rc=$?
				else
					log="Linux systeem zonder exclusions" ; fn_JobLOG 
					log="COMMANDO:rsync -avzr -e ssh --delete root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
								  rsync -avzr -e ssh --delete root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
								  rc=$?
				fi
			fi
			;;
		'W'*)				#Windows systeem backup
			log="een ${TYPE^^} Windows backup $SYSTEM $JOBNAME naar backuphost: $HOSTNAME" ; fn_JobLOG ; fn_CentralLOG
			if [ -f $BACKUPROOT/script/$SYSTEM-$JOBNAME.exclude ] ; then
				log="Windows systeem, met exclusions from file" ; fn_JobLOG
				log="COMMANDO:rsync -tvzr --delete --exclude-from $BACKUPROOT/script/$SYSTEM-$JOBNAME.exclude root@$SYSTEM::$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
							  rsync -tvzr --delete --exclude-from $BACKUPROOT/script/$SYSTEM-$JOBNAME.exclude root@$SYSTEM::$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
							  rc=$?
			else
				if [ -n "$EXCL" ] ; then
					log="Windows systeem, met exclusions" ; fn_JobLOG
					log="COMMANDO:rsync -tvzr --delete --exclude=$EXCL $SYSTEM::$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
								  rsync -tvzr --delete --exclude=$EXCL $SYSTEM::$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
								  rc=$?
				else
					log="Windows systeem zonder exclusions" ; fn_JobLOG
					log="COMMANDO:rsync -tvzr --delete $SYSTEM::$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
								  rsync -tvzr --delete $SYSTEM::$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
								  rc=$?
				fi
			fi
			;;
		'M'*)			#MS-SQL Database backup
			log="een ${TYPE^^} MS-SQL backup $SYSTEM $JOBNAME naar backuphost: $HOSTNAME" ; fn_JobLOG ; fn_CentralLOG
			log="MS-SQL kopie van Directory D:\backup maken, hier staat database dump" ; fn_JobLOG
			log="**********************************************************************************" ; fn_JobLOG
			log="Op Windows MS-SQL wordt een database dump gescheduled in directory D:\backup" ; fn_JobLOG
			log="**********************************************************************************" ; fn_JobLOG
			log="COMMANDO:rsync -avz --delete --exclude=.* $SYSTEM::data/backup/ $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
						  rsync -avz --delete --exclude=.* $SYSTEM::data/backup/ $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
						  rc=$?
			;;
		'S'*)			#Storeserver backup
			#Op Storeserver maken we altijd backup van:
			#/usr/sbin/firewall.sh
			#/etc
			log="een ${TYPE^^} Storeserver backup $SYSTEM $JOBNAME naar backuphost: $HOSTNAME" ; fn_JobLOG ; fn_CentralLOG
			if [ ! -d $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/Firewall ] ; then mkdir $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/Firewall ; fi #Dir aanmaken.
			log="Storeserver" : fn_JobLOG
			log="COMMANDO:rsync -avzr -e ssh --delete root@$SYSTEM:/usr/sbin/firewall.sh $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/Firewall/firewall.sh" ; fn_JobLOG
						  rsync -avzr -e ssh --delete root@$SYSTEM:/usr/sbin/firewall.sh $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/Firewall/firewall.sh >> $JOBLOGFILE
			log="COMMANDO:rsync -avzr -e ssh --delete root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME" ; fn_JobLOG
						  rsync -avzr -e ssh --delete root@$SYSTEM:$DIRS $BACKUPROOT/${LOKATIE^^}/${DAYNAME[0]}/$SYSTEM/$JOBNAME >> $JOBLOGFILE 2>&1
						  rc=$?
			;;
		'P'*)				#Postgress backup
			continue
			;;
		'D'*)				#Database backup
			continue
			;;
		*)				#Alle andere opties, melding in log en ga door naar volgende record
			log="$SYSTEM, '$JOBNAME' NIET ondersteund TYPE entry in de $HOSTLIST!" ; fn_CentralLOG
			;;
	esac

	###################################################################################################################	
	###################################################################################################################	
	log="**********************************************************************************" ; fn_JobLOG ; fn_CentralLOG
	log="$SYSTEM, '$JOBNAME' returnwaarde $rc"  ; fn_JobLOG ; fn_CentralLOG
	###################################################################################################################	
	###################################################################################################################	
	#Send return value 5x naar Nagios dmv NSCA, want op QA-Nagios komt melding niet altijd aan.
	NAGHost=$SYSTEM-$JOBNAME
	NAGService=${DAYNAME[0]:0:3}
	for i in {1..5}
	do
		case $rc in	
		0)
			#melding alle ok
			error=$rc
			log="RSYNC OK, returnvalue $rc" ; fn_SendNSCA 
			;;
		23)
			error=0
			log="Partial tranfer, returnvalue $rc" ; fn_SendNSCA
			;;
		24)
			error=0
			log="Files verwijderd tijdens backup, returnvalue $rc" ; fn_SendNSCA
			;;
		#x)
			#melding warning
			#error=0
			#log="Warning, returnvalue $rc" ; fn_SendNSCA 
			#;;
		*)
			#melding Critical
			error=2
			log="Error, returnvalue $rc" ; fn_SendNSCA
			;;
		esac
		sleep 2s
	done
	fn_JobLOG ; fn_CentralLOG
	log="**********************************************************************************" ; fn_JobLOG ; fn_CentralLOG
done

if [ $HOSTNAME == "QA-Backup" ] ; then
	###################################################################################################################
	###################################################################################################################
	log="**********************************************************************************" ; fn_CentralLOG
	log="**********************************************************************************" ; fn_CentralLOG
	log="In de Dagelijkse backup vanaf de QA-Backup ook rapporteren over beschikbare OpenVPN certificaten" ; fn_CentralLOG
	log="**********************************************************************************" ; fn_CentralLOG
	log="**********************************************************************************" ; fn_CentralLOG
	###################################################################################################################
	###################################################################################################################
	SERVICE=Certificaten
	SRVnaam=(QA-Batch QA-QYNCast)
	SRVaantal=(50 50) 
	Nagios=(20 21)
	
	i=0
	for i in 0 1
	do
		LOCATION="$BACKUPROOT/A/${DAYNAME[0]}/${SRVnaam[$i]}/data/certificatesV3"
		FILECOUNT=$(find $LOCATION -maxdepth 1 -type f | wc -l)
	    log="**********************************************************************************" ; fn_CentralLOG
		log="Op ${SRVnaam[$i]} nog $FILECOUNT OpenVPN Certificaten, Alarm pas bij minder dan ${SRVaantal[$i]}" ; fn_CentralLOG
		log="**********************************************************************************" ; fn_CentralLOG
		log="nog $FILECOUNT certificaten"
		if [ "$FILECOUNT" -le ${SRVaantal[$i]} ] ; then
				#Melding Alarm
				error=2
				for x in {1..5}
				do
					fn_SendNSCA
					sleep 2s
				done
			else
				#Melding OK
				error=0
				for x in {1..5}
				do
					fn_SendNSCA
					sleep 2s
				done
			fi
	done

	###################################################################################################################
	###################################################################################################################
	log="**********************************************************************************" ; fn_CentralLOG
	log="**********************************************************************************" ; fn_CentralLOG
	log="In de Dagelijkse backup vanaf de QA-Backup ook weekend backup starten" ; fn_CentralLOG
	log="**********************************************************************************" ; fn_CentralLOG
	log="**********************************************************************************" ; fn_CentralLOG
	###################################################################################################################
	###################################################################################################################
	## In weekend script wordt getest op dag en de juiste job gestart
	################################################################################################################################# 
	#Script Backup maken over de lokaties heen.
	
	#Omdat deze jobs lang duren aanroep doen zodat taak niet stopt als console scherm gesloten wordt.
	#Dit doe je met commando "screen"
	#http://www.tecmint.com/screen-command-examples-to-manage-linux-terminals/
	#starten #screen /backup/script/weekend.sh
	#Proces naar achtergrond dmv toets combi CTR-A
	#	Detach van het proces dmv d (detach)
	#Overzicht van screen achtergrond processen:
	#	screen -ls
	#screen sessie overnemen/naar foreground brengen.
	#	screen -R
	
	#13-2-2019 limiter gewijzigd backup duurt vaak te lang
	#Bandbreedte in Rosmalen is uitgebreid van 30Mb naar 50Mb verwacht dat we dit wel kunnen hebben.
	#5000 = 5Kb/s
	#BWLIMIT=5120
	BWLIMIT=15000
	#Er bestaan DRIE soorten weekend jobs.
	#Van Aalsmeer naar Rosmalen
	#Van Rosmalen naar Aalsmeer
	#Apart de Q: en S: driveletters in Rosmalen naar Aalsmeer
	#Elke van deze jobs staren we op een andere dag.
	case ${DAYNAME[0]} in	
		"5vrijdag")
			NAGHost=Weekend-S_Q_Drive
			JOBLOGFILE=$BASEDIR/$NAGHost.txt
			log="Start backup Content & Software" ; fn_JobLOG ; fn_CentralLOG
			rsync --bwlimit=$BWLIMIT -tvzr -e ssh --delete --exclude-from /backup/script/weekend-content.exclude root@QR-Backup:/backup/data-Vrijdag/ /backup/R/data-Vrijdag >> $JOBLOGFILE
			rc=$?
			fn_weekendbckstatusmelding
			log="End backup Content & Software, Rsync exit code $rc" ; fn_JobLOG; fn_CentralLOG
			log="**********************************************************************************" ; fn_CentralLOG
			;;
		#"6zaterdag")
		"3woensdag")
			#van Rosmalen naar Aalsmeer
			NAGHost=Weekend-ToAalsmeer
			JOBLOGFILE=$BASEDIR/$NAGHost.txt

			log="Start backup naar Aalsmeer" : fn_JobLOG ; fn_CentralLOG
			mv /backup/R/6zaterdag /backup/R/6zaterdag3
			mv /backup/R/6zaterdag2 /backup/R/6zaterdag
			mv /backup/R/6zaterdag3 /backup/R/6zaterdag2
			log="rsync --bwlimit=$BWLIMIT -tvzr -e ssh --delete --exclude-from /backup/script/weekend-ToAalsmeer.exclude root@QR-Backup:/backup/R/6zaterdag/ /backup/R/6zaterdag" ; fn_CentralLOG
			rsync --bwlimit=$BWLIMIT -tvzr -e ssh --delete --exclude-from /backup/script/weekend-ToAalsmeer.exclude root@QR-Backup:/backup/R/6zaterdag/ /backup/R/6zaterdag >> $JOBLOGFILE
			rc=$?
			fn_weekendbckstatusmelding
			log="End backup naar Aalsmeer, Rsync exit code $rc" ; fn_JobLOG ; fn_CentralLOG
			log="**********************************************************************************" ; fn_CentralLOG
		;;
		"7zondag")
			#Aalsmeer naar Rosmalen
			NAGHost=Weekend-ToRosmalen
			JOBLOGFILE=$BASEDIR/$NAGHost.txt

			log="**********************************************************************************" ; fn_CentralLOG
			log="Start backup naar Rosmalen" ;fn_JobLOG ; fn_CentralLOG
			BESTAND=$BASEDIR/tijdelijk-weekend.txt				
			echo "#!/bin/sh" > $BESTAND
			echo 'mv /backup/A/6zaterdag /backup/A/6zaterdag3' >> $BESTAND
			echo 'mv /backup/A/6zaterdag2 /backup/A/6zaterdag' >> $BESTAND
			echo 'mv /backup/A/6zaterdag3 /backup/A/6zaterdag2' >> $BESTAND
			ssh root@qr-backup 'bash -s' < $BESTAND
			rm $BESTAND
		
			rsync --bwlimit=$BWLIMIT -tvzr -e ssh --delete --exclude-from /backup/script/weekend-ToRosmalen.exclude /backup/A/6zaterdag/ root@QR-Backup:/backup/A/6zaterdag >> $JOBLOGFILE
			rc=$?
			fn_weekendbckstatusmelding
			log="End backup naar Rosmalen, Rsync exit code $rc" ; fn_JobLOG ; fn_CentralLOG
			log="**********************************************************************************" ; fn_CentralLOG
			;;
		*)
			log="GEEN weekend dag dus NIKS EXTRA doen" ; fn_CentralLOG
			log="**********************************************************************************" ; fn_CentralLOG
		;;
	esac
fi
