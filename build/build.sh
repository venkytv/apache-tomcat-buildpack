#!/bin/bash

BUILDDIR='/app'
APACHE_BUILDDIR="${BUILDDIR}/apache"
JRE_BUILDDIR="${BUILDDIR}/jre"
TOMCAT_BUILDDIR="${BUILDDIR}/tomcat"
WEBSOCKETD_BUILDDIR="${BUILDDIR}/websocketd"
BASEDIR='/vagrant'
BUNDLEDIR="${BASEDIR}/vendor/bundles"

: ${APACHE_MIRROR:='http://apache.bytenet.in/'}

. "$( dirname $0 )/versions.sh"

export PATH="/usr/bin:/bin:${APACHE_BUILDDIR}/bin"

die() {
	echo "ERROR: $*" >&2
	exit 2
}

download() {
	URL="$1"
	MD5="$2"
	OUT="${3:-$( basename $URL )}"
	[[ -f "$OUT" ]] || wget "$URL"

	DOWNLOAD_MD5=$( md5sum "$OUT" | cut -d' ' -f1 )
	[[ ${MD5} != ${DOWNLOAD_MD5} ]] &&
		die "Checksum verification failed: $OUT"
}

SRCDIR="${HOME}/src"
mkdir -p "$SRCDIR"
cd "$SRCDIR"

download "${APACHE_MIRROR}/httpd/httpd-${APACHE_VERSION}.tar.bz2" "$APACHE_MD5SUM"
download "${APACHE_MIRROR}/apr/apr-${APR_VERSION}.tar.bz2" "$APR_MDRSUM"
download "${APACHE_MIRROR}/apr/apr-util-${APRUTIL_VERSION}.tar.bz2" "$APRUTIL_MD5SUM"
download "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.bz2" "$PCRE_MD5SUM"

# Clean up build directory
rm -rf "${APACHE_BUILDDIR}"

# Build and install PCRE
banner PCRE
cd "$SRCDIR"
tar xf "pcre-${PCRE_VERSION}.tar.bz2"
cd "pcre-${PCRE_VERSION}"
./configure --prefix="$APACHE_BUILDDIR" \
	&& make \
	&& make install
[[ $? -ne 0 ]] && exit 2

# Build and install apache
banner Apache
cd "$SRCDIR"
for OUTDIR in "httpd-${APACHE_VERSION}" "apr-${APR_VERSION}" "apr-util-${APRUTIL_VERSION}"; do
	[[ -e "$OUTDIR" ]] && rm -rf "$OUTDIR"
done

tar xf "httpd-${APACHE_VERSION}.tar.bz2"
tar xf "apr-${APR_VERSION}.tar.bz2"
tar xf "apr-util-${APRUTIL_VERSION}.tar.bz2"

mv "apr-${APR_VERSION}" "httpd-${APACHE_VERSION}/srclib/apr"
mv "apr-util-${APRUTIL_VERSION}" "httpd-${APACHE_VERSION}/srclib/apr-util"
cd "httpd-${APACHE_VERSION}" \
	&& ./configure --prefix="$APACHE_BUILDDIR" --with-included-apr \
	&& make \
	&& make install
[[ $? -ne 0 ]] && exit 2
rm -rf "${APACHE_BUILDDIR}/man"
rm -rf "${APACHE_BUILDDIR}/manual"

# Build and install mod_jk
banner mod_jk
cd "$SRCDIR"
download "http://www.apache.org/dist/tomcat/tomcat-connectors/jk/tomcat-connectors-${MODJK_VERSION}-src.tar.gz" \
	"$MODJK_MD5SUM"
tar xf "tomcat-connectors-${MODJK_VERSION}-src.tar.gz"
cd "tomcat-connectors-${MODJK_VERSION}-src/native"
./configure --prefix="$APACHE_BUILDDIR" --with-apxs \
	&& make \
	&& make install
[[ $? -ne 0 ]] && exit 2

# Download and install tomcat
banner Tomcat
rm -rf "${TOMCAT_BUILDDIR}"
cd "$SRCDIR"
TOMCAT_MAJOR_VERSION="${TOMCAT_VERSION%%.*}"
download "${APACHE_MIRROR}/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
	"$TOMCAT_MD5SUM"
tar xf "apache-tomcat-${TOMCAT_VERSION}.tar.gz"
mv "apache-tomcat-${TOMCAT_VERSION}" ${TOMCAT_BUILDDIR}

# Download and install Oracle JRE
banner JRE
rm -rf "${JRE_BUILDDIR}"
cd "$SRCDIR"
JRE_MAJOR_VERSION=${JRE_VERSION%%-*}
URL="http://download.oracle.com/otn-pub/java/jdk/${JRE_VERSION}/jre-${JRE_MAJOR_VERSION}-linux-x64.tar.gz"
OUT=$( basename "$URL" )
[[ -e "$OUT" ]] ||
	wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "$URL"
MD5=$( md5sum "$OUT" | cut -d' ' -f1 )
[[ ${MD5} != ${JRE_MD5SUM} ]] &&
	die "Checksum verification failed: $OUT"
EXTRACTDIR='jdk_extract'
rm -rf "$EXTRACTDIR" && mkdir -p "$EXTRACTDIR"
cd "$EXTRACTDIR"
tar xf ../${OUT}
mv $( ls ) "$JRE_BUILDDIR"
cd "$SRCDIR"
rmdir "$EXTRACTDIR"

# Download and set up websocketd
banner Websocketd
rm -rf "${WEBSOCKETD_BUILDDIR}"
cd "$SRCDIR"
download "https://github.com/joewalnes/websocketd/releases/download/v${WEBSOCKETD_VERSION}/websocketd-${WEBSOCKETD_VERSION}-linux_amd64.zip" \
	"$WEBSOCKETD_MD5SUM"
unzip "websocketd-${WEBSOCKETD_VERSION}-linux_amd64.zip" websocketd
mkdir "${WEBSOCKETD_BUILDDIR}"
mv websocketd "$WEBSOCKETD_BUILDDIR"

# Bundle packages
banner Bundling
rm -rf "$BUNDLEDIR" && mkdir -p "$BUNDLEDIR"
cd "$BUILDDIR"
for BUNDLE in apache jre tomcat websocketd; do
	tar jcf "${BUNDLEDIR}/${BUNDLE}.tar.bz2" "$BUNDLE"
done

cd "$BUNDLEDIR"
md5sum *.tar.bz2 >"${BASEDIR}/bundles.md5sum"
