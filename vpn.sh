#!/bin/env bash
#
# vpn.sh - A script to manage OpenVPN connections on ec2
#
# Copyright (C) 2024 Javed Habib (jaeaeich) <jh4official@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

# Define the AWS region
REGION="ap-southeast-1"

# Define the path to the OpenVPN client config filters
PROFILE_NAME="client.ovpn"
CURR_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PATH_TO_OVPN_CLIENT_CONFIG="$CURR_DIR/$PROFILE_NAME"

# Check if the OpenVPN client config file exists
if [ ! -f "$PATH_TO_OVPN_CLIENT_CONFIG" ]; then
  echo "Error: OpenVPN client config file not found at $PATH_TO_OVPN_CLIENT_CONFIG."
  exit 1
fi

# Get the instance ID for the instance with the name 'openvpn'
INSTANCE_ID=$(aws ec2 describe-instances \
  --region "$REGION" \
  --filters "Name=tag:Name,Values=openvpn" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

# If instance is already runnning, inform and quit
STATE=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --filters "Name=tag:Name,Values=openvpn" \
  --query "Reservations[].Instances[].State.Name" \
  --output text \
  --region $REGION)

if [[ "$STATE" == "running" ]]; then
  echo "Did you forget to stop EC2? ooh the bill!!!"
  echo "Shutting down OpenVPN server..."

  # Attempt to stop the instance
  STOP_OUTPUT="$(aws ec2 stop-instances --instance-ids $INSTANCE_ID --output text --region $REGION)"
  STOP_STATUS="$(echo $STOP_OUTPUT | grep 'stopping')"

  if [ -n "$STOP_STATUS" ]; then
    echo "Stop request successful. The instance is now in the process of stopping."
  else
    echo "Error: Failed to send stop request. Response: $STOP_OUTPUT"
    exit 1
  fi

  echo "Waiting for the instance to stop..."
  while [[ "$STATE" != "stopped" ]]; do
    sleep 10
    STATE=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --filters "Name=tag:Name,Values=openvpn" \
      --query "Reservations[].Instances[].State.Name" \
      --output text \
      --region $REGION)
    echo "Current instance state: $STATE"
  done

  echo "The instance has been successfully stopped."
  exit 0
fi

if [[ "$STATE" != "stopped" ]]; then
  echo "State is: $STATE"
  exit 1
fi

aws ec2 start-instances \
  --instance-ids $INSTANCE_ID \
  --output text \
  --region $REGION

# Check if INSTANCE_ID is empty
if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" == "None" ]; then
  echo "Error: No instance ID found for the instance with name 'openvpn'."
  exit 1
fi

echo "Instance ID: $INSTANCE_ID"

# Wait for the EC2 instance to boot up
echo "Waiting for the instance to start..."
while [[ "$STATE" != "running" ]]; do
  sleep 10
  STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --filters "Name=tag:Name,Values=openvpn" \
    --query "Reservations[].Instances[].State.Name" \
    --output text \
    --region $REGION)
  echo "Current instance state: $STATE"
done

# Get the public IP address of the instance
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances \
  --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text)

# Check if INSTANCE_PUBLIC_IP is empty
if [ -z "$INSTANCE_PUBLIC_IP" ] || [ "$INSTANCE_PUBLIC_IP" == "None" ] || [ "$INSTANCE_PUBLIC_IP" == " " ]; then
  echo "Error: No public IP address found for instance ID $INSTANCE_ID."
  exit 1
fi

echo "Public IP Address: $INSTANCE_PUBLIC_IP"

# Extract the previous IP from the client config file
PREV_IP=$(grep remote "$PATH_TO_OVPN_CLIENT_CONFIG" | head -n 1 | awk '{print $2}')

# Check if PREV_IP was found
if [ -z "$PREV_IP" ] || ["$PREV_IP" == " " ]; then
  echo "Error: No previous IP address found in the OpenVPN client config file."
  exit 1
fi

# Replace the previous IP with the new IP in the config file
sed -i "s/$PREV_IP/$INSTANCE_PUBLIC_IP/g" "$PATH_TO_OVPN_CLIENT_CONFIG"

# Start the OpenVPN session using the updated config
# Note: Replace USERNAME and PASSWORD with actual value
printf "$USERNAME\n$PASSWORD\n" | openvpn3 session-start --config "$PATH_TO_OVPN_CLIENT_CONFIG"

echo "OpenVPN session started successfully."
