
set(FERNS_VERSION "1.0.0")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO luiz-monad/ferns
    REF ${FERNS_VERSION}
    SHA512 d74ae3bc340639cbc8b5db41a1fec710acabf8ec828dd28ce3bacf7029d1afd23aeaf47a2273a42995de285daa8aef33a7f90d5c57ef096e2cb872e0845e92b0
    HEAD_REF master
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
)

vcpkg_cmake_install()

vcpkg_copy_pdbs()

file(
    INSTALL ${CMAKE_CURRENT_LIST_DIR}/COPYING
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
    RENAME copyright
)

# # Moves all .cmake files from /debug/share/ferns/ to /share/ferns/
# # See /docs/maintainers/vcpkg_cmake_config_fixup.md for more details
# vcpkg_cmake_config_fixup(CONFIG_PATH cmake TARGET_PATH share/ferns)

# # Handle copyright
file(INSTALL 
    ${SOURCE_PATH}/LICENSE DESTINATION 
    ${CURRENT_PACKAGES_DIR}/share/ferns RENAME copyright)
