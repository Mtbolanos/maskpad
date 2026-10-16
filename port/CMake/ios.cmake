include(FetchContent)

# ZAPDLib runs in-process for first-launch asset extraction and requires PNG.
set(PNG_SHARED OFF CACHE BOOL "" FORCE)
set(PNG_STATIC ON CACHE BOOL "" FORCE)
set(PNG_FRAMEWORK OFF CACHE BOOL "" FORCE)
set(PNG_TESTS OFF CACHE BOOL "" FORCE)
set(PNG_TOOLS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
    PNG
    GIT_REPOSITORY https://github.com/pnggroup/libpng.git
    GIT_TAG 02f2b4f4699f0ef9111a6534f093b53732df4452 # v1.6.54
    OVERRIDE_FIND_PACKAGE
)
FetchContent_MakeAvailable(PNG)

# libpng's ARM NEON sources are not added consistently by the Xcode generator
# for iphoneos. Force the portable path on the target itself so every libpng
# translation unit sees the setting even when CMake cannot detect the target
# architecture while generating the Xcode project.
if(PLATFORM STREQUAL "OS64")
    target_compile_definitions(png_static PRIVATE PNG_ARM_NEON_OPT=0)
endif()

if(NOT TARGET PNG::PNG)
    add_library(PNG::PNG ALIAS png_static)
endif()

# Keep the desktop custom-audio formats available in the iOS build.
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(INSTALL_DOCS OFF CACHE BOOL "" FORCE)
set(INSTALL_PKG_CONFIG_MODULE OFF CACHE BOOL "" FORCE)
set(INSTALL_CMAKE_PACKAGE_MODULE OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
    Ogg
    GIT_REPOSITORY https://github.com/xiph/ogg.git
    GIT_TAG be05b13e98b048f0b5a0f5fa8ce514d56db5f822 # v1.3.6
    OVERRIDE_FIND_PACKAGE
)
FetchContent_MakeAvailable(Ogg)

FetchContent_Declare(
    Vorbis
    GIT_REPOSITORY https://github.com/xiph/vorbis.git
    GIT_TAG 0657aee69dec8508a0011f47f3b69d7538e9d262 # v1.3.7
)
FetchContent_MakeAvailable(Vorbis)
if(NOT TARGET Vorbis::vorbis)
    add_library(Vorbis::vorbis ALIAS vorbis)
    add_library(Vorbis::vorbisenc ALIAS vorbisenc)
    add_library(Vorbis::vorbisfile ALIAS vorbisfile)
endif()

