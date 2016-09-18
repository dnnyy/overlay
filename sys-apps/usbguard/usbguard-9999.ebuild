# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit autotools git-r3 systemd

DESCRIPTION="The USBGuard software framework helps to protect your computer against BadUSB."
HOMEPAGE="https://github.com/dkopecek/usbguard"
MY_AUTHOR="dkopecek"
EGIT_REPO_URI="https://github.com/${MY_AUTHOR}/${PN}.git"
EGIT_SUBMODULES=( src/ThirdParty/Catch src/ThirdParty/PEGTL src/ThirdParty/usbmon )

if [[ ${PV} == "9999" ]] ; then
	EGIT_BRANCH="master"
	KEYWORDS=""
else
	EGIT_COMMIT="usbguard-${PV}"
	KEYWORDS="~x86 ~amd64"
fi

LICENSE="GPL-2"
SLOT="0"
IUSE="crypt +dbus +policykit qt4 qt5 +systemd"
IUSE+=" crypt_gcrypt crypt_sodium"

DEPEND="sys-cluster/libqb
		sys-libs/libseccomp
		sys-libs/libcap-ng
		dev-libs/protobuf
		systemd? ( sys-apps/systemd )
		dbus? ( sys-apps/dbus
						dev-libs/dbus-glib )
		policykit? ( sys-auth/polkit )
		qt4? ( dev-qt/qtgui:4
					 dev-qt/qtsvg:4
					 dev-qt/qtcore:4 )
		qt5? ( dev-qt/qtgui:5
					 dev-qt/qtsvg:5
					 dev-qt/qtwidgets:5
					 dev-qt/qtcore:5 )
		crypt? (
			crypt_gcrypt? ( dev-libs/libgcrypt )
			crypt_sodium? ( dev-libs/libsodium )
		)"

RDEPEND="${DEPEND}
				virtual/udev"

REQUIRED_USE="
		crypt? (
			^^ (
					crypt_sodium
					crypt_gcrypt
			)
		)
		?? ( qt4 qt5 )"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=()

	if use crypt_gcrypt; then
		myconf+=( --with-crypto-library=gcrypt )
 	elif use crypt_sodium; then
		myconf+=( --with-crypto-library=sodium )
	fi

	if use qt5; then
		myconf+=( --with-gui-qt=qt5 )
	elif use qt4; then
		myconf+=( --with-gui-qt=qt4 )
	fi

	if use policykit; then
		myconf+=( --with-polkit )
	fi

	econf \
		$(use_enable systemd) \
		$(use_with dbus) \
		--with-bundled-catch \
		--with-bundled-pegtl \
		"${myconf[@]}"
}

src_compile() {
	emake
}

src_install() {
	emake DESTDIR="${D}" install

	doman doc/*.1
	doman doc/*.5
	doman doc/*.8

	systemd_dounit usbguard.service

	insinto /etc/usbguard
	doins usbguard-daemon.conf
}