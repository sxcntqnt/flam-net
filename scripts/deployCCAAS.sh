#!/bin/bash

. ../utils/cli-utils.sh
. ../utils/env.sh
. ../utils/ccutils.sh

FABRIC_CFG_PATH=$PWD/../config/

export PATH=${PWD}/bin:$PATH

function printHelp() {
    println "Usage: "
    println "  chaincode [mode: deploy/invoke]"
    println "  chaincode deploy - Deploy a chaincode"
    println "  chaincode [deploy-org/deploy-ccaas/deploy-peer]"
    println "    chaincode deploy-org - Deploy a chaincode on an organization"
    println "      chaincode deploy-org [--cc-name <cc name>] [--cc-path <cc path>] [--cc-version <cc version>]"
    println "                           [--cc-sequence <cc sequence>] [--org <organization name>] [--channel-name <channel name>]"
    println "        chaincode deploy-org --help (print this message)"
    println "          --cc-name <cc name> - Chaincode name"
    println "          --cc-path <cc path> - Chaincode path"
    println "          --cc-version <cc version> - Chaincode version"
    println "          --cc-sequence <cc sequence> - Chaincode sequence"
    println "          --org <organization name> - Name of the organization where the chaincode will be installed (could be more than one)"
    println "          --channel-name <channel name> - Name of the channel where the chaincode will be installed"
    println "          Examples:"
    println "            chaincode deploy-org --cc-name chaincode --cc-path ../chaincode/ --cc-version 1.1 --cc-sequence 1 --org org1 --channel-name channel01"
    println "    chaincode deploy-peer - Deploy a chaincode on a peer"
    println "      chaincode deploy-peer [--cc-name <cc name>] [--peer <peer ID>] [--org <organization name>] [--channel-name <channel name>]"
    println "        chaincode deploy-peer --help (print this message)"
    println "          --cc-name <cc name> - Chaincode name"
    println "          --peer <peer ID> - Peer ID"
    println "          --org <organization name> - Name of the organization where the chaincode will be installed (could be more than one)"
    println "          --channel-name <channel name> - Name of the channel where the chaincode will be installed"
    println "          Examples:"
    println "            chaincode deploy-peer --cc-name chaincode --peer 1 --org org1 --channel-name channel01"
    println "  chaincode invoke - Invoke a chaincode method"
    println "    chaincode invoke [--cc-name <cc name>] [--cc-args <cc arguments>] [--user-name <username>]"
    println "                     [--org <organization name>] [--channel-name <channel name>]"
    println "      chaincode invoke --help (print this message)"
    println "        --cc-name <cc name> - Chaincode name"
    println "        --cc-args <cc path> - Chaincode arguments with the method name that will be invoked"
    println "        --user-name <username> - User name of the invoker user"
    println "        --org <organization name> - Name of the organization where the chaincode is installed"
    println "        --channel-name <channel name> - Name of the channel where the chaincode is installed"
    println "        Examples:"
    println "          chaincode invoke --cc-name chaincode --cc-args '{\"Args\":[\"methodName\",\"arg1\"]}' --user-name user --org org1 --channel-name channel101"
    println "    chaincode deploy-ccaas - Deploy a chaincode as a service"
    println "      chaincode deploy-ccaas [-ccn <cc name>][-ccl <cc language>] [-ccv <cc version>] [-ccs <cc sequence>] [-ccp <cc path>] [-cci <cc init func>]"
    println "        chaincode deploy-ccas --help (print this message)"
    println "    -c <channel name> - Name of channel to deploy chaincode to"
    println "    -ccn <name> - Chaincode name."
    println "    -ccv <version>  - Chaincode version. 1.0 (default), v2, version3.x, etc"
    println "    -ccs <sequence>  -  Chaincode definition sequence.  Must be auto (default) or an integer, 1 , 2, 3, etc"
    println "    -ccp <path>  - File path to the chaincode. (used to find the dockerfile for building the docker image only)"
    println "    -ccep <policy>  - (Optional) Chaincode endorsement policy using signature policy syntax. The default policy requires an endorsement from Org1 and Org2"
    println "    -cccg <collection-config>  - (Optional) File path to private data collections configuration file"
    println "    -cci <fcn name>  - (Optional) Name of chaincode initialization function. When a function is provided, the execution of init will be requested and the function will be invoked."
    println "    -ccaasdocker <true|false>  - (Optional) Default is true; the chaincode docker image will be built and containers started automatically. Set to false to control this manually"
    println
    println "    -h - Print this message"
    println
    println " Possible Mode and flag combinations"
    println "   \033[0;32mdeployCC\033[0m -ccn -ccv -ccs -ccp -cci -r -d -verbose"
    println
    println " Examples:"
    println "   bc-network.sh deployCCAAS  -ccn basicj -ccp ../asset-transfer-basic/chaincode-java"
    println "   bc-network.sh deployCCAAS  -ccn basict -ccp ../asset-transfer-basic/chaincode-typescript -ccaasdocker false"
}

