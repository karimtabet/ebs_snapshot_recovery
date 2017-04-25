# EBS Snapshot Recovery
This repo contains a script that takes an EC2 instance ID and a snapshotted volume ID and recovers the latest snapshot of that volume on to the given EC2 instance.

### Dependencies
- aws cli
- jq

### Parameters
Under `IN PARAMS`, fill in your `RECOVERY_INSTANCE_ID` and your `SNAPSHOT_VOLUME_ID`.

### Usage
The script should first be made executable
```sh
chmod +x recover.sh
```
Then you can simply run
```sh
./recover.sh
```

### TODO
- Option to create a new EC2 instance instead of provide ID of existing one
- Pass in parameters as shell arguments

