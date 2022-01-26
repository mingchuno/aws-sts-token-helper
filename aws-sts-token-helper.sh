#!/usr/bin/env bash
#
# Sample for getting temp session token from AWS STS
#
# aws --profile youriamuser sts get-session-token --duration 3600 \
# --serial-number arn:aws:iam::012345678901:mfa/user --token-code 012345
#
# Based on : https://github.com/EvidentSecurity/MFAonCLI/blob/master/aws-temp-token.sh
#
# Updated: 2020-04-09
# Author: MC Or
# Based on : https://gist.github.com/ogavrisevs/2debdcb96d3002a9cbf2

PROG_NAME=$(basename $0)

show_help(){
  echo "Usage: $PROG_NAME [-v] [-c config_file (default=.config)] -t mfa_token"
  exit 0
}

while getopts ":c:t:hv" opt; do
  case ${opt} in
    c) CONFIG_FILE=$OPTARG;;
    t) MFA_TOKEN_CODE=$OPTARG;;
    h) show_help;;
    v) verbose_mode=true;;
    \?)
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    :)
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))

if [ "$MFA_TOKEN_CODE" == "" ]; then
  echo "ERROR: Please provide a MFA token"
  show_help
  exit 1
fi
CONFIG_FILE=${CONFIG_FILE:-".config"}

if [ "$verbose_mode" = "true" ]; then echo "Using config file:$CONFIG_FILE" ; fi
if [ "$verbose_mode" = "true" ]; then echo "Using MFA token:$MFA_TOKEN_CODE" ; fi

# Main program
AWS_CLI=`which aws`

if test -f "$CONFIG_FILE"; then
  source $CONFIG_FILE
else
  echo "Config file not exist!"
  exit 1
fi

if [ $? -ne 0 ]; then
  echo "AWS CLI is not installed; exiting"
  exit 1
else
  if [ "$verbose_mode" = "true" ]; then echo "Using AWS CLI found at $AWS_CLI" ; fi
fi

if [ "$verbose_mode" = "true" ]; then
  echo "AWS-CLI Profile: $AWS_USER_PROFILE"
  echo "AWS-CLI Session token profile: $AWS_2AUTH_PROFILE"
  echo "MFA ARN: $ARN_OF_MFA"
  echo "MFA Token Code: $MFA_TOKEN_CODE"
fi

if [ "$verbose_mode" = "true" ]; then set -x ; fi
read -d=' ' AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN <<< \
  $(aws --profile $AWS_USER_PROFILE sts get-session-token \
  --duration $DURATION  \
  --serial-number $ARN_OF_MFA \
  --token-code $MFA_TOKEN_CODE \
  --output text | awk '{ print $2, $4, $5 }')

if [ "$verbose_mode" = "true" ]; then
  echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
  echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
  echo "AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"
fi

if [ -z "$AWS_SESSION_TOKEN" ]
then
  exit 1
fi
`aws --profile $AWS_2AUTH_PROFILE configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"`
`aws --profile $AWS_2AUTH_PROFILE configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"`
`aws --profile $AWS_2AUTH_PROFILE configure set aws_session_token "$AWS_SESSION_TOKEN"`
