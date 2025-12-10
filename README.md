# VergeOS Packer - Debian 13 Cloud Image Builder

Automated VM creation on VergeOS using HashiCorp Packer and Debian 13 cloud images.

## Quick Start

### Prerequisites
- VergeOS cluster with **API v4** access (required for the Packer plugin)
- Debian 13 cloud image uploaded to VergeOS (qcow2 format)
- Packer installed (`apt install packer` or download from [packer.io](https://www.packer.io/downloads))

### Installation

1. **Clone this repository**
```bash
git clone <your-repo>
cd vergeos-packer-public
```

2. **Initialize Packer**
```bash
packer init build.pkr.hcl
```

3. **Configure variables**
```bash
cp variables.pkrvars.hcl.example variables.pkrvars.hcl
vim variables.pkrvars.hcl
```

Update these values:
- `vergeio_endpoint` - Your VergeOS server IP/hostname
- `vergeio_username` - VergeOS username
- `vergeio_password` - VergeOS password
- `network_id` - Network ID to attach VMs to
- `debian_cloud_image_id` - File ID of your Debian 13 qcow2 cloud image

4. **Build**
```bash
packer build -var-file="variables.pkrvars.hcl" build.pkr.hcl
```

## What This Does

This Packer configuration:
1. Creates a new VM in VergeOS
2. Imports a Debian 13 cloud image (qcow2) as the system disk
3. Configures the VM with cloud-init
4. Powers on the VM
5. Waits for SSH connectivity
6. Runs provisioning scripts to:
   - Update system packages
   - Install common tools (git, vim, htop, curl, wget)
7. Shuts down the VM gracefully

The result is a ready-to-use Debian 13 VM template.

## Default Credentials

After the build completes:
- **Username**: `debian`
- **Password**: `packer123` (set via cloud-init)

Both users have sudo access with NOPASSWD.

## Finding Your Cloud Image ID

To find the File ID of your Debian cloud image in VergeOS:

```bash
curl -k -u "username:password" \
  "https://your-vergeio-server/api/v4/files" -s | \
  jq '.[] | select(.name | contains("debian")) | {key: ."$key", name: .name}'
```

Look for files like `debian-13-generic-amd64-*.qcow2`.

## Customization

### Cloud-Init Configuration

Edit `cloud-init/cloud-user-data.yml` to customize:
- Users and passwords
- Installed packages
- System configuration
- Timezone, locale, etc.

### Provisioning Scripts

Edit the `build` block in `build.pkr.hcl` to add custom provisioning steps.

## Why Cloud Images?

This project uses **Debian cloud images** instead of ISO installation or template cloning because:

✅ **Pre-built and bootable** - No installation required  
✅ **Cloud-init ready** - Designed for automation  
✅ **Fast** - Build completes in ~2 minutes  
✅ **Reliable** - Bootloader and system properly configured  

## Troubleshooting

**Build fails with "name already in use":**
- Delete the existing VM in VergeOS UI
- Or change the `name` variable in the configuration

**SSH timeout:**
- Verify the network ID is correct
- Check that the VM can reach the network
- Ensure cloud-init completed (check VM console)

**Can't login:**
- Wait 1-2 minutes for cloud-init to complete
- Try username `debian` with password `packer123`
- Check VM console for cloud-init logs

## Files

- `build.pkr.hcl` - Main Packer configuration
- `variables.pkrvars.hcl.example` - Example variables file
- `cloud-init/cloud-user-data.yml` - Cloud-init configuration
- `cloud-init/meta-data.yml` - Instance metadata
- `.gitignore` - Prevents committing credentials

## Security

⚠️ **Never commit `variables.pkrvars.hcl`** - It contains your credentials!

The `.gitignore` file is configured to exclude this file automatically.

## License

MIT License - Feel free to use and modify!

## Contributing

Pull requests welcome! Please test your changes before submitting.

## Resources

- [VergeOS Packer Plugin](https://github.com/verge-io/packer-plugin-vergeio)
- [HashiCorp Packer Documentation](https://www.packer.io/docs)
- [Debian Cloud Images](https://cloud.debian.org/images/cloud/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
