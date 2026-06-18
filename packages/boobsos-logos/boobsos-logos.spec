Name:           boobsos-logos
Version:        44.1
Release:        1%{?dist}
Summary:        Grafiki brandingowe BoobsOS (fork fedora-logos)
# fedora-logos używa licencji "Copyright only" + MIT dla niektórych plików
License:        MIT and Copyright only
BuildArch:      noarch

# Lokalizacja drzewa plików przygotowanego przez build.sh.
# Uzywamy _topdir/BUILD (staly katalog) zamiast _builddir, ktory
# w nowszych wersjach rpmbuild wskazuje na podkatalog z nazwa paczki.
%global _logos_tree %{_topdir}/BUILD/boobsos-logos-tree
%global _logos_filelist %{_topdir}/BUILD/boobsos-logos.filelist

# === Dostarczamy te same "wirtualne" pakiety co fedora-logos ===
Provides:       system-logos         = %{version}-%{release}
Provides:       fedora-logos         = %{version}-%{release}
Provides:       gnome-logos          = %{version}-%{release}
Provides:       redhat-logos         = %{version}-%{release}

# === Wypieramy i konfliktujemy z fedora-logos, żeby dnf wybrał nas ===
Obsoletes:      fedora-logos < %{version}-%{release}
Conflicts:      fedora-logos

%description
Fork paczki fedora-logos dla dystrybucji BoobsOS.
Zawiera wszystkie pliki oryginalne z fedora-logos (Plymouth, ikony, grub,
tapety, bootloader), ale zasoby graficzne instalatora Anaconda (pixmapy
paska bocznego, nagłówka itp.) są zastąpione brandingiem BoobsOS
(łabędź w heksagonie, paleta #2563EB→#2090C0→#402090).

Paczka spełnia zależność `system-logos` wymaganą przez anaconda-gui
i anaconda-webui, eliminując fedora-logos z obrazu ISO.

# Brak %prep/%build — drzewo plików jest przygotowane przed wywołaniem rpmbuild.
# Pusty %prep żeby rpmbuild nie wyrzucał błędu braku katalogu build subdir.
%prep
# nic do roboty — build.sh przygotował %{_logos_tree} i %{_logos_filelist}

%build
# noarch, brak kompilacji

%install
# Skopiuj całe drzewo plików z przygotowanego katalogu do buildroot
cp -a %{_logos_tree}/. %{buildroot}/

%files -f %{_logos_filelist}

%changelog
* Thu Jun 18 2026 BoobsOS <repo@cycx.io> - 44.1-1
- Fork fedora-logos 42.0.1-3.fc44 z brandingiem BoobsOS
- Zastapienie pixmap Anacondy (sidebar-logo, sidebar-bg, topbar-bg)
  grafikami BoobsOS (labedz w heksagonie)
- Provides/Obsoletes/Conflicts: fedora-logos - zastepuje oryginalny pakiet
