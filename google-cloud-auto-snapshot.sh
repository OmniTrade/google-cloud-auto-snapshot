#!/bin/bash

if [ -z "${DAYS_RETENTION}" ]; then
  export DAYS_RETENTION=30
fi

# Author: Alan Fuller, Fullworks
if [ "$1" = "production" ]; then
# loop through all disks within this project  and create a snapshot
gcloud compute disks list --format='value(name,zone)'| grep -e data-production -e data-wallet-production | while read DISK_NAME ZONE; do
  gcloud compute disks snapshot $DISK_NAME --snapshot-names autogcs-${DISK_NAME:0:31}-$(date "+%Y-%m-%d-%s") --zone $ZONE
done
fi

if [ "$1" = "staging" ]; then
# loop through all disks within this project  and create a snapshot
gcloud compute disks list --format='value(name,zone)'| grep -e data-staging -e data-wallet-staging  | while read DISK_NAME ZONE; do
  gcloud compute disks snapshot $DISK_NAME --snapshot-names autogcs-${DISK_NAME:0:31}-$(date "+%Y-%m-%d-%s") --zone $ZONE
done
fi

# snapshots are incremental and dont need to be deleted, deleting snapshots will merge snapshots, so deleting doesn't loose anything
# having too many snapshots is unwiedly so this script deletes them after n days
gcloud compute snapshots list --filter="creationTimestamp<$(date -d "-${DAYS_RETENTION} days" "+%Y-%m-%d") AND name~'(autogcs.*)'" --uri | while read SNAPSHOT_URI; do
   gcloud compute snapshots delete $SNAPSHOT_URI --quiet
done

