# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} pypy3 )
DISTUTILS_USE_PEP517=setuptools
inherit distutils-r1 pypi

DESCRIPTION="PAC/Dnsmasq/Wingy file Generator"
HOMEPAGE="https://github.com/JinnLynn/genpac"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~ia64 ~riscv ~sparc ~x86"

PATCHES=(
	"${FILESDIR}/${PN}-2.1.0-fix-collections.patch"
)
