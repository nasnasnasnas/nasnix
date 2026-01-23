ssh root@stream.szpunar.cloud "sudo umount -l /mnt/nzbdav; sudo umount -l /mnt/zurg"

sudo nixos-rebuild switch --flake .#magicbox2 --target-host root@stream.szpunar.cloud --use-substitutes