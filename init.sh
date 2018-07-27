#!/bin/bash

if ! ls $PWD | grep -q $(basename "$0"); then
  echo "You have to run this script right in the directory where it is."
  exit 1
fi

SRC_HOME=$PWD
DEV_HOME=~/development
GIT_USER="Don Draper"
GIT_EMAIL="donoldfashioned@gmail.com"

RED='\033[31m'
CYAN='\033[36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

function check_and_install {
  if dpkg -s $1 &> /dev/null; then
    echo "$1 is already installed."
  else
    sudo apt install -y $1
  fi
}

function chef_install_or_upgrade {

  # bash init.sh chef_install_or_upgrade cookbooks

  files_to_ignore=".*\.git|.*\.log|.*\.yml|.*\.lock\.json|data_bags|resource_factory"

  echo $files_to_ignore

  while read DIR OPS FILE < <(inotifywait -r -q -e modify,create $1); do

    echo $DIR$FILE | egrep -q "$files_to_ignore"
    result=$?

    if [ $result -ne 0 ]; then
      echo -en "$(date +"[%m-%d_%H:%M:%S]")\t$DIR\t\t\t$OPS\t\t$FILE"
      echo

      echo "$DIR $OPS $FILE"

      # cd `echo $DIR | awk -F '/' '{print $1"/"$2}'`
      cd cookbooks/showme

      if [ -f *.lock.json ]; then
        chef update
      else
        chef install
      fi

      kitchen converge --log-level=debug --color
      # kitchen converge --log-level=debug --color
      echo

      cd -
      #tree 2> /dev/null
      echo "----------------------------------------------------------------"
      echo; echo
    fi

  done

}

function go_build_install {

  # bash init.sh go_build_install src

  while read DIR OPS FILE < <(inotifywait -r -q -e modify,create $1); do

    byobu select-pane -t go_auto_runs:.1
    # when it is a test code
    if echo $FILE | egrep -q "_test\.go$"; then
      clear
      echo -en "$(date +"[%m-%d_%H:%M:%S]")\t$DIR\t\t$OPS\t$FILE"
      echo

      echo "$DIR $OPS $FILE"

      echo -e "${CYAN}Go testing..${NC}"
      go test `echo $DIR | sed 's/^src\/\(.*\)\/$/\1/g'`
      if [ $? -eq 0 ]; then
        echo -e "${CYAN}Testing has been succeeded..${NC}"; echo
        echo
      else
        echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"; echo
        echo -e "${RED}${BOLD}Testing has been failed..${NC}"; echo
        echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"; echo
        echo
      fi

      #tree src pkg
      echo "----------------------------------------------------------------"
      echo; echo
    elif echo $FILE | egrep -q "\.go$"; then
      clear
      echo -en "$(date +"[%m-%d_%H:%M:%S]")\t$DIR\t\t$OPS\t$FILE"
      echo

      echo "$DIR $OPS $FILE"

      echo -e "${CYAN}Go building..${NC}"

      if echo $DIR | grep -q 'gostudy'; then
        go install github.com/itisnotdone/gostudy
      else
        echo "go install `echo $DIR | sed 's/^src\/\(.*\)\/$/\1/g'`"
        go install `echo $DIR | sed 's/^src\/\(.*\)\/$/\1/g'`
        # echo "go install github.com/itisnotdone/gostudy"
        # go install github.com/itisnotdone/gostudy
      fi
      if [ $? -eq 0 ]; then
        echo -e "${CYAN}Building has been succeeded..${NC}"; echo
        echo

        # byobu select-window -t go_auto_runs:main
        byobu select-pane -t go_auto_runs:.0

        if grep -q 'pry.Pry()' $DIR$FILE; then
          byobu-tmux send-keys -t go_auto_runs:main "go-pry run $DIR$FILE" "Enter"
          sleep 3 # need to wait since go-pry re-create the source file triggering inotifywait
        else

          if echo $DIR | grep -q 'gostudy'; then
            byobu-tmux send-keys -t go_auto_runs:main "clear" "Enter"
            byobu-tmux send-keys -t go_auto_runs:main "gostudy" "Enter"
          elif echo $DIR | grep -q 'easeovs'; then
            byobu-tmux send-keys -t go_auto_runs:main "clear" "Enter"
            byobu-tmux send-keys -t go_auto_runs:main "sudo easeovs create --config ~/go/src/github.com/itisnotdone/easeovs/sample.yml" "Enter"
            sleep 5
            byobu-tmux send-keys -t go_auto_runs:main "sudo easeovs destroy --config ~/go/src/github.com/itisnotdone/easeovs/sample.yml"
            #byobu-tmux send-keys -t go_auto_runs:main "easeovs generate --config $GOPATH/src/github.com/itisnotdone/easeovs/sample.yml --host-id 2" "Enter"
          else
            thecmd=`echo $DIR | sed 's/^.*\/\(.*\)\//\1/g'`
            byobu-tmux send-keys -t go_auto_runs:main "clear" "Enter"
            byobu-tmux send-keys -t go_auto_runs:main "$thecmd" "Enter"
          fi

        fi

      else
        echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"; echo
        echo -e "${RED}${BOLD}Building has been failed..${NC}"; echo
        echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"; echo
        echo
      fi

      tree bin pkg/linux_amd64/github.com/itisnotdone
      #tree src pkg
      echo "----------------------------------------------------------------"
      echo; echo
    fi

    byobu select-pane -t go_auto_runs:.1
  done

}

