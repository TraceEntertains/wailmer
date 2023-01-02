# wailmer
An attempt at making the hb-appstore building process more painless.
Almost all original code made by the 4TU/fortheusers team.

# Usage

Export the platform you want to compile for; e.x:
```
# replace switch with wii, wiiu, all, etc.
export PLATFORM=switch
```

Then run these commands:
```
wget https://raw.githubusercontent.com/TraceEntertains/wailmer/main/wailmer.sh
chmod +x ./wailmer.sh
sudo ./wailmer.sh
```

Then you have (hopefully) successfully built hb-appstore!
