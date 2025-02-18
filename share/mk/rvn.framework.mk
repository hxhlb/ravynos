.include <bsd.subdir.mk>

FRAMEWORK_DIR=${MAKEOBJDIR}/${FRAMEWORK}.framework
FMWK_VERSION?=A
NO_ROOT=yes

UID != id -u
.if defined(UID) && ${UID} != 0
INSTALLFLAGS=-U
.endif

.if defined(SRCS) && !empty(SRCS)
LIBMODE?=0555
SHLIB_NAME=lib${FRAMEWORK}.so
SHLIB_VERSION=${FMWK_VERSION}
SHLIBDIR=${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}
.endif

.if defined(INCS) && !empty(INCS)
INSTALL+= ${INSTALLFLAGS}
INCLUDEDIR=${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}/Headers
.endif

.if defined(RESOURCES) && !empty(RESOURCES)
RSCDIR=${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}/Resources
installresources: ${RESOURCES}
	tar -C ${.CURDIR} -cf - ${RESOURCES} | tar -C ${RSCDIR} -xvf -
.else
installresources: .PHONY
.endif

.include <rvn.common.mk>

all: ${FRAMEWORK_DIR} ${SHLIB_NAME} installincludes _libinstall installresources \
	post-resources
post-resources: .PHONY

${FRAMEWORK_DIR}:
	@${ECHO} building ${FRAMEWORK_DIR} bundle
	mkdir -p "${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}/Headers" \
		"${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}/Modules" \
		"${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}/Resources"
	(cd "${FRAMEWORK_DIR}"; \
		ln -sf Versions/${FMWK_VERSION}/Headers Headers; \
		ln -sf Versions/${FMWK_VERSION}/Modules Modules; \
		ln -sf Versions/${FMWK_VERSION}/Resources Resources)
.if defined(SRCS) && !empty(SRCS)
	(cd ${FRAMEWORK_DIR}; \
		ln -sf Versions/${FMWK_VERSION}/lib${FRAMEWORK}.so lib${FRAMEWORK}.so)
.endif
	(cd "${FRAMEWORK_DIR}/Versions"; ln -sf ${FMWK_VERSION} Current)
	touch "${FRAMEWORK_DIR}/Versions/${FMWK_VERSION}/Resources/Info.plist"

link_subdirs:
_fcmd=(
.for d in ${LINK_SUBDIR}
LINK_EXT.${d}?=.o
_fcmd+=find ${d} -name '*${LINK_EXT.${d}:M*}' -a -not -name '.depend.*'
.for _excl in ${LINK_EXCLUDE.${d}:M*}
_fcmd+= -a -not -name '${_excl}'
.endfor
_fcmd+=;
.endfor
_fcmd+=)
LDADD+= ${_fcmd:sh:M*}

.include <bsd.lib.mk>
.include <bsd.incs.mk>

${SHLIB_NAME_FULL}: link_subdirs
