Name:           boobsos-branding
Version:        1.0.0
Release:        1%{?dist}
Summary:        Branding wizualny BoobsOS — ikony, tapety, motyw Plymouth, logo GDM
License:        MIT
BuildArch:      noarch

%description
Paczka zawiera zasoby wizualne BoobsOS (wariant niebieski/dev):
- Ikony aplikacji w rozmiarach 64x64, 128x128, 256x256, 512x512 (hicolor)
- Tapety pulpitu: boobsos.png i boobsos-dark.png
- Motyw Plymouth "boobsos" (two-step): boobsos.plymouth, watermark.png, boobsos-logo.png
- Logo GDM: boobsos-gdm-logo.png

%install
install -Dm644 %{_sourcedir}/icons/64x64/boobsos.png \
    %{buildroot}%{_datadir}/icons/hicolor/64x64/apps/boobsos.png
install -Dm644 %{_sourcedir}/icons/128x128/boobsos.png \
    %{buildroot}%{_datadir}/icons/hicolor/128x128/apps/boobsos.png
install -Dm644 %{_sourcedir}/icons/256x256/boobsos.png \
    %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/boobsos.png
install -Dm644 %{_sourcedir}/icons/512x512/boobsos.png \
    %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/boobsos.png

install -Dm644 %{_sourcedir}/backgrounds/boobsos.png \
    %{buildroot}%{_datadir}/backgrounds/boobsos/boobsos.png
install -Dm644 %{_sourcedir}/backgrounds/boobsos-dark.png \
    %{buildroot}%{_datadir}/backgrounds/boobsos/boobsos-dark.png

install -Dm644 %{_sourcedir}/plymouth/boobsos.plymouth \
    %{buildroot}%{_datadir}/plymouth/themes/boobsos/boobsos.plymouth
install -Dm644 %{_sourcedir}/plymouth/watermark.png \
    %{buildroot}%{_datadir}/plymouth/themes/boobsos/watermark.png
install -Dm644 %{_sourcedir}/plymouth/boobsos-logo.png \
    %{buildroot}%{_datadir}/plymouth/themes/boobsos/boobsos-logo.png

install -Dm644 %{_sourcedir}/pixmaps/boobsos-gdm-logo.png \
    %{buildroot}%{_datadir}/pixmaps/boobsos-gdm-logo.png

%files
%{_datadir}/icons/hicolor/64x64/apps/boobsos.png
%{_datadir}/icons/hicolor/128x128/apps/boobsos.png
%{_datadir}/icons/hicolor/256x256/apps/boobsos.png
%{_datadir}/icons/hicolor/512x512/apps/boobsos.png
%{_datadir}/backgrounds/boobsos/boobsos.png
%{_datadir}/backgrounds/boobsos/boobsos-dark.png
%dir %{_datadir}/plymouth/themes/boobsos
%{_datadir}/plymouth/themes/boobsos/boobsos.plymouth
%{_datadir}/plymouth/themes/boobsos/watermark.png
%{_datadir}/plymouth/themes/boobsos/boobsos-logo.png
%{_datadir}/pixmaps/boobsos-gdm-logo.png

%changelog
* Tue Jun 17 2026 BoobsOS <repo@cycx.io> - 1.0.0-1
- Pierwsza paczka brandingu BoobsOS (wariant niebieski/dev)
