# wailmer
An attempt at making the Spheal/hb-appstore building process more painless.

# Usage

Export the platform you want to compile for; e.x:
```
# replace switch with wii, wiiu, all, etc.
export PLATFORM=switch
```

Then run these commands:
```
wget https://raw.githubusercontent.com/TraceEntertains/wailmer-ubuntu/main/wailmer-ubuntu.sh
chmod +x ./wailmer-ubuntu.sh
sudo ./wailmer-ubuntu.sh
```

Then you have (hopefully) successfully built hb-appstore!
