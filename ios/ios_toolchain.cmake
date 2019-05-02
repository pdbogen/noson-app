# cmake -G Xcode \
#  -DCMAKE_TOOLCHAIN_FILE=./ios_toolchain.cmake \
#  -DCMAKE_PREFIX_PATH=~/Qt5.9.1/5.9.1/ios/ \
#  -DBOOST_ROOT=~/Code/SoftwareWorkshop/sw_thirdparties/osx/boost_1_63_0
#  -DBoost_COMPILER=-xgcc42 ../source

# * `IOS`: indicates that the build is being performed for iOS (generic device or simulator)
# * `IOS_PLATFORM`: indicates the platform to compile for. This can be the genuine operating system (`OS`) or the simulator (`SIMULATOR`)
# * `IOS_ARCH`: the architecture to compile. The default is dependant on the `IOS_PLATFORM`:
#    * `armv7;arm64` for the `IOS`
#    * `i386;x86_64` for the `SIMULATOR`
#
# Other variables
#
# * `CMAKE_IOS_SDK_ROOT`: indicates the name of an SDK to choose, defaults to the "most recent" SDK
#
# By default code signing is `OFF`, but should be activated per target in order to have the compilation
# possible for iOS device (Xcode defaults to some ad-hox signing otherwise). This can be done
# through the target properties `XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED`

# TODO
# - documentation
# - detects automatically sdks and target systems from XCode, and lists the sysroots
# - this is for IOS only, not watchOS or anything else
# - indicate the bundle structure for this target system (different than from macOS)
# - indicate how to run tests maybe through `CROSSCOMPILING_EMULATOR`
# - fix the tests
# - find other libraries that clang/clang++ ?


# some relevant doc/resources
# https://developer.apple.com/library/content/documentation/DeveloperTools/Conceptual/cross_development/Using/using.html#//apple_ref/doc/uid/20002000-SW6

# for running simulator
# https://stackoverflow.com/questions/26031601/xcode-6-launch-simulator-from-command-line
# can be consumed with
# https://cmake.org/cmake/help/v3.8/prop_tgt/CROSSCOMPILING_EMULATOR.html

# Raffi: automated code signing
# public.kitware.com/pipermail/cmake/2016.../064602.html
# set_target_properties(app PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY  "PROPER IDENTIFIER")

# listing all signing identities
# security find-identity -v -p codesigning

# signing a binary
# codesign -s my-signing-identity -f ./md5

# signing code manually
# https://developer.apple.com/library/content/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html

# examining a .a
# lipo -info boost_1_63_0_ios/lib/libboost_filesystem.a


set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_VERSION 1)
set(UNIX True)
set(APPLE True)
set(IOS True)

#
if(NOT DEFINED IOS_PLATFORM)
  set(IOS_PLATFORM "OS")
endif()

# left as an example on how to list things from command line utilities
# to be integrated
if(FALSE)
  execute_process(
    COMMAND xcodebuild -sdk -version
    RESULT_VARIABLE
      XCODE_SYSROOT_LISTING_RES
    OUTPUT_VARIABLE
      XCODE_SYSROOT_LISTING
    ERROR_VARIABLE
      XCODE_SYSROOT_LISTING_ERROR
  )

  if(NOT "${XCODE_SYSROOT_LISTING_RES}" STREQUAL "0")
    message(FATAL_ERROR "Cannot list SDKs from xcodebuild. Please make sure XCode is properly installed")
  endif()

  string(REGEX MATCHALL "Path:[ ]*([a-zA-Z0-9/\\. ]+)"
         VAR_MATCH "${XCODE_SYSROOT_LISTING}"
        )
  list(REMOVE_DUPLICATES VAR_MATCH)
  message("${VAR_MATCH}")
endif()


# for each SDK, showing the version:
# xcrun --sdk iphoneos --show-sdk-version

#
# Detect the current XCode
#
if(NOT DEFINED XCODE_ROOT_PATH)
  execute_process(
    COMMAND xcode-select -print-path
    RESULT_VARIABLE
      XCODE_COMPILER_PRINT_PATH_RES
    OUTPUT_VARIABLE
      XCODE_COMPILER_PRINT_PATH
    ERROR_VARIABLE
      XCODE_COMPILER_PRINT_PATH_ERROR
  )
  # Raffi : check errors
  set(_suffix_app ".app")
  string(FIND "${XCODE_COMPILER_PRINT_PATH}" "${_suffix_app}/" VAR_LOCATION_APP)
  string(SUBSTRING "${XCODE_COMPILER_PRINT_PATH}" 0 "${VAR_LOCATION_APP}" XCODE_ROOT_PATH)
  set(XCODE_ROOT_PATH "${XCODE_ROOT_PATH}${_suffix_app}" CACHE STRING "XCode ROOT folder" FORCE)
endif()

#
# Check the platform selection and setup for developer root
if(IOS_PLATFORM STREQUAL "OS")
  set(IOS_PLATFORM_LOCATION "iPhoneOS.platform")
  set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphoneos") # This causes the installers to properly locate the output libraries
elseif(IOS_PLATFORM STREQUAL "SIMULATOR")
  set(IOS_PLATFORM_LOCATION "iPhoneSimulator.platform")
  set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-iphonesimulator")
else()
  message(FATAL_ERROR "Unsupported IOS_PLATFORM value selected. Please choose OS or SIMULATOR")
endif()

# Indicate cross compilation: we suppose that we never perform compilation direclty
# on a device
set(CMAKE_CROSSCOMPILING TRUE)

