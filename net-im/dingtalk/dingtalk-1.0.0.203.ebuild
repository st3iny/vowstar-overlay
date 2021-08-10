# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit desktop multilib unpacker xdg

DESCRIPTION="dingtalk"
HOMEPAGE="https://gov.dingtalk.com"
SRC_URI="com.alibabainc.${PN}_${PV}_amd64.deb"

LICENSE="all-rights-reserved"
KEYWORDS="-* ~amd64"
SLOT="0"

RESTRICT="strip mirror bindist fetch"

RDEPEND="
	dev-libs/libthai
	net-nds/openldap
	sys-libs/glibc
	sys-libs/zlib
"

BDEPEND="dev-util/patchelf"

DEPEND="${RDEPEND}"

S=${WORKDIR}

src_unpack() {
	:
}

src_install() {
	dodir /
	cd "${ED}" || die
	unpacker
	# Remove the libraries that break compatibility in modern systems
	# Dingtalk will use the system libs instead
	version=$(cat opt/apps/com.alibabainc.dingtalk/files/version)
	# Use system stdc++
	rm opt/apps/com.alibabainc.dingtalk/files/${version}/libstdc++* || die
	# Use system glibc
	rm opt/apps/com.alibabainc.dingtalk/files/${version}/libm.so* || die
	# Use system zlib
	rm opt/apps/com.alibabainc.dingtalk/files/${version}/libz* || die

	# Set RPATH for preserve-libs handling
	pushd "opt/apps/com.alibabainc.dingtalk/files/${version}/" || die
	local x
	for x in $(find) ; do
		# Use \x7fELF header to separate ELF executables and libraries
		[[ -f ${x} && $(od -t x1 -N 4 "${x}") == *"7f 45 4c 46"* ]] || continue
		patchelf --set-rpath '$ORIGIN' "${x}" || \
			die "patchelf failed on ${x}"
	done
	popd || die
	# Fix fcitx5
	sed -i "s/export XMODIFIERS/#export XMODIFIERS/g" opt/apps/com.alibabainc.dingtalk/files/Elevator.sh || die
	sed -i "s/export QT_IM_MODULE/#export QT_IM_MODULE/g" opt/apps/com.alibabainc.dingtalk/files/Elevator.sh || die
	sed -i "s/export QT_QPA_PLATFORM/#export QT_QPA_PLATFORM/g" opt/apps/com.alibabainc.dingtalk/files/Elevator.sh || die
	mkdir -p usr/share/applications || die
	cp opt/apps/com.alibabainc.dingtalk/entries/applications/com.alibabainc.dingtalk.desktop usr/share/applications/ || die
}

pkg_nofetch() {
	einfo "Please follow https://h5.dingtalk.com/circle/healthCheckin.html?corpId=dingdc75e6471f48e6171a5c74e782e240c4&c003e554-f=3edf7be3-a&cbdbhh=qwertyuiop and download"
	einfo "${DISTFILE_BIN}"
	einfo "and place it in your DISTDIR directory."
}