#!/bin/bash

# Function to build chaincode
function buildCC() {
    # Set default values if arguments are not provided
    CC_NAME=$1
    CHANNEL_NAME=${2:-"NA"}
    CC_SRC_PATH=$3
    CCAAS_DOCKER_RUN=${4:-"true"}
    CC_VERSION=${5:-"0.0.0.1"}
    CC_SEQUENCE=${6:-"0.0.0.1"}
    CC_INIT_FCN=${7:-"NA"}
    CC_END_POLICY=${8:-"NA"}
    CC_COLL_CONFIG=${9:-"NA"}
    DELAY=${10:-"3"}
    MAX_RETRY=${11:-"5"}
    VERBOSE=${12:-"True"}
    CC_SRC_LANGUAGE=${13:-"go"}
    CCAAS_SERVER_PORT=9999

    # Set container CLI and compose CLI
    : ${CONTAINER_CLI:="docker"}
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}

    # Print execution details
    println "executing with the following"
    println "- CC_NAME: ${C_GREEN}${CC_NAME}${C_RESET}"
    println "- CC_SRC_PATH: ${C_GREEN}${CC_SRC_PATH}${C_RESET}"
    println "- CC_SRC_LANGUAGE: ${C_GREEN}${CC_SRC_LANGUAGE}${C_RESET}"
    println "- CC_VERSION: ${C_GREEN}${CC_VERSION}${C_RESET}"
    println "- CHANNEL_NAME: ${C_GREEN}${CHANNEL_NAME}${C_RESET}"
    println "- CC_SEQUENCE: ${C_GREEN}${CC_SEQUENCE}${C_RESET}"
    println "- CC_END_POLICY: ${C_GREEN}${CC_END_POLICY}${C_RESET}"
    println "- CC_COLL_CONFIG: ${C_GREEN}${CC_COLL_CONFIG}${C_RESET}"
    println "- CC_INIT_FCN: ${C_GREEN}${CC_INIT_FCN}${C_RESET}"
    println "- DELAY: ${C_GREEN}${DELAY}${C_RESET}"
    println "- MAX_RETRY: ${C_GREEN}${MAX_RETRY}${C_RESET}"
    println "- VERBOSE: ${C_GREEN}${VERBOSE}${C_RESET}"

    # Convert CC_SRC_LANGUAGE to lowercase
    CC_SRC_LANGUAGE=$(echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:])

    # Language-specific preparation
    case $CC_SRC_LANGUAGE in
        go)
            CC_RUNTIME_LANGUAGE=golang
            infoln "Vendoring Go dependencies at $CC_SRC_PATH"
            pushd $CC_SRC_PATH
            GO111MODULE=on go mod vendor
            popd
            successln "Finished vendoring Go dependencies"
            ;;
        java)
            CC_RUNTIME_LANGUAGE=java
            infoln "Compiling Java code..."
            pushd $CC_SRC_PATH
            ./gradlew installDist
            popd
            successln "Finished compiling Java code"
            CC_SRC_PATH=$CC_SRC_PATH/build/install/$CC_NAME
            ;;
        javascript | typescript)
            CC_RUNTIME_LANGUAGE=node
            if [ "$CC_SRC_LANGUAGE" = "typescript" ]; then
                infoln "Compiling TypeScript code into JavaScript..."
                pushd $CC_SRC_PATH
                npm install
                npm run build
                popd
                successln "Finished compiling TypeScript code into JavaScript"
            fi
            ;;
        *)
            fatalln "The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script. Supported chaincode languages are: go, java, javascript, and typescript"
            exit 1
            ;;
    esac

    # Set INIT_REQUIRED flag
    INIT_REQUIRED="--init-required"
    if [ "$CC_INIT_FCN" = "NA" ]; then
        INIT_REQUIRED=""
    fi

    # Set CC_END_POLICY and CC_COLL_CONFIG flags
    CC_END_POLICY="--signature-policy ${CC_END_POLICY:-}"
    CC_COLL_CONFIG="--collections-config ${CC_COLL_CONFIG:-}"

    # Validate chaincode arguments
    if [ -z "$CC_NAME" ] || [ "$CC_NAME" = "NA" ]; then
        fatalln "No chaincode name was provided. Valid call example: ./network.sh deployCCAS -ccn basic -ccp ../asset-transfer-basic/chaincode-go "
    elif [ -z "$CC_SRC_PATH" ] || [ "$CC_SRC_PATH" = "NA" ]; then
        fatalln "No chaincode path was provided. Valid call example: ./network.sh deployCCAS -ccn basic -ccp ../asset-transfer-basic/chaincode-go "
    elif [ ! -d "$CC_SRC_PATH" ]; then
        fatalln "Path to chaincode does not exist. Please provide a different path."
    fi

    # Set CC_END_POLICY and CC_COLL_CONFIG flags
    CC_END_POLICY="--signature-policy ${CC_END_POLICY:-}"
    CC_COLL_CONFIG="--collections-config ${CC_COLL_CONFIG:-}"
}

