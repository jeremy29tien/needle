#!/bin/bash
#This script automatically runs PIVUS{sampleNumber}_ROP/07c_viral/PIVUS{sampleNumber}_Aligned--07c_viral_output.bam files through needle for the specified range of PIVUS samples.

#Options: -range for running on all PIVUS, -sample for running on just one sample

if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Please use the '-s' flag to specify the PIVUS sample, or the '-a' flag to run on multiple samples."
    exit 1
fi

while getopts ":rs:" opt; do
  case ${opt} in
    s )
      sample=$OPTARG
      ;;
    r )
      sample=""
      read -p 'Starting PIVUS sample in Needle run: ' sampleStart
      read -p 'Ending PIVUS sample in Needle run: ' sampleEnd
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
        exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument." 1>&2
        exit 1
      ;;
  esac
done
shift $((OPTIND -1))

#running on multiple samples
if [ -z "$sample" ]; then

   startNumber=${sampleStart:5}
   #echo "$(($startNumber + 1))"
   endNumber=${sampleEnd:5}
   number=$startNumber
   while [ "$number" != $(printf %03d "$((10#$endNumber + 1))") ]
   do
     sampleName=$(printf PIVUS%03d "$((10#$number))")
#     if [ ${#number} -eq 1 ]
#     then      
#       sampleName=PIVUS00$number
#     fi
#     if [ ${#number} -eq 2 ]
#     then
#        sampleName=PIVUS0$number
#     fi
#     if [ ${#number} -eq 3 ]
#     then
#        sampleName=PIVUS$number
#     fi
     echo *-------------*
     echo ${sampleName}
     echo *-------------*
     /users/j29tien/needle/needle.sh /users/j29tien/ROP/results/${sampleName}_ROP/07c_viral/${sampleName}_Aligned--07c_viral_output.bam /users/j29tien/needle/results/${sampleName}.needle
     number=$(printf %03d "$((10#$number + 1))")
   done
else
        ##For now, just use these to run one sample at a time.
        #place these commands in loop to loop through all PIVUS
	/users/j29tien/needle/needle.sh /users/j29tien/ROP/results/${sample}_ROP/07c_viral/${sample}_Aligned--07c_viral_output.bam /users/j29tien/needle/results/${sample}.needle
fi
