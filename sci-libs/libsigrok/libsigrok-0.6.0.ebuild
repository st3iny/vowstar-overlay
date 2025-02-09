# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"

PYTHON_COMPAT=( python3_{9..12} )
GIT_COMMIT="f6d0f7a"

inherit autotools python-r1 java-pkg-opt-2 udev xdg

if [[ ${PV} == *9999* ]]; then
	EGIT_REPO_URI="git://sigrok.org/${PN}"
	inherit git-r3
else
	SRC_URI="http://sigrok.org/gitweb/?p=${PN}.git;a=snapshot;h=${GIT_COMMIT};sf=zip -> ${PN}-${GIT_COMMIT}.zip"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
	S="${WORKDIR}/${PN}-${GIT_COMMIT}"
fi

DESCRIPTION="Basic hardware drivers for logic analyzers and input/output file format support"
HOMEPAGE="https://sigrok.org/wiki/Libsigrok"

LICENSE="GPL-3"
SLOT="0/4"
IUSE="bluetooth +cxx ftdi hidapi java nettle parport python serial static-libs test +udev usb"
REQUIRED_USE="java? ( cxx )
	python? ( cxx ${PYTHON_REQUIRED_USE} )"

RESTRICT="!test? ( test )"

# We also support librevisa, but that isn't in the tree ...
LIB_DEPEND="
	>=dev-libs/glib-2.32.0[static-libs(+)]
	>=dev-libs/libzip-0.8:=[static-libs(+)]
	bluetooth? ( >=net-wireless/bluez-4.0:= )
	cxx? ( dev-cpp/glibmm:2[static-libs(+)] )
	ftdi? ( dev-embedded/libftdi:1[static-libs(+)] )
	hidapi? ( >=dev-libs/hidapi-0.8.0 )
	nettle? ( dev-libs/nettle:=[static-libs(+)] )
	parport? ( sys-libs/libieee1284[static-libs(+)] )
	python? (
		${PYTHON_DEPS}
		>=dev-python/pygobject-3.0.0[${PYTHON_USEDEP}]
	)
	serial? ( >=dev-libs/libserialport-0.1.1[static-libs(+)] )
	usb? ( virtual/libusb:1[static-libs(+)] )
"
RDEPEND="
	java? ( >=virtual/jre-1.8:* )
	!static-libs? ( ${LIB_DEPEND//\[static-libs(+)]} )
	static-libs? ( ${LIB_DEPEND} )
"
DEPEND="${LIB_DEPEND//\[static-libs(+)]}
	cxx? ( app-doc/doxygen )
	java? (
		>=dev-lang/swig-3.0.6
		>=virtual/jdk-1.8:*
	)
	python? (
		>=dev-lang/swig-3.0.6
		dev-python/numpy[${PYTHON_USEDEP}]
		dev-python/setuptools[${PYTHON_USEDEP}]
	)
	test? ( >=dev-libs/check-0.9.4 )
	virtual/pkgconfig
"

BDEPEND="app-arch/unzip"

PATCHES=(
	# https://bugs.gentoo.org/878395
	"${FILESDIR}/${PN}-0.5.2-swig-4.1.patch"
	"${FILESDIR}/${PN}-0.5.2-sipeed-slogic.patch"
)

pkg_setup() {
	use python && python_setup
	java-pkg-opt-2_pkg_setup
}

src_unpack() {
	[[ ${PV} == *9999* ]] && git-r3_src_unpack || default
}

sigrok_src_prepare() {
	eautoreconf
}

src_prepare() {
	default
	sigrok_src_prepare
	use python && python_copy_sources
}

sigrok_src_configure() {
	econf \
		$(use_with bluetooth libbluez) \
		$(use_with ftdi libftdi) \
		$(use_with hidapi libhidapi) \
		$(use_with nettle libnettle) \
		$(use_with parport libieee1284) \
		$(use_with serial libserialport) \
		$(use_with usb libusb) \
		$(use_enable cxx) \
		$(use_enable java) \
		$(use_enable static-libs static) \
		"${@}"
}

each_python_configure() {
	cd "${BUILD_DIR}"
	sigrok_src_configure --disable-ruby --enable-python
}

src_configure() {
	sigrok_src_configure --disable-ruby --disable-python
	use python && python_foreach_impl each_python_configure
}

each_python_compile() {
	cd "${BUILD_DIR}"
	emake python-build
}

src_compile() {
	default
	use python && python_foreach_impl each_python_compile
}

src_test() {
	emake check
}

each_python_install() {
	cd "${BUILD_DIR}"
	emake python-install DESTDIR="${D}"
	python_optimize
}

src_install() {
	default
	use python && python_foreach_impl each_python_install
	use udev && udev_dorules contrib/*.rules
	find "${D}" -name '*.la' -type f -delete || die
}

pkg_postinst() {
	udev_reload
	xdg_pkg_postinst
}

pkg_postrm() {
	udev_reload
	xdg_pkg_postrm
}
