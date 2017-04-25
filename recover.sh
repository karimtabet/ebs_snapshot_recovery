#!/bin/bash

set -e

# IN PARAMS
RECOVERY_INSTANCE_ID=
SNAPSHOT_VOLUME_ID=

echo "Gathering information about the instance"
BLOCK_DEVICE_MAPPING=`aws ec2 describe-instance-attribute --instance-id ${RECOVERY_INSTANCE_ID} --attribute blockDeviceMapping`
DEVICE_NAME=`echo ${BLOCK_DEVICE_MAPPING} | jq '.BlockDeviceMappings[0].DeviceName' | tr -d '"'`
OLD_VOLUME_ID=`echo ${BLOCK_DEVICE_MAPPING} | jq '.BlockDeviceMappings[0].Ebs.VolumeId' | tr -d '"'`
AVAILABILITY_ZONE=`aws ec2 describe-instances --filters "Name=instance-id,Values='${RECOVERY_INSTANCE_ID}'" | jq '.Reservations[0].Instances[0].Placement.AvailabilityZone' | tr -d '"'`
LATEST_SNAPSHOT_ID=`aws ec2 describe-snapshots --filter "Name=volume-id,Values='${SNAPSHOT_VOLUME_ID}'" | jq '.[]|max_by(.StartTime)|.SnapshotId' | tr -d '"'`
echo "Found instance ${RECOVERY_INSTANCE_ID} in ${AVAILABILITY_ZONE} has volume ${OLD_VOLUME_ID} on device ${DEVICE_NAME}"

echo "Creating new volume from snapshot ${LATEST_SNAPSHOT_ID}"
NEW_VOLUME_ID=`aws ec2 create-volume --region eu-west-1 --availability-zone ${AVAILABILITY_ZONE} --snapshot-id ${LATEST_SNAPSHOT_ID} | jq '.VolumeId' | tr -d '"'`
echo "Created new volume ${NEW_VOLUME_ID}"

aws ec2 wait volume-available --volume-ids $NEW_VOLUME_ID

echo "Stopping the instance"
aws ec2 stop-instances --instance-ids $RECOVERY_INSTANCE_ID

aws ec2 wait instance-stopped --instance-ids $RECOVERY_INSTANCE_ID

echo "Detaching current volume"
aws ec2 detach-volume --volume-id $OLD_VOLUME_ID --instance-id $RECOVERY_INSTANCE_ID

aws ec2 wait volume-available --volume-ids $OLD_VOLUME_ID

echo "Attaching new volume"
aws ec2 attach-volume --volume-id $NEW_VOLUME_ID --instance-id $RECOVERY_INSTANCE_ID --device $DEVICE_NAME

aws ec2 wait volume-in-use --volume-ids $NEW_VOLUME_ID

echo "Starting the instance"
aws ec2 start-instances --instance-ids $RECOVERY_INSTANCE_ID
