# How to set up WSL 2 for docker
1. Follow [this guide](https://docs.microsoft.com/en-us/windows/wsl/install-win10) to install WSL 2.
1. Open the distro in the terminal and install `nginx`
1. Create a `dev/tools` folder in you home directory and add the files from scripts

# Add new project
1. `sudo ./add-site.sh example.local,example2.local 35001`