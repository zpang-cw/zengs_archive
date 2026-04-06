# ZSH SHELL FUNCTIONS

# DESCRIBE A GBX NODE'S RACK BASED ON NODE's BMN NAME/SSERIAL
bmn_rack() {

  if [ $# -lt 1 ]; then

    echo '[Usage]: bmns_rack <-a|-d|-t> <bmn1> ... <bmnN>'
    return 1

  fi

  local terse_flag
  local all_flag
  local devices_flag

  zparseopts -E -D  -- \
    a=all_flag \
    b=bmns_flag \
    d=devices_flag \
    r=racks_flag \
    || return 1

# ONLY ALLOW USER TO SPECIFY ONE OPTION EACH CALL

  local oCounter=0

  for o in all_flag bmns_flag devices_flag racks_flag; do if (( ${(P)#o} )); then (( oCounter++ )) fi; done

  if (( oCounter > 1 )); then

    echo '[Error]: only specify one option at a time :)'
    return 1

  fi

# ISOLATE INPUT POSITIONAL ARGUMENTS (`zparseopts` ALREADY TRIMS OFF OPTIONS/FLAGS INPUT ARGS)
  local positionalArgs=( "$@" )
# REMOVE DUPLICATE POSITIONAL ARGS
  typeset -U positionalArgs
# TO-DO - IF `positionalArgs` HAS LENGTH oF 0/EMPTY


  if [[ -n "$bmns_flag" ]]; then

     for (( i = 1; i <= ${#positionalArgs}; i++ )); do

       echo "[${positionalArgs[i]}]"; echo '---------------------------------------------------------------------------'
       k get bmn ${positionalArgs[i]} -o json | jq -r '.metadata.labels."ds.coreweave.com/physical-topology.rack-name"' | xargs -I% cwctl describe rack % --sections=bmns

     done

  elif [[ -n "$all_flag" ]]; then

     for (( i = 1; i <= ${#positionalArgs}; i++ )); do

       echo "[${positionalArgs[i]}]"; echo '---------------------------------------------------------------------------'
       k get bmn ${positionalArgs[i]} -o json | jq -r '.metadata.labels."ds.coreweave.com/physical-topology.rack-name"' | xargs -I% cwctl describe rack %

     done

  elif [[ -n "$devices_flag" ]]; then

     for (( i = 1; i <= ${#positionalArgs}; i++ )); do

       echo "[${positionalArgs[i]}]"; echo '---------------------------------------------------------------------------'
       k get bmn ${positionalArgs[i]} -o json | jq -r '.metadata.labels."ds.coreweave.com/physical-topology.rack-name"' | xargs -I% cwctl describe rack % --sections=devices

     done

  elif [[ -n "$racks_flag" ]]; then

     for (( i = 1; i <= ${#positionalArgs}; i++ )); do

       echo "[${positionalArgs[i]}]"; echo '---------------------------------------------------------------------------'
       k get bmn ${positionalArgs[i]} -o json | jq -r '.metadata.labels."ds.coreweave.com/physical-topology.rack-name"'

     done

  else

# DEFAULT (-b)
     for (( i = 1; i <= ${#positionalArgs}; i++ )); do

       echo "[${positionalArgs[i]}]"; echo '---------------------------------------------------------------------------'
       k get bmn ${positionalArgs[i]} -o json | jq -r '.metadata.labels."ds.coreweave.com/physical-topology.rack-name"' | xargs -I% cwctl describe rack % --sections=bmns

     done

  fi

}


# 'ALIAS' TO `k describe bmn <bmn>`
# TO-DO: ADD FLAGS FOR `-o json` AND `-o yaml`
kdbmn() {

  if [ $# -lt 1 ]; then
    echo '[Usage]: kd_bmns <bmn...>, short-hand for k describe <bmn>'
    return 1

  fi

  k describe bmn $@

}

# 'ALIAS' TO `k describe device <nvlink/powershelf/cdu/>`
kddvc() {

  if [ $# -lt 1 ]; then
    echo '[Usage]: kddvc <device1...deviceN>, short-hand for k describe <device>'
    return 1

  fi

  k describe device $@

}

# 'ALIAS' TO `k get device <nvlink/powershelf/cdu/>`
# TO-DO - add `-s` option for status
# k get device -o yaml <device> | yq '.status'
kgdvc() {

  if [ $# -lt 1 ]; then
    echo '[Usage]: kgdvc <device1...deviceN>, short-hand for k get <device>'
    return 1

  fi

  k get device $@

}


# RETRIEVE A GBX RACK'S LIST OF BMN NAMES
# TO-DO - GET A RACK'S NODE SERIALS VIA `-s OR --serial` FLAG
racknodes() {

  if [ $# -lt 1 ]; then
    echo '[Usage]: racknodes <rack>'
    return 1

  elif [ $# -gt 1 ]; then
    echo '[Error] this function only takes 1 input argument :)'
    return 1

  fi

  cwctl describe rack $1 --sections=bmns | sed -e '1,/----/ d' | awk "{print \$1}"

}



# FIX ONBOARD BMNS THAT DID NOT RECEIVE THEIR DEFAULT NODEPROFILE ("nodeprofile toggle")
nodeprofile_tg() {

  if [ $# -lt 1 ]; then

    echo '[Usage]: nodeprofile_tg <bmn1> ... <bmnN>'
    return 1

  fi

#  echo "$@"
#  for i in "${argv[@]}"; do

  for i in $@; do

#    echo "$i"
    cwctl flcc node --disable-cks $i; sleep 0.5;  cwctl flcc node $i -p "" ; sleep 0.5; cwctl flcc node $i --enable-cks
#
  done

}


# GET LATEST NODE STATE MESSAGES/ALERTS
# Default - last 3 state transition
# TO-DO - option flag for: 1. ALL transitions 2. last N transitions
bmn_status() {

  if [ $# -lt 1 ]; then

    echo '[Usage]: bmn_status <bmn1> ... <bmnN>'
    return 1

  fi

  for i in $@; do

    echo "[$i]"
    echo '--------'
    kubectl get bmn -o yaml $i | yq '.status.reportedNodeInfo.status.conditions[0,1,2]'

  done

}