packageChaincode() {

  address="{{.peername}}_${CC_NAME}_ccaas:${CCAAS_SERVER_PORT}"
  prefix=$(basename "$0")
  tempdir=$(mktemp -d -t "$prefix.XXXXXXXX") || error_exit "Error creating temporary directory"
  label=${CC_NAME}_${CC_VERSION}
  mkdir -p "$tempdir/src"

cat > "$tempdir/src/connection.json" <<CONN_EOF
{
  "address": "${address}",
  "dial_timeout": "10s",
  "tls_required": false
}
CONN_EOF

   mkdir -p "$tempdir/pkg"

cat << METADATA-EOF > "$tempdir/pkg/metadata.json"
{
    "type": "ccaas",
    "label": "$label"
}
METADATA-EOF

    tar -C "$tempdir/src" -czf "$tempdir/pkg/code.tar.gz" .
    tar -C "$tempdir/pkg" -czf "$CC_NAME.tar.gz" metadata.json code.tar.gz
    rm -Rf "$tempdir"

    PACKAGE_ID=$(peer lifecycle chaincode calculatepackageid ${CC_NAME}.tar.gz)
  
    successln "Chaincode is packaged  ${address}"
}

buildDockerImages() {
  . ../utils/cli-utils.sh

  # if set don't build - useful when you want to debug yourself
  if [ "$CCAAS_DOCKER_RUN" = "true" ]; then
    # build the docker container
    infoln "Building Chaincode-as-a-Service docker image '${CC_NAME}' '${CC_SRC_PATH}'"
    infoln "This may take several minutes..."
    set -x
    ${CONTAINER_CLI} build -f $CC_SRC_PATH/Dockerfile -t ${CC_NAME}_ccaas_image:latest --build-arg CC_SERVER_PORT=9999 $CC_SRC_PATH >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Docker build of chaincode-as-a-service container failed"
    successln "Docker image '${CC_NAME}_ccaas_image:latest' built succesfully"
  else
    infoln "Not building docker image; this the command we would have run"
    infoln "   ${CONTAINER_CLI} build -f $CC_SRC_PATH/Dockerfile -t ${CC_NAME}_ccaas_image:latest --build-arg CC_SERVER_PORT=9999 $CC_SRC_PATH"
  fi
}

startDockerContainer() {
  # start the docker container
  if [ "$CCAAS_DOCKER_RUN" = "true" ]; then
    infoln "Starting the Chaincode-as-a-Service docker container..."
    set -x
    ${CONTAINER_CLI} run --rm -d --name peer0org1_${CC_NAME}_ccaas  \
                  --network fabric_test \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest

    ${CONTAINER_CLI} run  --rm -d --name peer0org2_${CC_NAME}_ccaas \
                  --network fabric_test \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Failed to start the container container '${CC_NAME}_ccaas_image:latest' "
    successln "Docker container started succesfully '${CC_NAME}_ccaas_image:latest'" 
  else
  
    infoln "Not starting docker containers; these are the commands we would have run"
    infoln "    ${CONTAINER_CLI} run --rm -d --name peer0org1_${CC_NAME}_ccaas  \
                  --network fabric_test \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest"
    infoln "    ${CONTAINER_CLI} run --rm -d --name peer0org2_${CC_NAME}_ccaas  \
                  --network fabric_test \
                  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CCAAS_SERVER_PORT} \
                  -e CHAINCODE_ID=$PACKAGE_ID -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
                    ${CC_NAME}_ccaas_image:latest"

  fi
}

