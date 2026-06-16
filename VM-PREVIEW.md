# BoobsOS — podgląd w VM (qcow2 + QEMU/VNC)

Jak zbudować bootowalny obraz BoobsOS i odpalić go w VM z dostępem VNC/SSH.

## Stan

- ✅ Obraz OCI `boobsos:dev` zbudowany i zweryfikowany (`docker build -f Containerfile`).
- ✅ Bootowalny **qcow2** wygenerowany przez `bootc-image-builder`:
  `bib-output/qcow2/disk.qcow2` (24 GiB wirt., ~5 GiB realnie). Bootuje przez
  UEFI → GRUB „BoobsOS (Fedora Linux)".
- ✅ Konto demo w obrazie: **`boobs` / `boobs`** (grupa wheel), autologin GNOME.

## Jak odpalić VM (na hoście, NIE przez agenta)

> Sandbox agenta blokuje uruchamianie qemu jako procesu hosta. Uruchom poniższe
> **bezpośrednio w swoim terminalu na fz-vm** (lub przez `! ./run-vm.sh`).

```bash
cd /home/fzienowicz/boobsos
./run-vm.sh
```

Skrypt startuje QEMU/KVM, UEFI przez OVMF, grafika virtio. VNC i SSH nasłuchują
**tylko na adresie Tailscale** `100.102.29.104`:

- **VNC:** połącz klientem (Remmina/TigerVNC) do `100.102.29.104:5900`, hasło `BoobsVNC2026`
- **SSH:** `ssh boobs@100.102.29.104 -p 2222` (hasło `boobs`)

Zmienne do nadpisania: `TS_IP`, `VNC_PASS`, `DISK`.
Zatrzymanie VM: `sudo pkill -f "name BoobsOS"`.

## Jak odtworzyć qcow2 od zera

Wymaga: docker, lokalny rejestr, dostęp do `quay.io/centos-bootc/bootc-image-builder`.

```bash
# 1. zbuduj obraz OCI
docker build -f Containerfile -t boobsos:dev .

# 2. (opcjonalnie) warstwa demo z userem + autologinem
docker build -f Containerfile.vm -t boobsos-vm:dev .

# 3. lokalny rejestr + push
docker run -d --name boobs-reg -p 5000:5000 registry:2
docker tag boobsos-vm:dev localhost:5000/boobsos-vm:dev
docker push localhost:5000/boobsos-vm:dev

# 4. zapełnij container-storage podmanem Z WNĘTRZA obrazu (host nie ma podmana)
sudo mkdir -p /var/lib/containers/storage
sudo docker run --rm --privileged --network host --security-opt label=disable \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  --entrypoint /usr/bin/podman boobsos:dev \
  pull --tls-verify=false localhost:5000/boobsos-vm:dev

# 5. bib --local → qcow2 (rootfs trzeba podać jawnie!)
sudo docker run --rm --privileged --network host --security-opt label=disable \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v $PWD/bib-output:/output -v $PWD/bib-config.toml:/config.toml:ro \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 --rootfs ext4 --config /config.toml --local \
  localhost:5000/boobsos-vm:dev
```

## Napotkane pułapki (rozwiązane)

- bib czyta obraz **źródłowy z container-storage**, nie z rejestru → zapełniamy
  storage podmanem z wnętrza obrazu Fedory (host nie ma podmana — apt zablokowany).
- bib wymaga jawnego `--rootfs ext4` (obraz nie deklaruje domyślnego rootfs).
- `bootc install to-disk --via-loopback` nie tworzył ESP (UEFI) — dlatego bib, nie to-disk.
- **Sandbox agenta** ubija hostowe qemu (display/VNC → sygnał 16; nawet `qemu-img`/`pkill qemu`).
  Dlatego VM uruchamia się ręcznie na hoście, nie z poziomu agenta.