# function go_run {
# 
#   # bash init.sh go_run bin
# 
#   while read DIR OPS FILE < <(inotifywait -r -q -e modify,create $1); do
# 
#     clear
#     echo -en "$(date +"[%m-%d_%H:%M:%S]")\t$DIR\t\t$OPS\t$FILE"
#     echo
# 
#     echo "$DIR $OPS $FILE"
#     echo
# 
#     `echo $FILE | sed 's/\(^.*\)-go-tmp-umask/\1/g'`
#     # go-pry run src/github.com/itisnotdone/gostudy/main.go
#     # go run src/github.com/itisnotdone/gostudy/main.go
# 
#     #tree bin
#     echo "----------------------------------------------------------------"
#     echo; echo
# 
#   done
# 
# }


############################################################################################
# For initializing development environment
############################################################################################

GEM_HOME=~/.chefdk/gem/ruby/*/gems
function provision_ruby_projects {
  cd $GEM_HOME
  gems=$(ls)
  for app in maas-client gogetit kitchen-gogetkitchen; do
    if ! echo "$gems" | egrep "$app$"; then
      get_github_project $app
    fi
    rm -rf $app-*
    ln -fns $PWD/$app $PWD/$app-`gem list | grep $app | awk '{print $2}' | tr -d '()'`
  done

  if ! echo "$gems" | egrep "hyperkit$"; then
    git clone https://github.com/jeffshantz/hyperkit.git
  fi
  rm -rf hyperkit-*
  ln -fns $PWD/hyperkit $PWD/hyperkit-`gem list | grep hyperkit | awk '{print $2}' | tr -d '()'`
}

COOKBOOK_HOME=$DEV_HOME/tournant/cookbooks
function provision_chef_projects {
  cd $COOKBOOK_HOME
  for cb in init_desktop base maaster nrm resource_bowl; do
    get_github_project $cb
  done
}

function get_github_project {
  git clone https://github.com/itisnotdone/$1.git
  echo "[user]" >> $1/.git/config
  echo "  name = $GIT_USER" >> $1/.git/config
  echo "  email = $GIT_EMAIL" >> $1/.git/config
}

function provision_sessions {

  check_and_install inotify-tools

  cd $SRC_HOME

  # cookbooks
  byobu-tmux new-session -d -s tournant -n main
  byobu-tmux new-window -n cmd -t tournant
  byobu-tmux new-window -n data_bag -t tournant
  byobu-tmux send-keys -t tournant:data_bag "cd data_bags" "Enter"
  byobu-tmux new-session -d -s kitchen_auto_runs -n main
  byobu-tmux send-keys -t kitchen_auto_runs:main "bash init.sh chef_install_or_upgrade cookbooks" "Enter"

  for CB in $(ls cookbooks);
  do
    byobu-tmux new-window -n $CB -t tournant
    byobu-tmux send-keys -t tournant:$CB "cd cookbooks/$CB" "Enter"
    byobu-tmux new-window -n "$CB"_test -t tournant
    byobu-tmux send-keys -t tournant:"$CB"_test "cd cookbooks/$CB" "Enter"
  done

  # maas-client
  byobu-tmux new-session -d -s maas-client -n dev
  byobu-tmux send-keys -t maas-client:dev "cd $GEM_HOME/maas-client" "Enter"
  byobu-tmux new-window -n cmd -t maas-client
  byobu-tmux send-keys -t maas-client:cmd "cd $GEM_HOME/maas-client" "Enter"

  # # hyperkit
  # byobu-tmux new-session -d -s hyperkit -n dev
  # byobu-tmux send-keys -t hyperkit:dev "cd $GEM_HOME/hyperkit" "Enter"
  # byobu-tmux new-window -n cmd -t hyperkit
  # byobu-tmux send-keys -t hyperkit:cmd "cd $GEM_HOME/hyperkit" "Enter"

  # gogetit
  byobu-tmux new-session -d -s gogetit -n dev
  byobu-tmux send-keys -t gogetit:dev "cd $GEM_HOME/gogetit" "Enter"
  byobu-tmux new-window -n cmd -t gogetit
  byobu-tmux send-keys -t gogetit:cmd "cd $GEM_HOME/gogetit" "Enter"

  # kitchen-gogetkitchen
  byobu-tmux new-session -d -s kitchen-gogetkitchen -n dev
  byobu-tmux send-keys -t kitchen-gogetkitchen:dev "cd $GEM_HOME/kitchen-gogetkitchen" "Enter"
  byobu-tmux new-window -n cmd -t kitchen-gogetkitchen
  byobu-tmux send-keys -t kitchen-gogetkitchen:cmd "cd $GEM_HOME/kitchen-gogetkitchen" "Enter"

  # # mydocs
  # byobu-tmux new-session -d -s mydocs -n doc
  # byobu-tmux send-keys -t mydocs:doc "cd $DEV_HOME/mydocs" "Enter"

  # # mydotfile
  # byobu-tmux new-session -d -s mydotfile -n dev
  # byobu-tmux send-keys -t mydotfile:dev "cd ~/.vim/bundle/mydotfile" "Enter"


  # zero
  byobu-tmux new-session -d -s zero -n dev
  byobu-tmux send-keys -t zero:dev "cd $PWD/zero" "Enter"
  byobu-tmux new-window -n cmd -t zero
  byobu-tmux send-keys -t zero:cmd "cd $PWD/zero" "Enter"

  # go
  byobu-tmux new-session -d -s go -n dev

  # easeovs
  byobu-tmux send-keys -t go:dev "cd $GOPATH/src/github.com/itisnotdone/easeovs" "Enter"
  byobu-tmux new-window -n dev_cmd -t go
  byobu-tmux send-keys -t go:dev_cmd "cd $GOPATH/src/github.com/itisnotdone/easeovs" "Enter"

  # gostudy
  byobu-tmux new-window -n gostudy -t go
  byobu-tmux send-keys -t go:gostudy "cd $GOPATH/src/github.com/itisnotdone/gostudy" "Enter"
  byobu-tmux new-window -a -n gostudy_cmd -t go
  byobu-tmux send-keys -t go:gostudy_cmd "cd $GOPATH/src/github.com/itisnotdone/gostudy" "Enter"

  # # go auto_runs
  # byobu-tmux new-session -d -s go_auto_runs -n main
  # byobu-tmux send-keys -t go_auto_runs:main "cd $GOPATH" "Enter"
  # byobu-tmux split-window -h -t go_auto_runs:main
  # byobu-tmux send-keys -t go_auto_runs:main "cd $GOPATH" "Enter"
  # byobu-tmux send-keys -t go_auto_runs:main "bash init.sh go_build_install src" "Enter"

}

function propagate_shared_dirs {
  # re-generate symbolic links
  cd $SRC_HOME

  for cookbooks in `ls -d cookbooks/*/ | sed 's/\(.*\)\/$/\1/g'`; do \
    for target_dir in data_bags; do \
      if ! `ls -d $cookbooks/*/ | sed 's/\(.*\)\/$/\1/g' | grep $target_dir`; then \
        echo "Symbolic linking $cookbooks"; \
        bash -xc "ln -fns $PWD/$target_dir $PWD/$cookbooks/$target_dir"; \
        ls -l $PWD/$cookbooks/$target_dir; \
      fi; \
    done; \
  done
  ln -s ~/development/tournant/init.sh $GOPATH/init.sh

}

function link_for_zero {

  cd $SRC_HOME
  SOURCE=$PWD
  TARGET=$PWD/zero

  for THINGS in cookbooks data_bags; do
    ln -fns $SOURCE/$THINGS $TARGET/$THINGS
  done

}

function rebuild_default_image {
  # bash init.sh rebuild_default_image
  remote_name=don-lxd
  image_name=ubuntu-16.04-chef
  container_name=default-image

  echo "lxc image delete $remote_name:$image_name"
  lxc image delete $remote_name:$image_name
  echo "lxc start $remote_name:$container_name"
  lxc start $remote_name:$container_name

  echo "Make chages on the container."
  echo "This will be waiting for you until done."
  echo;echo
  wait_until_available $container_name
  ssh $container_name

  while true; do
    read -p "Do you think it's done changing? " yn
    case $yn in
      [Yy]* ) break;;
      * ) echo "Please answer Y or y.";;
    esac
  done

  ssh $container_name "> .bash_history"

  echo "lxc stop $remote_name:$container_name"
  lxc stop $remote_name:$container_name
  echo "lxc publish --verbose $remote_name:$container_name $remote_name: --alias $image_name"
  lxc publish --verbose $remote_name:$container_name $remote_name: --alias $image_name
}

function wait_until_available {
  while ! ping -c 1 -i 1 $1; do
    echo "$1 seems not available now.."
    sleep 1
  done
}

if [ $# -eq 0 ]; then
  echo "Available commands are as follow."; \
  for func in \
    provision_ruby_projects \
    provision_chef_projects \
    propagate_shared_dirs \
    provision_sessions \
    rebuild_default_image \
    link_for_zero \
    ; do \
    echo "bash $(basename "$0") $func"; \
  done
else
  $1 $2 $3 $4 $5
fi
