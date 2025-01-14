#!/usr/bin/env bash

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  IMAGE_NAME
#   DESCRIPTION:  The name and tag of the Docker image. Default: 'cdalvaro/docker-salt-master:latest'.
#----------------------------------------------------------------------------------------------------------------------
export IMAGE_NAME=${IMAGE_NAME:-'cdalvaro/docker-salt-master:latest'}

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  CONTAINER_NAME
#   DESCRIPTION:  The name of the container. Default: 'salt-master'.
#----------------------------------------------------------------------------------------------------------------------
export CONTAINER_NAME=salt-master

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  PLATFORM
#   DESCRIPTION:  The platform to run the tests on. Default: the current platform.
#----------------------------------------------------------------------------------------------------------------------
export PLATFORM=${PLATFORM:-$(docker version --format='{{.Server.Os}}/{{.Server.Arch}}')}

#---  ENV VARIABLE  ---------------------------------------------------------------------------------------------------
#          NAME:  BOOTUP_WAIT_SECONDS
#   DESCRIPTION:  The number of seconds to wait for the container to boot up. Default: 60.
#----------------------------------------------------------------------------------------------------------------------
export BOOTUP_WAIT_SECONDS=${BOOTUP_WAIT_SECONDS:-60}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  cleanup
#   DESCRIPTION:  Clean up tasks.
#----------------------------------------------------------------------------------------------------------------------
function cleanup()
{
  echo "🧹 Removing ${CONTAINER_NAME} ..."
  docker container rm --force "${CONTAINER_NAME}"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  docker-exec
#   DESCRIPTION:  Execute the given command inside the container.
#----------------------------------------------------------------------------------------------------------------------
function docker-exec()
{
  docker exec "${CONTAINER_NAME}" "$@"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  docker-logs
#   DESCRIPTION:  Get the logs of the container.
#----------------------------------------------------------------------------------------------------------------------
function docker-logs()
{
  docker logs "${CONTAINER_NAME}"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  salt-run
#   DESCRIPTION:  Execute the salt-run command inside the container.
#----------------------------------------------------------------------------------------------------------------------
function salt-run()
{
  docker-exec salt-run "$@"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  salt-call
#   DESCRIPTION:  Execute the salt-call command inside the container.
#----------------------------------------------------------------------------------------------------------------------
function salt-call()
{
  docker-exec salt-call "$@"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  master_log
#   DESCRIPTION:  Print salt-master log.
#----------------------------------------------------------------------------------------------------------------------
function master_log()
{
  docker-exec cat data/logs/salt/master
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  wait_container
#   DESCRIPTION:  Wait for the container to boot up.
#----------------------------------------------------------------------------------------------------------------------
function start_container_and_wait()
{
  # shellcheck disable=SC2206
  local DOCKER_ARGS=( $@ )

  docker run --rm --detach --name "${CONTAINER_NAME}" \
  --publish 4505:4505 --publish 4506:4506 \
  --platform "${PLATFORM}" ${DOCKER_ARGS[@]} \
  "${IMAGE_NAME}" || return 1

  echo "==> Waiting ${BOOTUP_WAIT_SECONDS} seconds for the container to be ready ..."
  sleep "${BOOTUP_WAIT_SECONDS}"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  ok
#   DESCRIPTION:  Print a successfull message.
#----------------------------------------------------------------------------------------------------------------------
function ok()
{
  echo "✅ $*"
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  error
#   DESCRIPTION:  Print an error message, show the salt-master log and exit with code 1.
#----------------------------------------------------------------------------------------------------------------------
function error()
{
  echo "🔥 $*"
  master_log
  return 1
}

#---  FUNCTION  -------------------------------------------------------------------------------------------------------
#          NAME:  check_equal
#   DESCRIPTION:  Check if the given value is equal to the expected value.
#----------------------------------------------------------------------------------------------------------------------
function check_equal()
{
  local actual="$1"
  local expected="$2"
  local message="$3"

  output=$(cat <<EOF
${message}
  Expected: ${expected}
    Actual: ${actual}
EOF
)

  if [[ "${actual}" == "${expected}" ]]; then
    ok "${output}"
  else
    error "${output}"
  fi
}