#
# looking for the compilers
# Check how to do it consistently with XCODE_ROOT_PATH
if(NOT DEFINED XCODE_COMPILER_CLANG)
  execute_process(
    COMMAND xcodebuild -find-executable clang
    RESULT_VARIABLE
      XCODE_COMPILER_CLANG_RES
    OUTPUT_VARIABLE
      XCODE_COMPILER_CLANG
    ERROR_VARIABLE
      XCODE_COMPILER_CLANG_ERROR
  )
  if(NOT "${XCODE_COMPILER_CLANG_RES}" STREQUAL "0")
    message(FATAL_ERROR "IOSToolchain: 'clang' compiler cannot be found")
  endif()
  set(XCODE_COMPILER_CLANG "${XCODE_COMPILER_CLANG}" CACHE STRING "XCode clang compiler" FORCE)
endif()

if(NOT DEFINED XCODE_COMPILER_CLANGPP)
  execute_process(
    COMMAND xcodebuild -find-executable clang++
    RESULT_VARIABLE
      XCODE_COMPILER_CLANGPP_RES
    OUTPUT_VARIABLE
      XCODE_COMPILER_CLANGPP
    ERROR_VARIABLE
      XCODE_COMPILER_CLANGPP_ERROR
  )
  if(NOT "${XCODE_COMPILER_CLANGPP_RES}" STREQUAL "0")
    message(FATAL_ERROR "IOSToolchain: 'clang++' compiler cannot be found")
  endif()
  set(XCODE_COMPILER_CLANGPP "${XCODE_COMPILER_CLANGPP}" CACHE STRING "XCode clang++ compiler" FORCE)
endif()

set(CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING "Force unset of the deployment target for iOS" FORCE)
set(CMAKE_IOS_DEVELOPER_ROOT "${XCODE_ROOT_PATH}/Contents/Developer/Platforms/${IOS_PLATFORM_LOCATION}/Developer")

# Find and use the most recent iOS sdk unless specified manually with CMAKE_IOS_SDK_ROOT
if (NOT DEFINED CMAKE_IOS_SDK_ROOT)
  file(GLOB _CMAKE_IOS_SDKS "${CMAKE_IOS_DEVELOPER_ROOT}/SDKs/*")
  if(_CMAKE_IOS_SDKS)
    list(SORT _CMAKE_IOS_SDKS)
    list(REVERSE _CMAKE_IOS_SDKS)
    list(GET _CMAKE_IOS_SDKS 0 CMAKE_IOS_SDK_ROOT)
  else()
    message(FATAL_ERROR "No iOS SDK's found in default search path ${CMAKE_IOS_DEVELOPER_ROOT}. Manually set CMAKE_IOS_SDK_ROOT or install the iOS SDK.")
  endif()
  message(STATUS "Toolchain using default iOS SDK: ${CMAKE_IOS_SDK_ROOT}")
endif()

set (CMAKE_IOS_SDK_ROOT ${CMAKE_IOS_SDK_ROOT} CACHE PATH "Location of the selected iOS SDK")
# this variable is used all over the places in CMake, we override it with the
# iOS SDK root found
set (CMAKE_OSX_SYSROOT ${CMAKE_IOS_SDK_ROOT} CACHE PATH "Sysroot used for iOS support")

#
# set the architecture for iOS
#
if(NOT DEFINED IOS_ARCH)
  if (IOS_PLATFORM STREQUAL "OS")
    set(CMAKE_SYSTEM_PROCESSOR arm)
    set(IOS_ARCH armv7 arm64)
  elseif(IOS_PLATFORM STREQUAL "SIMULATOR")
    set(CMAKE_SYSTEM_PROCESSOR x86_64)
    set(IOS_ARCH i386 x86_64)
  endif()
endif()
set(CMAKE_OSX_ARCHITECTURES ${IOS_ARCH} CACHE string  "Build architecture for iOS")

# Set the find root to the iOS developer roots and to user defined paths
set(CMAKE_FIND_ROOT_PATH
  ${CMAKE_IOS_DEVELOPER_ROOT}
  ${CMAKE_IOS_SDK_ROOT}
  ${CMAKE_PREFIX_PATH}
  CACHE string  "iOS find search path root"
)

# set up the default search directories for frameworks
set (CMAKE_SYSTEM_FRAMEWORK_PATH
  ${CMAKE_IOS_SDK_ROOT}/System/Library/Frameworks
  ${CMAKE_IOS_SDK_ROOT}/System/Library/PrivateFrameworks
  ${CMAKE_IOS_SDK_ROOT}/Developer/Library/Frameworks
)

# visibility flags
set (CMAKE_CXX_FLAGS_INIT "-fvisibility=hidden -fvisibility-inlines-hidden")

# from https://public.kitware.com/Bug/view.php?id=15329
set(CMAKE_MACOSX_BUNDLE YES)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO")


if(CMAKE_OSX_SYSROOT)
  if(NOT IS_DIRECTORY "${CMAKE_OSX_SYSROOT}")
    message(FATAL_ERROR
      "iOS: The system root directory needed for the selected iOS version and architecture does not exist:\n"
      "  ${CMAKE_OSX_SYSROOT}\n"
      )
  endif()
else()
  message(FATAL_ERROR
    "iOS: No CMAKE_OSX_SYSROOT was selected."
    )
endif()

set(CMAKE_BUILD_TYPE_INIT Debug)

