# LineageOS and AAOS building

_For Linux only._

Automated building of [LineageOS](https://wiki.lineageos.org/) and [AAOS (Android Automotive OS)](https://developers.google.com/cars/design/automotive-os).

## Requirements

Make sure you meet the following conditions:

- A 64-bit environment
- At least 250GB of free disk space to check out the code and an extra 150GB to build it
- At least 16GB of available RAM
- Ubuntu 14.04 or higher

Also if you want to build AAOS, make sure that your device is either **gts4lv** or **gts4lvwifi**.

## Execution

To download and execute the script, run the commands below:

```bash
cd WORKING_DIRECTORY
wget https://github.com/Knoddleboy/LineageOS-AAOS_build/blob/main/lineageos-aaos_build.sh
chmod +x lineageos-aaos_build.sh
sudo ./lineageos-aaos_build.sh
```
