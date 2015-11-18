######################################################################
# ossfs - FUSE-based file system backed by Amazon S3
#
# Copyright 2007-2008 Randy Rizun <rrizun@gmail.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
######################################################################
dnl Process this file with autoconf to produce a configure script.

AC_PREREQ(2.59)
AC_INIT(ossfs, 0.0.1)
AC_CONFIG_HEADER([config.h])

AC_CANONICAL_SYSTEM
AM_INIT_AUTOMAKE()

AC_PROG_CXX
AC_PROG_CC

CXXFLAGS="$CXXFLAGS -Wall -D_FILE_OFFSET_BITS=64"

PKG_CHECK_MODULES([DEPS], [fuse >= 2.8.4 libcurl >= 7.0 libxml-2.0 >= 2.6 libcrypto >= 0.9])

dnl ----------------------------------------------
dnl check functions
dnl ----------------------------------------------
dnl malloc_trim function
AC_CHECK_FUNCS(malloc_trim, , )

dnl Initializing NSS(temporally)
dnl AC_MSG_CHECKING([Initializing libcurl build with NSS])
dnl AC_ARG_ENABLE(
dnl   nss-init,
dnl   [
dnl     AS_HELP_STRING(
dnl       [--enable-nss-init],
dnl       [Inilializing libcurl with NSS (default is no)]
dnl     )
dnl   ],
dnl   [
dnl     case "${enableval}" in
dnl     yes)
dnl       AC_MSG_RESULT(yes)
dnl       nss_init_enabled=yes
dnl       ;;
dnl     *)
dnl       AC_MSG_RESULT(no)
dnl       nss_init_enabled=no
dnl       ;;
dnl     esac
dnl   ],
dnl   [
dnl     AC_MSG_RESULT(no)
dnl     nss_init_enabled=no
dnl   ])
dnl 
dnl AS_IF(
dnl   [test $nss_init_enabled = yes],
dnl   [
dnl     AC_DEFINE(NSS_INIT_ENABLED, 1)
dnl     AC_CHECK_LIB(nss3, NSS_NoDB_Init, , [AC_MSG_ERROR(not found NSS libraries)])
dnl     AC_CHECK_LIB(plds4, PL_ArenaFinish, , [AC_MSG_ERROR(not found PL_ArenaFinish)])
dnl     AC_CHECK_LIB(nspr4, PR_Cleanup, , [AC_MSG_ERROR(not found PR_Cleanup)])
dnl     AC_CHECK_HEADER(nss.h, , [AC_MSG_ERROR(not found nss.h)])
dnl     AC_CHECK_HEADER(nspr4/prinit.h, , [AC_MSG_ERROR(not found prinit.h)])
dnl     AC_PATH_PROG(NSSCONFIG, [nss-config], no)
dnl     AS_IF(
dnl       [test $NSSCONFIG = no],
dnl       [
dnl         DEPS_CFLAGS="$DEPS_CFLAGS -I/usr/include/nss3"
dnl         DEPS_LIBS="$DEPS_LIBS -lnss3"
dnl       ],
dnl       [
dnl         addcflags=`nss-config --cflags`
dnl         DEPS_CFLAGS="$DEPS_CFLAGS $addcflags"
dnl         dnl addlib=`nss-config --libs`
dnl         dnl DEPS_LIBS="$DEPS_LIBS $addlib"
dnl         DEPS_LIBS="$DEPS_LIBS -lnss3"
dnl       ])
dnl     AC_PATH_PROG(NSPRCONFIG, [nspr-config], no)
dnl     AS_IF(
dnl       [test $NSPRCONFIG = no],
dnl       [
dnl         DEPS_CFLAGS="$DEPS_CFLAGS -I/usr/include/nspr4"
dnl         DEPS_LIBS="$DEPS_LIBS -lnspr4 -lplds4"
dnl       ],
dnl       [
dnl         addcflags=`nspr-config --cflags`
dnl         DEPS_CFLAGS="$DEPS_CFLAGS $addcflags"
dnl         dnl addlib=`nspr-config --libs`
dnl         dnl DEPS_LIBS="$DEPS_LIBS $addlib"
dnl         DEPS_LIBS="$DEPS_LIBS -lnspr4 -lplds4"
dnl       ])
dnl   ])
dnl 
dnl AS_UNSET(nss_enabled)

dnl ----------------------------------------------
dnl output files
dnl ----------------------------------------------
AC_CONFIG_FILES(Makefile src/Makefile test/Makefile doc/Makefile)

dnl ----------------------------------------------
dnl put
dnl ----------------------------------------------
AC_OUTPUT

dnl ----------------------------------------------
dnl end configuration
dnl ----------------------------------------------

