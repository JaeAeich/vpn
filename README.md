# VPN Management Script

This script is designed to manage OpenVPN connections on an EC2 instance. It
starts and stops an EC2 instance running an OpenVPN server, updates the OpenVPN
client configuration with the new public IP, and establishes a VPN connection.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
  - [.vpnrc File](#vpnrc-file)
- [License](#license)

## Requirements

- Bash (version 4.0 or higher)
- AWS CLI configured with necessary permissions
- OpenVPN 3 CLI (`openvpn3`)
- A running EC2 instance tagged with `Name=openvpn`
  - Use free OpenVPN AMIs from the AWS Marketplace
  - Free tier-eligible EC2 instance type (e.g., `t2.micro`)
- The `.vpnrc` file for storing user credentials

## Installation

- **Clone the repository**:

```sh
git clone https://github.com/jaeaeich/vpn.git
```

- **Move the script and dependencies**:

```sh
mv vpn-manager/vpn.sh ~/bin/vpn/
chmod +x ~/bin/vpn/vpn.sh
```

- **Make the script available as a command**:

```sh
echo 'export PATH="$HOME/bin/vpn:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

If you use `zsh`, `fish` or other shells, modify the appropriate shell
configuration.

## Usage

To start the VPN connection:

```sh
vpn
```

This will start the EC2 instance, update the OpenVPN client configuration, and
establish a VPN connection.

## Configuration

### .vpnrc File

The `.vpnrc` file stores your VPN credentials and other configuration settings.
The script looks for the `.vpnrc` file in the following locations:

1. `$HOME/.config/vpn/.vpnrc` (preferred location)
2. `$HOME/.vpnrc` (fallback location)

#### Example `.vpnrc` File:

```sh
INSTANCE_NAME="openvpn" # Replace with your EC2 instance name
USERNAME="openvpn" # Replace with your OpenVPN username
PASSWORD="your_password" # Replace with your OpenVPN password
REGION="ap-southeast-1"  # Replace with your desired AWS region
PROFILE_NAME="client.ovpn" # Replace with your OpenVPN profile name
```

Ensure that your `.vpnrc` file is secure and only accessible by you:

```sh
chmod 600 ~/.config/vpn/.vpnrc
```

## License

This script is licensed under the GNU General Public License v3.0. You are free
to redistribute and modify the script under the terms of this license.

For more details, see the [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html) file.