deployChaincode() {
    # Build the docker image
    buildDockerImages

    ## Package the chaincode
    packageChaincode

    # Install chaincode for each organization
    for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
        infoln "Installing chaincode on peer0.$ORGANIZATION..."
        installChaincode "$ORGANIZATION"
    done

    ## Query whether the chaincode is installed
    for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
        queryInstalled "$ORGANIZATION"
    done

    # Approve and check commit readiness for each organization
    for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
        approveForMyOrg "$ORGANIZATION"
        checkCommitReadiness "$ORGANIZATION" "\"${ORGANIZATION}MSP\": true"
    done

    ## Now approve also for org2
    for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
        approveForMyOrg "$ORGANIZATION"
    done

    ## Check whether the chaincode definition is ready to be committed
    ## Expect them all to have approved
    for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
        checkCommitReadiness "$ORGANIZATION" "\"${ORGANIZATION}MSP\": true"
    done

    ## Now that we know for sure all orgs have approved, commit the definition
    commitChaincodeDefinition "${ORGANIZATIONS[@]}"

    ## Query on all orgs to see that the definition committed successfully
    for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
        queryCommitted "$ORGANIZATION"
    done

    # Start the container
    startDockerContainer

    ## Invoke the chaincode - this does require that the chaincode have the 'initLedger'
    ## method defined
    if [ "$CC_INIT_FCN" = "NA" ]; then
        infoln "Chaincode initialization is not required"
    else
        for ORGANIZATION in "${ORGANIZATIONS[@]}"; do
            chaincodeInvokeInit "$ORGANIZATION"
        done
    fi
}

# Function to check if required flags are entered
checkRequiredFlags() {
    local flag_value="$1"
    local flag_name="$2"
    if [ -z "$flag_value" ]; then
        echo "Error: --$flag_name flag not entered"
        exit 1
    fi
}

# Function to initialize chaincode deployment on a peer
initChaincodePeer() {
  # Loop through arguments
  while [[ $# -ge 1 ]]; do
    key="$1"
    case $key in
    --help)
      printHelp
      exit 0
      ;;
    --cc-name)
      CC_NAME="$2"
      checkRequiredFlags "$CC_NAME" "cc-name"
      shift
      ;;
    --peer)
      PEER="$2"
      checkRequiredFlags "$PEER" "peer"
      shift
      ;;
    --channel-name)
      CHANNEL_NAME="$2"
      checkRequiredFlags "$CHANNEL_NAME" "channel-name"
      shift
      ;;
    --org)
      ORGANIZATION="$2"
      checkRequiredFlags "$ORGANIZATION" "org"
      shift
      ;;
    *)
      echo "Error: Unknown flag: $key. Use --help for more information"
      exit 1
      ;;
    esac
    shift
  done

  # Print execution details
  echo "Executing with the following"
  echo "- ORGANIZATION/S NAME/S: ${ORGANIZATION}"
  echo "- CHAINCODE NAME: ${CC_NAME}"
  echo "- PEER: ${PEER}"

  # Call function to install chaincode on the peer
  installPeerChaincode "$ORGANIZATION" "$PEER"
}

# Main function
main() {
    if [ -z "$1" ]; then
        echo "Error: No flags entered. Use --help for more information"
        exit 1
    fi

    # Loop through arguments
    while [[ $# -ge 1 ]]; do
      key="$1"
      case $key in
      --help)
        printHelp
        exit 0
        ;;
      --install-peer)
        shift
        initChaincodePeer "$@"
        exit
        ;;
      --cc-name)
        CC_NAME="$2"
        checkRequiredFlags "$CC_NAME" "cc-name"
        shift
        ;;
      --cc-path)
        CC_SRC_PATH="$2"
        checkRequiredFlags "$CC_SRC_PATH" "cc-path"
        shift
        ;;
      --cc-version)
        CC_VERSION="$2"
        checkRequiredFlags "$CC_VERSION" "cc-version"
        shift
        ;;
      --cc-sequence)
        CC_SEQUENCE="$2"
        checkRequiredFlags "$CC_SEQUENCE" "cc-sequence"
        shift
        ;;
      --channel-name)
        CHANNEL_NAME="$2"
        shift
        ;;
      --org)
        if [ -z "${ORGANIZATIONS}" ]; then
          ORGANIZATIONS=("$2")
        else
          ORGANIZATIONS+=("$2")
        fi
        shift
        ;;
      *)
        echo "Error: Unknown flag: $key. Use --help for more information"
        exit 1
        ;;
      esac
      shift
    done

    # Check if required flags are entered
    checkRequiredFlags "$ORGANIZATIONS" "org"
    checkRequiredFlags "$CC_NAME" "cc-name"
    checkRequiredFlags "$CC_SRC_PATH" "cc-path"
    checkRequiredFlags "$CC_VERSION" "cc-version"
    checkRequiredFlags "$CC_SEQUENCE" "cc-sequence"

    # Call the function to deploy chaincode
    buildCC "$CC_NAME" "$CHANNEL_NAME" "$CC_SRC_PATH" "true" "$CC_VERSION" "$CC_SEQUENCE" "NA" "NA" "MAJORITY" "3" "5" "True" "go"

    # Call the function to deploy chaincode
    deployChaincode
    # Checking the exit status of the deployment
    if [ $? -ne 0 ]; then
      fatalln "Deploying chaincode failed"
    fi

}

# Call the main function
main "$@"