set(OPUS_BUILD_TESTING OFF CACHE BOOL "" FORCE)
set(OPUS_BUILD_PROGRAMS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(
    Opus
    GIT_REPOSITORY https://github.com/xiph/opus.git
    GIT_TAG ddbe48383984d56acd9e1ab6a090c54ca6b735a6 # v1.5.2
)
FetchContent_MakeAvailable(Opus)
if(NOT TARGET Opus::opus)
    add_library(Opus::opus ALIAS opus)
endif()

set(OPUS_COMPAT_INCLUDE_DIR "${CMAKE_BINARY_DIR}/maskpad-include")
file(COPY "${opus_SOURCE_DIR}/include/"
    DESTINATION "${OPUS_COMPAT_INCLUDE_DIR}/opus"
)
target_include_directories(opus INTERFACE
    "$<BUILD_INTERFACE:${OPUS_COMPAT_INCLUDE_DIR}>"
)

# opusfile 0.12 has no CMake project; build its local-file decoder directly.
FetchContent_Declare(
    OpusFile
    GIT_REPOSITORY https://github.com/xiph/opusfile.git
    GIT_TAG a55c164e9891a9326188b7d4d216ec9a88373739 # v0.12
    SOURCE_SUBDIR cmake-not-available
)
FetchContent_MakeAvailable(OpusFile)
add_library(opusfile STATIC
    ${opusfile_SOURCE_DIR}/src/info.c
    ${opusfile_SOURCE_DIR}/src/internal.c
    ${opusfile_SOURCE_DIR}/src/opusfile.c
    ${opusfile_SOURCE_DIR}/src/stream.c
)
target_compile_definitions(opusfile PRIVATE OP_DISABLE_HTTP)
target_include_directories(opusfile
    PUBLIC ${opusfile_SOURCE_DIR}/include
    PRIVATE ${opusfile_SOURCE_DIR}/src
)
target_link_libraries(opusfile PUBLIC Ogg::ogg Opus::opus)
add_library(OpusFile::opusfile ALIAS opusfile)

# --- MaskPad AP: OpenSSL for Archipelago ------------------------------------------------------------
# garrettjoecox's Archipelago client (apclientpp/websocketpp/asio) connects over TLS with OpenSSL, which
# the iOS SDK does not ship. Build a static OpenSSL 3.5 LTS once per build directory (kept with _deps, so
# the CI cache and the Mac runner reuse it) and point FindOpenSSL at it.
set(MASKPAD_OPENSSL_VERSION "3.5.9")
set(MASKPAD_OPENSSL_SHA256 "603f5602e2eef00d77fbd429d34dcd5822bb301757a1bc9cdb24c670f1eb859a")
if(PLATFORM STREQUAL "SIMULATORARM64")
    set(MASKPAD_OPENSSL_TARGET "iossimulator-arm64-xcrun")
else()
    set(MASKPAD_OPENSSL_TARGET "ios64-xcrun")
endif()
set(MASKPAD_OPENSSL_PREFIX "${CMAKE_BINARY_DIR}/_deps/openssl-${MASKPAD_OPENSSL_VERSION}-${MASKPAD_OPENSSL_TARGET}")
if(NOT EXISTS "${MASKPAD_OPENSSL_PREFIX}/lib/libssl.a" OR NOT EXISTS "${MASKPAD_OPENSSL_PREFIX}/lib/libcrypto.a")
    set(_maskpad_openssl_archive "${CMAKE_BINARY_DIR}/_deps/openssl-${MASKPAD_OPENSSL_VERSION}.tar.gz")
    set(_maskpad_openssl_source "${CMAKE_BINARY_DIR}/_deps/openssl-${MASKPAD_OPENSSL_VERSION}-src")
    file(DOWNLOAD
        "https://github.com/openssl/openssl/releases/download/openssl-${MASKPAD_OPENSSL_VERSION}/openssl-${MASKPAD_OPENSSL_VERSION}.tar.gz"
        "${_maskpad_openssl_archive}"
        EXPECTED_HASH SHA256=${MASKPAD_OPENSSL_SHA256}
        TLS_VERIFY ON
    )
    file(REMOVE_RECURSE "${_maskpad_openssl_source}")
    file(ARCHIVE_EXTRACT INPUT "${_maskpad_openssl_archive}" DESTINATION "${_maskpad_openssl_source}")
    set(_maskpad_openssl_tree "${_maskpad_openssl_source}/openssl-${MASKPAD_OPENSSL_VERSION}")
    cmake_host_system_information(RESULT _maskpad_jobs QUERY NUMBER_OF_LOGICAL_CORES)
    message(STATUS "MaskPad AP: building OpenSSL ${MASKPAD_OPENSSL_VERSION} for ${MASKPAD_OPENSSL_TARGET}")
    execute_process(
        COMMAND perl Configure ${MASKPAD_OPENSSL_TARGET} no-shared no-tests no-apps no-docs no-module
            "-mios-version-min=${DEPLOYMENT_TARGET}"
            "--prefix=${MASKPAD_OPENSSL_PREFIX}" --libdir=lib
        WORKING_DIRECTORY "${_maskpad_openssl_tree}"
        RESULT_VARIABLE _maskpad_openssl_result
    )
    if(NOT _maskpad_openssl_result EQUAL 0)
        message(FATAL_ERROR "OpenSSL Configure failed (${_maskpad_openssl_result})")
    endif()
    execute_process(
        COMMAND make -j${_maskpad_jobs} build_libs
        WORKING_DIRECTORY "${_maskpad_openssl_tree}"
        RESULT_VARIABLE _maskpad_openssl_result
        OUTPUT_QUIET
    )
    if(NOT _maskpad_openssl_result EQUAL 0)
        message(FATAL_ERROR "OpenSSL build failed (${_maskpad_openssl_result})")
    endif()
    execute_process(
        COMMAND make install_dev
        WORKING_DIRECTORY "${_maskpad_openssl_tree}"
        RESULT_VARIABLE _maskpad_openssl_result
        OUTPUT_QUIET
    )
    if(NOT _maskpad_openssl_result EQUAL 0)
        message(FATAL_ERROR "OpenSSL install failed (${_maskpad_openssl_result})")
    endif()
    file(REMOVE_RECURSE "${_maskpad_openssl_source}")
endif()
set(OPENSSL_ROOT_DIR "${MASKPAD_OPENSSL_PREFIX}" CACHE PATH "" FORCE)
set(OPENSSL_INCLUDE_DIR "${MASKPAD_OPENSSL_PREFIX}/include" CACHE PATH "" FORCE)
set(OPENSSL_CRYPTO_LIBRARY "${MASKPAD_OPENSSL_PREFIX}/lib/libcrypto.a" CACHE FILEPATH "" FORCE)
set(OPENSSL_SSL_LIBRARY "${MASKPAD_OPENSSL_PREFIX}/lib/libssl.a" CACHE FILEPATH "" FORCE)
set(OPENSSL_USE_STATIC_LIBS TRUE)

# The CA list the app installs for Archipelago (MaskPadAPSupport.mm): the build Mac's system list.
set(MASKPAD_CA_BUNDLE "${CMAKE_BINARY_DIR}/maskpad-cacert-bundle.crt")
configure_file("/etc/ssl/cert.pem" "${MASKPAD_CA_BUNDLE}" COPYONLY)
