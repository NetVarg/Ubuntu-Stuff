# Update snap store programs

sudo snap refresh --list|grep -Eq "Name\s+Version"
exitCode=$?

if [ $exitCode -eq 0 ]
then

  sudo snap refresh --list

  read -n1 -p "Update/Refresh snap? [y,n]" doit 
  case $doit in  
    y|Y)
      echo
      ps -e | grep snap-store >/dev/null 2>&1
      ec=$?
      if [ $ec -eq 0 ]
      then
        killall snap-store >/dev/null 2>&1
      fi
      sudo snap refresh ;;

    *)
      echo
      echo "Nothings done" ;; 
  esac
fi
