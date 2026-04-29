#!/bin/zsh

# GUARDRAILS
if [ $# -lt 1 ]; then

  echo '[Usage]: rackinfo <-b|-nv|-cdu|-ps> <-n|-d|-v|-s> <rack0...rackN>'

  echo "[Flags]:\n-b --> compute bmns/compute trays/nodes\n-nv --> nvlink switches\n-cdu --> cooling distribution units\n-ps --> power shelves\n-n --> ssname\n-s --> serial\n-d --> deviceslot\n-v --> verbose (name,deviceslot,serial)"

  return 1

fi

local flag_b=false
local flag_nv=false
local flag_cdu=false
local flag_ps=false
local flag_n=false
local flag_d=false
local flag_f=false
local flag_v=false
local flag_s=false
local positionalArgs=()
local optionsCounter=0

while [[ $# -gt 0 ]]; do

  case $1 in

    -b|--bmn|--bmns)
      flag_b='true'; (( optionsCounter++ ))
      ;;
    --nv|--nvlink|--nvlinks)
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
      flag_s='true'; (( optionsCounter++ ))
      ;;
    -f|--failed)
      flag_f='true'; (( optionsCounter++ ))
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

  echo '[Error]: no optional flags specified :('
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

#if [[ ( "$flag_b" == 'true'  && "$flag_n" == 'true' ) || "$flag_b" == 'true' ]]; then
if [[ "$flag_b" == 'true' ]]; then

  if [[ "$flag_f" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "cwctl describe rack $i --sections=bmns | sed -e '1,/----/ d' | grep fail"
    done
    return 0

  fi

  if [[ "$flag_n" == 'true' && "$flag_d" == 'true' && "$flag_s" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"NAME:.metadata.name,DEVICESLOT:,SERIAL:,BMC_IP:\""
    done

  elif [[ "$flag_n" == 'true' && "$flag_d" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"NAME:.metadata.name,DEVICESLOT:,BMC_IP:\""
    done

  elif [[ "$flag_n" == 'true' && "$flag_s" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"NAME:.metadata.name,SERIAL:,BMC_IP:\""
    done

  elif [[ "$flag_d" == 'true' && "$flag_s" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"DEVICESLOT:,SERIAL:,BMC_IP:\""
    done

  elif [[ "$flag_d" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"DEVICESLOT:,BMC_IP:\""
    done

  elif [[ "$flag_s" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "kubectl get bmns -l 'ds.coreweave.com/physical-topology.rack-name=$i' -o custom-columns=\"SERIAL:,BMC_IP:\""
    done

  elif [[ "$flag_n" == 'true' ]]; then

    for i in ${positionalArgs[@]}; do
      echo "cwctl describe rack $i --sections=bmns | sed -e '1,/----/ d' | awk \"{print \$1}\""
    done

  else

    for i in ${positionalArgs[@]}; do
      echo "cwctl describe rack $i --sections=bmns | sed -e '1,/----/ d'"
    done

  fi

fi

# TO-DO - IF CONDITIONAL HERE
#echo '[Error]: did we specify rack component? (-b/-c/-nv/-p)'; return 1
