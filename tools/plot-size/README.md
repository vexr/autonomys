# Autonomys Tools

## plot-size.sh
### Shell script to determine ideal plot size. This script assumes you will use the entire drive for the plot. XFS and EXT4 are currently supported.

### Usage:
```bash
chmod +x plot-size.sh
./plot-size.sh [<disk path>]
```

### Examples:
```bash
./plot-size.sh
./plot-size.sh /dev/sdb
```
#### Notice: This script will prompt for elevated permissions. This is necessary to query tune2fs for ext4 and xfs_info for xfs file systems to obtain drive space information.