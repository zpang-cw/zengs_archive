#!/bin/zsh

set -e
set -u
set -o pipefail


#### FUNC DEFINITIONS

# USAGE GUIDE

show_manual() {

cat << EOF

vackjra - a CLI tool purposed for sending/retrying bmn provisioning states across various FLCC workflows (compatible with GBX nodes currently)

[USAGE]

vackjra [-h|--help] [-s|--send] <workflow_steps> [-f|--failed] <failed_steps> [-rt|--retry|-rtpc|--retry-by-powercycle|-rtpd|--retry-by-powerdrain] <rack0 .. rackN>


[WORKFLOW STATES]

-nv | --node-vaultify
-nz | --node-zap
-dv | --dpu-vaultify
-dz | --dpu-zap
-zs | --zap-seatrial
-nz | --node-zap
-fd | --fielddiag
-l10 | --l10-test
-l10p | --l10-test-loop
-l11fd | --gb200-l11-fielddiag
-l11rb | --node-l11-reboot
-l11 | --l11-test
-l12s | --l12-seatrial
-l12 | --l12-test
-l12p | --l12-test-loop
-pc | --power-cycle
-pd | --power-drain
-pv | --provision


[EXAMPLES]

# SEND A BMN TO A WORKFLOW STATE (START PROVISIONING WORKFLOW)
vackjra -s -pv <bmn>

# SHOW ALL FAILED BMNS IN A RACK
vackjra -f <rack>

# SHOW ALL NODE-ZAP FAILS
vackjra -f -nz <rack>

# SEND BACK ALL NODE-ZAPS
vackjra -f -nz -rt <rack>

# SEND BACK ALL NODE-ZAPS VIA POWER-CYCLE
vackjra -f -nz -rtpc <rack>

# SEND BACK ALL NODE-ZAPS VIA POWER-DRAIN
vackjra -f -nz -rtpd <rack>

# SEND BACK ALL FAILS VIA POWER-CYCLE (NOTE - THIS CURRENTLY REQUIRES MANUAL CONFIRMATION FOR EVERY ACTION!)
vackjra -f -rtpc <rack>

# SEND BACK ALL FAILS VIA POWER-DRAIN (NOTE - THIS CURRENTLY REQUIRES MANUAL CONFIRMATION FOR EVERY ACTION!)
vackjra -f -rtpd <rack>

EOF
}

