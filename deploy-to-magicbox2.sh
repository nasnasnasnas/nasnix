ssh root@stream.szpunar.cloud "sudo umount -l /mnt/nzbdav; sudo umount -l /mnt/zurg"

sudo nixos-rebuild switch --flake .#magicbox2 --target-host root@stream.szpunar.cloud --use-substitutes --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= --option extra-substituters https://install.determinate.systems --show-trace