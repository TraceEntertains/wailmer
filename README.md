# wailmer-ubuntu
An attempt at making the Spheal/hb-appstore dependency installation process more painless.

Also, only run on Ubuntu/WSL Ubuntu.
Stuff would probably go wrong if you ran this on something like msys2, arch, etc. (Debian should work though)

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
