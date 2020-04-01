#!/bin/bash

doShowContext()
{  
  echo "   "
  echo "=== context =================="
  echo "CURRENT_DIR=$CURRENT_DIR"
  echo "SCRIPT_NAME=$SCRIPT_NAME"

  echo "EVER=$EVER"
  echo "ELIST=$ELIST"
  echo "QTVER=$QTVER"
  echo "QTMODULES=$QTMODULES"
  echo "PROJECT NAME=$PROJ_NAME"
  echo "VERBOSE=$VERBOSE"

  echo "POSITIONAL=${POSITIONAL[@]}"
  echo "=============================="
  echo "   "
}

doSetupEmscripten() {
  DOWNLOAD=YES
  if [[ -d "emsdk" ]]; then
    echo "  "
    read -p "Directory emsdk already exists. Do you want to delete it?   " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # do dangerous stuff
        rm -fr emsdk
    else 
      DOWNLOAD=NO
    fi 
  fi

  # Get the emsdk repo
  if [[ $DOWNLOAD == YES ]]; then
    q="--quiet"
    if [[ $VERBOSE == YES ]]; then
      echo "  "
      echo "################################################"
      echo "# Downloading and installing emscripten"
      echo "################################################"
      echo "  "
      q=""
    fi
    git clone ${q} https://github.com/emscripten-core/emsdk.git
  fi

  if [[ $ELIST == YES ]]; then
    #to see the different versions we can install
    emsdk/emsdk list
    exit 0
  else
    echo "Installing the Emscripten version $EVER ."
    echo "For a list of available versions use "
    emsdk/emsdk install $EVER
    
    # Make the "latest" SDK "active" for the current user. (writes ~/.emscripten file)
    emsdk/emsdk activate $EVER
    
    # Activate PATH and other environment variables in the current terminal
    source emsdk/emsdk_env.sh
  fi
}

doSetupQt()
{ 
  DOWNLOAD=YES
  if [[ -d "qt5" ]]; then
    echo "  "
    read -p "Directory qt5 already exists. Do you want to delete it?   " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # do dangerous stuff
        rm -fr qt5
    else 
      DOWNLOAD=NO
    fi 
  fi

  # Get the qt repo
  if [[ $DOWNLOAD == YES ]]; then
    q="--quiet"
    if [[ $VERBOSE == YES ]]; then
      echo "  "
      echo "################################################"
      echo "# Downloading and building Qt"
      echo "################################################"
      echo "  "
      q=""
    fi
    git clone ${q} -b $QTVER https://code.qt.io/qt/qt5.git
  fi  

  if [[ -z $QTMODULES ]]; then
    qt5/init-repository -f
  else
    qt5/init-repository -f --module-subset=$QTMODULES
  fi

  #create a shadow build folder
  CREATE_SHADOW_DIR=YES
  if [[ -d "qt5_shadow" ]]; then
    echo "  " 
    read -p "Shadow Build directory qt5_shadow already exists. Do you want to delete it?   " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # do dangerous stuff
        rm -fr qt5_shadow
    else 
      CREATE_SHADOW_DIR=NO
      exit 1
    fi 
  fi

  if [[ $CREATE_SHADOW_DIR == YES ]]; then
    mkdir qt5_shadow
  fi
  qt5/configure -opensource -confirm-license -xplatform wasm-emscripten -feature-thread -nomake examples -no-dbus -no-ssl -prefix qt5_shadow/
  
  MODULES=$(echo $QTMODULES | tr "," "\n")
  MODULES_STR=""
  for mod in $MODULES
  do
    MODULES_STR+=" module-"$mod 
    echo mod=$mod
    echo str=$MODULES_STR
  done
  cd qt5_shadow
  make $MODULES_STR -j$NCORES
  make install -j$NCORES
}

doBuildQtProject()
{
  if [[ $VERBOSE == YES ]]; then
    echo " "
    echo "###############################################"
    echo "# Build your qt project"
    echo "###############################################"
    echo "  "
  fi
  cd $PROJ_NAME
  ../qt5_shadow/qtbase/bin/qmake
  make
  cd ..
}

doCheckLocally()
{
  if [[ $VERBOSE == YES ]]; then
    echo "  "
    echo "################################################"
    echo "# Serve your compiled code "
    echo "################################################"
    echo "  "
  fi
  open -a "Google Chrome" http://localhost:8000/${PROJ_NAME}.html

  python3 -m http.server

}

#start array
CURRENT_DIR=`pwd`
SCRIPT_NAME=$(basename "$0")

EVER=latest
ELIST=NO
QTVER="5.14.0"
QTMODULES=""
PROJ_NAME=""
VERBOSE=YES
NCORES=1
POSITIONAL=()
SHOWHELP=NO

while [[ $# -gt 0 ]]
do
  key="$1"
  case $key in
      -h|--help)
      SHOWHELP=YES
      shift
      ;;
      -ev|--emscriptenVersion)
      EVER="$2"
      shift # past argument
      shift # past value
      ;;
      -elist|--emscriptenListVersions)
      ELIST=YES
      shift # past argument
      ;;
      -Qtv|--QtVersion)
      QTVER="$2"
      shift # past argument
      shift # past value
      ;;
      -QtMods|--QtModules)
      QTMODULES=("$2")
      shift # past argument
      shift # past value
      ;;
      -NCores|--NumCores)
      NCORES=("$2")
      shift # past argument
      shift # past value
      ;;
      --QtProjectName)
      PROJ_NAME="$2"
      shift # past argument
      shift # past value
      ;;
      -s|--silent)
      VERBOSE=NO
      shift # past argument
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

if [[ $SHOWHELP == YES ]]; then
  echo " "
  echo "./setup.sh -ev 1.39.11 -Qtv 5.15 -QtModules qtbase,qtcharts,qtsvg"
  echo " "
  exit 1
fi

if [[ $VERBOSE == YES ]]; then
  echo "  "
  echo "Running $SCRIPT_NAME from $CURRENT_DIR"
  echo "This tool will download, configure, compile and serve wasm for a qt project"
  echo "By juangpc.  "
  echo "             "
fi


if [[ $VERBOSE == YES ]]; then
  doShowContext
fi

doSetupEmscripten
doSetupQt
doBuildQtProject
doCheckLocally





EOF