# CMDS USED TO GATHER STATUS OF RACK NODES
bmn_query () {

  if [ $# -lt 1 ]; then return 1; fi

  for i in $@; do
    cwctl describe rack --sections=bmns $i | sed -e '1,/----/ d'
  done

}

# TO-DO
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

# FUNCTION FOR USER CONFIRMATION
confirm() {

  local prompt="${1:-Proceed?}"
  local reply
  read "?$prompt (Y/n): " reply < /dev/tty
  [[ "$reply:l" == y || "$reply:l" == yes ]]

}

# FUNCTION AS SHORT-HAND GBX FLCC PROVISION WORKFLOW
gbx_provision() {

  cwctl flcc node -w gb200-rack-provision-v4 "$@"

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
local flag_pv=false
local flag_v=false
local flag_rt=false
local flag_rtpc=false
local flag_rtpd=false
local flag_dr=false
local flag_h=false
local flag_s=false
local positionalArgs=()
local optionsCounter=0


# IF NO ARGUMENTS GIVEN - SHOW USAGE GUIDE
if [ $# -lt 1 ]; then

    show_manual
    return 1

fi


# START PARSING OPTION FLAGS
while [[ $# -gt 0 ]]; do

  case $1 in

    -b|--bmn|--bmns)
      flag_b='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -nv|--nvlink|--nvlinks)
      flag_nv='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -c|--cdu|--cdus)
      flag_cdu='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -p|--ps|--powershelves)
      flag_ps='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -n|--name)
      flag_n='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -d|--deviceslot)
      flag_d='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -sn|--serial)
      flag_s='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -f|--failed)
      flag_f='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -s|--send)
      flag_s='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -pv|--provision)
      flag_pv='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -nv|--node-vaultify) 
      flag_nv='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -dv|--dpu-vaultify) 
      flag_dv='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -dz|--dpu-zap) 
      flag_dz='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -zs|--zap-seatrial) 
      flag_zs='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -nz|--node-zap) 
      flag_nz='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -fd|--fielddiag) 
      flag_fd='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l10|-l10-test|--l10-test) 
      flag_l10='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l10p|-l10-test-loop|--l10-test-loop) 
      flag_l10p='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l11fd|-l11-fielddiag|--l11-fielddiag|--gb200-l11-fielddiag) 
      flag_l11fd='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l11rb|-node-l11-reboot|--node-l11-reboot) 
      flag_l11rb='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l11|-l11-test|--l11-test) 
      flag_l11='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l12s|-l12-seatrial|--l12-seatrial) 
      flag_l12s='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l12|-l12-test|--l12-test) 
      flag_l12='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -l12p|-ll2-test-loop|--l12-test-loop) 
      flag_l12p='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -pc|--power-cycle)
      flag_pc='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -pd|--power-drain)
      flag_pd='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -rt|--retry|--send-back)
      flag_rt='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -rtpc|--retry-by-powercycle)
      flag_rtpc='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -rtpd|--retry-by-powerdrain)
      flag_rtpd='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -dr|--dryrun)
      flag_dr='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -v|--verbose)
      flag_v='true'; optionsCounter=$(( optionsCounter + 1 ))
      ;;
    -h|--help)
      flag_h='true'; optionsCounter=$(( optionsCounter + 1 ))
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


# OUTPUT USAGE MANUAL IF `-h/--help` OPTIONS WERE PASSED
if [[ "$flag_h" == 'true' ]]; then

    show_manual
    return 0

fi


# THROW ERROR IF NO POSITIONAL ARGS GIVEN
if [[ -z $positionalArgs ]]
then
	echo '[Error]: no positional arguments given :('
	return 1
fi


# REMOVE DUPLICATES IN POSITIONAL ARGS
typeset -U positionalArgs


# TO-DO: ADDITIONAL SANITY CHECKS OF PASSED POSITIONAL ARGS
# - CATCH SPECIAL CHARACTERS
# - MIN & MAX LENGTH
# - CANNOT BE PURE DIGITS OR ALPHA - ENFORCE ALPHANUMERICAL


#### PARSE FOR WORKFLOW STATES TO SEND BMNS TO

if [[ "$flag_s" == 'true' ]]; then

  for i in ${positionalArgs[@]}; do

    if [[ "$flag_pv" == 'true' ]]; then

      gbx_provision $i

    fi
    return 0

  done

fi


#### PARSE FOR PROVISIONING WORKFLOW FAILURES

# TO-DO - OPTION TO ACTION ON MULTIPLE SPECIFIED FAILURES
# REFERENCE SYNTAX - if  [[ ( "$flag_b" == 'true'  && "$flag_n" == 'true' ) || "$flag_b" == 'true' ]]; then


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
      elif [[ "$flag_rtpc" == 'true' ]]; then
        bmn_query $i | awk '$9 == "dpu-vaultify" && $10 == "fail" {print $1}' | while read -r line; do bmn_pc $line; done
      elif [[ "$flag_rtpd" == 'true' ]]; then
        bmn_query $i | awk '$9 == "dpu-vaultify" && $10 == "fail" {print $1}' | while read -r line; do bmn_pd $line; done
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

# TO-DO - UNIQUE RETRY CMDS FOR RE-RETRYING L11FD
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

# LIST ALL FAILED WORKFLOW STEPS IN A RACK -- OPTION TO POWER-CYCLE OR POWER-DRAIN ALL FAILS -- ASKS USER FOR CONFIRMATION
      if [[ "$flag_rtpc" == 'true' ]]; then

        bmn_query $i | awk '$10 == "fail" {print $1}' | while read -r line; do

          echo "[$line]"
          kubectl get bmn $line

          echo '[CHECK-POINT]'
          if confirm "Run 'cwctl flcc node --one-off -w instant-power-cycle $line'"; then
            bmn_pc $line
          else
            echo "[$line] one-off power-cycle CANCELLED"
          fi

        done

      elif [[ "$flag_rtpd" == 'true' ]]; then

        bmn_query $i | awk '$10 == "fail" {print $1}' | while read -r line; do

          echo "[$line]"
          kubectl get bmn $line

          echo '[CHECK-POINT]'
          if confirm "Run 'cwctl flcc node --one-off -w instant-power-drain $line'"; then
            bmn_pd $line
          else
            echo "[$line] one-off power-drain CANCELLED"
          fi

        done

      else
        bmn_query $i | awk '$10 == "fail" {print $0}'
      fi


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
