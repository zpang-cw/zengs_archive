#!/bin/zsh

#### GUARDRAILS
#set -e
set -u
set -o pipefail


#### USAGE GUIDE
# TO-DO - CONVERT USAGE OUTPUT INTO A FUNCTION
if [ $# -lt 1 ]; then

  echo '[Usage]: vackjra <-b|-nv|-cdu|-ps> <-n|-d|-v|-s> <rack0...rackN>'

  echo "[Flags]:\n-b --> compute bmns/compute trays/nodes\n-nv --> nvlink switches\n-cdu --> cooling distribution units\n-ps --> power shelves\n-n --> ssname\n-s --> serial\n-d --> deviceslot\n-v --> verbose (name,deviceslot,serial)"

  return 1

fi

#### FUNC DEFINITIONS

# CMDS USED TO GATHER STATUS OF RACK NODES
bmn_query () {

  if [ $# -lt 1 ]; then return 1; fi

  for i in $@; do
    cwctl describe rack --sections=bmns $i | sed -e '1,/----/ d'
  done

}

# CMDS USED TO GATHER STATUS OF RACK DEVICES
#dvc_query () {
#
#}

# CMDS USED FOR ONE-OFF NODE POWER-CYCLES
bmn_pc () {

  if [ $# -lt 1 ]; then return 1; fi
  cwctl flcc node --one-off -w instant-power-cycle "$@"

}

# CMDS USED FOR ONE-OFF NODE POWER-DRAINS
bmn_pd () {

  if [ $# -lt 1 ]; then return 1; fi
  cwctl flcc node --one-off -w instant-power-drain "$@"

}


# VAR DECLARATIONS
local flag_b=false
local flag_nv=false
local flag_cdu=false
local flag_ps=false
local flag_n=false
local flag_d=false
local flag_sn=false
local flag_f=false
local flag_nv=false
local flag_dv=false
local flag_dz=false
local flag_zs=false
local flag_nz=false
local flag_fd=false
local flag_l10=false
local flag_l10p=false
local flag_l11fd=false
local flag_l11rb=false
local flag_l11=false
local flag_l12s=false
local flag_l12=false
local flag_l12p=false
local flag_pc=false
local flag_pd=false
local flag_v=false
local flag_rt=false
local flag_rtpc=false
local flag_rtpd=false
local flag_dr=false
local positionalArgs=()
local optionsCounter=0

while [[ $# -gt 0 ]]; do

  case $1 in

    -b|--bmn|--bmns)
      flag_b='true'; (( optionsCounter++ ))
      ;;
    -nv|--nvlink|--nvlinks)
      flag_nv='true'; (( optionsCounter++ ))
      ;;
    -c|--cdu|--cdus)
      flag_cdu='true'; (( optionsCounter++ ))
      ;;
    -p|--ps|--powershelves)
      flag_ps='true'; (( optionsCounter++ ))
      ;;
    -n|--name)
      flag_n='true'; (( optionsCounter++ ))
      ;;
    -d|--deviceslot)
      flag_d='true'; (( optionsCounter++ ))
      ;;
    -s|--serial)
      flag_sn='true'; (( optionsCounter++ ))
      ;;
    -f|--failed)
      flag_f='true'; (( optionsCounter++ ))
      ;;
    -nv|--node-vaultify) 
      flag_nv='true'; (( optionsCounter++ ))
      ;;
    -dv|--dpu-vaultify) 
      flag_dv='true'; (( optionsCounter++ ))
      ;;
    -dz|--dpu-zap) 
      flag_dz='true'; (( optionsCounter++ ))
      ;;
    -zs|--zap-seatrial) 
      flag_zs='true'; (( optionsCounter++ ))
      ;;
    -nz|--node-zap) 
      flag_nz='true'; (( optionsCounter++ ))
      ;;
    -fd|--fielddiag) 
      flag_fd='true'; (( optionsCounter++ ))
      ;;
    -l10|-l10-test|--l10-test) 
      flag_l10='true'; (( optionsCounter++ ))
      ;;
    -l10p|-l10-test-loop|--l10-test-loop) 
      flag_l10p='true'; (( optionsCounter++ ))
      ;;
    -l11fd|-l11-fielddiag|--l11-fielddiag|--gb200-l11-fielddiag) 
      flag_l11fd='true'; (( optionsCounter++ ))
      ;;
    -l11rb|-node-l11-reboot|--node-l11-reboot) 
      flag_l11rb='true'; (( optionsCounter++ ))
      ;;
    -l11|-l11-test|--l11-test) 
      flag_l11='true'; (( optionsCounter++ ))
      ;;
    -l12s|-l12-seatrial|--l12-seatrial) 
      flag_l12s='true'; (( optionsCounter++ ))
      ;;
    -l12|-l12-test|--l12-test) 
      flag_l12='true'; (( optionsCounter++ ))
      ;;
    -l12p|-ll2-test-loop|--l12-test-loop) 
      flag_l12p='true'; (( optionsCounter++ ))
      ;;
    -pc|--power-cycle)
      flag_pc='true'; (( optionsCounter++ ))
      ;;
    -pd|--power-drain)
      flag_pd='true'; (( optionsCounter++ ))
      ;;
    -rt|--retry|--send-back)
      flag_rt='true'; (( optionsCounter++ ))
      ;;
    -rtpc|--retry-by-powercycle)
      flag_rtpc='true'; (( optionsCounter++ ))
      ;;
    -rtpd|--retry-by-powerdrain)
      flag_rtpd='true'; (( optionsCounter++ ))
      ;;
    -dr|--dryrun)
      flag_dr='true'; (( optionsCounter++ ))
      ;;
    -v|--verbose)
      flag_v='true'; (( optionsCounter++ ))
      ;;
    --)
      shift
      positionalArgs+=("$@")
      break
      ;;
    *)
      positionalArgs+=("$1")
      ;;

  esac
  shift

done

# THROW ERROR IF NO OPTIONAL ARGS GIVEN
if (( optionsCounter == 0 ))
then

  echo '[Error]: no options specified :('
  return 1

fi


# THROW ERROR IF NO POSITIONAL ARGS GIVEN
if [[ -z $positionalArgs ]]
then
	echo '[Error]: no positional arguments given :('
	return 1
fi

# REMOVE DUPLICATES
typeset -U positionalArgs

# TO-DO: SANITY CHECKS OF POSITIONAL ARGS
# - CATCH SPECIAL CHARACTERS
# - MIN & MAX LENGTH
# - CANNOT BE PURE DIGITS OR ALPHA - ENFORCE ALPHANUMERICAL

#if [[ ( "$flag_b" == 'true'  && "$flag_n" == 'true' ) || "$flag_b" == 'true' ]]; then


#### PARSE FOR PROVISIONING WORKFLOW FAILURES

if [[ "$flag_f" == 'true' ]]; then

  for i in ${positionalArgs[@]}; do

    if [[ "$flag_nv" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "node-vaultify" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s node-vaultify
      else
        bmn_query $i | awk '$9 == "node-vaultify" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_dv" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "dpu-vaultify" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s dpu-vaultify
      else
        bmn_query $i | awk '$9 == "dpu-vaultify" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_dz" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "dpu-zap" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s dpu-zap

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "dpu-zap" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "dpu-zap" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "dpu-zap" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_zs" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "zap-seatrial" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s zap-seatrial
      else
        bmn_query $i | awk '$9 == "zap-seatrial" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_nz" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "node-zap" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s node-zap

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "node-zap" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "node-zap" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "node-zap" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_fd" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "fielddiag" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s fielddiag

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "fielddiag" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "fielddiag" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "fielddiag" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_l10" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l10-test" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s l10-test

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l10-test" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l10-test" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "l10-test" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_l10p" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l10-test-loop" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-provision-v4 -s l10-test-loop

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l10-test-loop" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l10-test-loop" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "l10-test-loop" && $10 == "fail" {print $0}'
      fi

# TO-DO - UNIQUE WORKFLOW FOR RE-RETRYING L11FD
    elif [[ "$flag_l11fd" == 'true' ]]; then

      bmn_query $i | awk '$9 == "gb200-l11-fielddiag" && $10 == "fail" {print $0}'


    elif [[ "$flag_l11rb" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "node-l11-reboot" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-hpc-verification-v4 -s node-l11-reboot

      else
        bmn_query $i | awk '$9 == "node-l11-reboot" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_l11" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l11-test" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-hpc-verification-v4 -s l11-test

      else
        bmn_query $i | awk '$9 == "l11-test" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_l12s" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-seatrial" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-hpc-verification-v4 -s l12-seatrial

      else
        bmn_query $i | awk '$9 == "l12-seatrial" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_l12" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-test" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-hpc-verification-v4 -s l12-test

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-test" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-test" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "l12-test" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_l12p" == 'true' ]]; then

      if [[ "$flag_rt" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-test-loop" && $10 == "fail" {print $1}' | tr '\n' ' ' | xargs cwctl flcc node -w gb200-rack-hpc-verification-v4 -s l12-test-loop

      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-test-loop" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done

      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "l12-test-loop" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done

      else
        bmn_query $i | awk '$9 == "l12-test-loop" && $10 == "fail" {print $0}'
      fi


    elif [[ "$flag_pc" == 'true' ]]; then

      bmn_query $i | awk '$9 == "power-cycle" && $10 == "fail" {print $0}'


    elif [[ "$flag_pd" == 'true' ]]; then

      bmn_query $i | awk '$9 == "power-drain" && $10 == "fail" {print $0}'


    else

      bmn_query $i | awk '$10 == "fail" {print $0}'

    fi

  done

# GUARDRAIL - PREVENT PROCESSING OF ADDITIONAL FLAGS WHEN PARSING FOR FAILURES
  return 0

fi


##### PARSE FOR RACK NODE INFO (BMN NAME, DEVICESLOT, SERIAL, IPs)

if [[ "$flag_b" == 'true' ]]; then

# EVALUATE OPTIONS TO PRINT BMN METADATA (NAME, DEVICESLOT, SERIAL)
  if [[ "$flag_n" == 'true' && "$flag_d" == 'true' && "$flag_sn" == 'true' ]]; then

      echo '[TODO] - OUTPUT BMN NAME, DEVICESLOT, & SERIAL'

  elif [[ "$flag_n" == 'true' && "$flag_d" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      kubectl get bmn -l "ds.coreweave.com/physical-topology.rack-name=$i" --sort-by=".metadata.labels['flcc\.coreweave\.com/deviceslot']" -o custom-columns="BMN:.metadata.name,DEVICESLOT:.metadata.labels['flcc\.coreweave\.com/deviceslot']" --no-headers
#      echo "kubectl get bmn -l \"ds.coreweave.com/physical-topology.rack-name=$i\" --sort-by=\".metadata.labels['flcc\.coreweave\.com/deviceslot']\" -o custom-columns=\"BMN:.metadata.name,DEVICESLOT:.metadata.labels['flcc\.coreweave\.com/deviceslot']\" --no-headers"
    done

  elif [[ "$flag_n" == 'true' && "$flag_sn" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
#      echo "kubectl get bmn -l \"ds.coreweave.com/physical-topology.rack-name=$i\" --sort-by=\".metadata.labels['flcc\.coreweave\.com/deviceslot']\" -o custom-columns=\"BMN:.metadata.name\" --no-headers | tr '\n' ' ' | xargs cvrt b2s | tr ' ' '\n'"
      kubectl get bmn -l "ds.coreweave.com/physical-topology.rack-name=$i" --sort-by=".metadata.labels['flcc\.coreweave\.com/deviceslot']" -o custom-columns="BMN:.metadata.name" --no-headers | tr '\n' ' ' | xargs cvrt b2s | tr ' ' '\n'
    done

  elif [[ "$flag_d" == 'true' && "$flag_sn" == 'true' ]]; then

      echo '[TODO] - OUTPUT ONLY NODE DEVICESLOT & SERIAL'

  elif [[ "$flag_d" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
#      echo "kubectl get bmn -l \"ds.coreweave.com/physical-topology.rack-name=$i\" --sort-by=\".metadata.labels['flcc\.coreweave\.com/deviceslot']\" -o custom-columns=\"DEVICESLOT:.metadata.labels['flcc\.coreweave\.com/deviceslot']\" --no-headers"
      kubectl get bmn -l "ds.coreweave.com/physical-topology.rack-name=$i" --sort-by=".metadata.labels['flcc\.coreweave\.com/deviceslot']" -o custom-columns="DEVICESLOT:.metadata.labels['flcc\.coreweave\.com/deviceslot']" --no-headers 
    done

  elif [[ "$flag_sn" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
#      echo "kubectl get bmn -l \"ds.coreweave.com/physical-topology.rack-name=$i\" --sort-by=\".metadata.labels['flcc\.coreweave\.com/deviceslot']\" -o custom-columns=\"BMN:.metadata.name\" --no-headers | tr '\n' ' ' | xargs cvrt b2s | tr ' ' '\n'"
      kubectl get bmn -l "ds.coreweave.com/physical-topology.rack-name=$i" --sort-by=".metadata.labels['flcc\.coreweave\.com/deviceslot']" -o custom-columns="BMN:.metadata.name" --no-headers | tr '\n' ' ' | xargs cvrt b2s | tr ' ' '\n'
#      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"SERIAL:,BMC_IP:\""
    done

  elif [[ "$flag_n" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
#      echo "kubectl get bmn -l \"ds.coreweave.com/physical-topology.rack-name=$i\" --sort-by=\".metadata.labels['flcc\.coreweave\.com/deviceslot']\" -o custom-columns=\"BMN:.metadata.name\" --no-headers"
      kubectl get bmn -l "ds.coreweave.com/physical-topology.rack-name=$i" --sort-by=".metadata.labels['flcc\.coreweave\.com/deviceslot']" -o custom-columns="BMN:.metadata.name" --no-headers
#      echo "cwctl describe rack $i --sections=bmns | sed -e '1,/----/ d' | awk \"{print \$1}\""
#      cwctl describe rack $i --sections=bmns | sed -e '1,/----/ d' | awk "{print $1}"
    done

  else

    for i in ${positionalArgs[@]}; do
#      echo "cwctl describe rack $i --sections=bmns | sed -e '1,/----/ d'"
      bmn_query $i
    done

  fi

fi

# TO-DO - IF CONDITIONAL HERE
#echo '[Error]: did we specify rack component? (-b/-c/-nv/-p)'; return 1
