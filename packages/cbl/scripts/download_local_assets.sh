#!/bin/bash

# Default values
BASE_DIR="assets"
PLATFORM="all"
CBL_VERSION="3.2.0"
CBLITEDART_VERSION="8.0.0"
VECTOR_SEARCH_VERSION="1.0.0"
EDITION="enterprise"

# Extract major versions
CBL_MAJOR_VERSION="${CBL_VERSION%%.*}"
CBLITEDART_MAJOR_VERSION="${CBLITEDART_VERSION%%.*}"

# Print help function
print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -d, --dir DIR                 Output directory (default: assets)"
    echo "  -p, --platform PLATFORM       Target platform: all, windows, macos, linux (default: all)"
    echo "  -c, --cbl-version VERSION     Couchbase Lite version (default: 3.2.0)"
    echo "  -t, --cblitedart VERSION      CBLiteDart version (default: 8.0.0)"
    echo "  -v, --vector-search VERSION   Vector Search version (default: 1.0.0)"
    echo "  -e, --edition EDITION         Edition: enterprise or community (default: enterprise)"
    echo "  -h, --help                    Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --dir my_assets --platform windows --cbl-version 3.2.1 --edition community"
    echo "  $0 -d assets -p macos -c 3.2.0 -t 8.0.0 -v 1.0.0 -e enterprise"
}

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--dir) BASE_DIR="$2"; shift ;;
        -p|--platform) PLATFORM="$2"; shift ;;
        -c|--cbl-version) CBL_VERSION="$2"; shift ;;
        -t|--cblitedart) CBLITEDART_VERSION="$2"; shift ;;
        -v|--vector-search) VECTOR_SEARCH_VERSION="$2"; shift ;;
        -e|--edition) EDITION="$2"; shift ;;
        -h|--help) print_help; exit 0 ;;
        *) echo "Unknown parameter: $1"; print_help; exit 1 ;;
    esac
    shift
done

# Validate platform parameter
if [ "$PLATFORM" != "all" ] && [ "$PLATFORM" != "windows" ] && [ "$PLATFORM" != "macos" ] && [ "$PLATFORM" != "linux" ]; then
    echo "ERROR: Invalid platform specified. Must be one of: all, windows, macos, linux"
    exit 1
fi

# Validate edition parameter
if [ "$EDITION" != "enterprise" ] && [ "$EDITION" != "community" ]; then
    echo "ERROR: Invalid edition specified. Must be either: enterprise, community"
    exit 1
fi

# Print configuration
echo "Configuration:"
echo "- Output directory: $BASE_DIR"
echo "- Platform: $PLATFORM"
echo "- CBL Version: $CBL_VERSION"
echo "- CBLiteDart Version: $CBLITEDART_VERSION"
echo "- Vector Search Version: $VECTOR_SEARCH_VERSION"
echo ""

# Create base directories based on platform
if [ "$PLATFORM" = "all" ]; then
    mkdir -p "${BASE_DIR}"/linux "${BASE_DIR}"/macos "${BASE_DIR}"/windows
else
    mkdir -p "${BASE_DIR}/${PLATFORM}"
fi

# Function to check download
check_download() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo "ERROR: Download failed for $file"
        exit 1
    fi
    
    if [[ "$file" == *.zip ]]; then
        if ! unzip -t "$file" > /dev/null 2>&1; then
            echo "ERROR: Invalid zip file $file"
            exit 1
        fi
    elif [[ "$file" == *.tar.gz ]]; then
        if ! tar tzf "$file" > /dev/null 2>&1; then
            echo "ERROR: Invalid tar.gz file $file"
            exit 1
        fi
    fi
}

# Function to download file
download_file() {
    local url=$1
    local output=$2
    echo "Downloading: $url to $output"
    curl -L -o "$output" "$url" || {
        echo "ERROR: Failed to download $url"
        exit 1
    }
    check_download "$output"
}

# Function to create macOS framework structure
create_macos_framework() {
    local framework_dir=$1
    local dylib_path=$2
    
    mkdir -p "${framework_dir}/Versions/A"
    mv "${dylib_path}" "${framework_dir}/Versions/A/CouchbaseLiteVectorSearch"
    cd "${framework_dir}"
    ln -s "Versions/A/CouchbaseLiteVectorSearch" "CouchbaseLiteVectorSearch"
    ln -s "Versions/A" "Current"
    cd - > /dev/null
}

# Function to setup platform
setup_platform() {
    local os=$1
    local platform_dir="${BASE_DIR}/${os}"
    
    mkdir -p "${platform_dir}"

    case ${os} in
        linux)
            # CBLite
            download_file "https://packages.couchbase.com/releases/couchbase-lite-c/${CBL_VERSION}/couchbase-lite-c-${EDITION}-${CBL_VERSION}-linux-x86_64.tar.gz" "temp/cblite.tar.gz"
            tar xzf "temp/cblite.tar.gz" -C "temp"
            cp "temp/libcblite-${CBL_VERSION}/lib/x86_64-linux-gnu/libcblite.so."* "${platform_dir}/"
            (cd "${platform_dir}" && rm -f libcblite.so.${CBL_MAJOR_VERSION} libcblite.so)
            (cd "${platform_dir}" && ln -s "libcblite.so.${CBL_VERSION}" "libcblite.so.${CBL_MAJOR_VERSION}" && ln -s "libcblite.so.${CBL_MAJOR_VERSION}" "libcblite.so")
            
            # CBLiteDart
            download_file "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v${CBLITEDART_VERSION}/couchbase-lite-dart-${CBLITEDART_VERSION}-${EDITION}-linux-x86_64.tar.gz" "temp/cblitedart.tar.gz"
            tar xzf "temp/cblitedart.tar.gz" -C "temp"
            cp "temp/libcblitedart-${CBLITEDART_VERSION}/lib/x86_64-linux-gnu/libcblitedart.so."* "${platform_dir}/"
            (cd "${platform_dir}" && rm -f libcblitedart.so.${CBLITEDART_MAJOR_VERSION} libcblitedart.so)
            (cd "${platform_dir}" && ln -s "libcblitedart.so.${CBLITEDART_VERSION}" "libcblitedart.so.${CBLITEDART_MAJOR_VERSION}" && ln -s "libcblitedart.so.${CBLITEDART_MAJOR_VERSION}" "libcblitedart.so")
            
            # Vector Search
            download_file "https://packages.couchbase.com/releases/couchbase-lite-vector-search/${VECTOR_SEARCH_VERSION}/couchbase-lite-vector-search-${VECTOR_SEARCH_VERSION}-linux-x86_64.zip" "temp/vector_search.zip"
            rm -rf "temp/vector_search"
            unzip -o -q "temp/vector_search.zip" -d "temp/vector_search"
            cp "temp/vector_search/lib/CouchbaseLiteVectorSearch.so" "${platform_dir}/"
            cp "temp/vector_search/lib/libgomp.so.1.0.0" "${platform_dir}/"
            (cd "${platform_dir}" && rm -f libgomp.so.1)
            (cd "${platform_dir}" && ln -s "libgomp.so.1.0.0" "libgomp.so.1")
            ;;
            
        macos)
            # CBLite
            download_file "https://packages.couchbase.com/releases/couchbase-lite-c/${CBL_VERSION}/couchbase-lite-c-${EDITION}-${CBL_VERSION}-macos.zip" "temp/cblite.zip"
            unzip -o -q "temp/cblite.zip" -d "temp"
            cp "temp/libcblite-${CBL_VERSION}/lib/libcblite."* "${platform_dir}/"
            (cd "${platform_dir}" && rm -f libcblite.${CBL_MAJOR_VERSION}.dylib libcblite.dylib)
            (cd "${platform_dir}" && ln -s "libcblite.${CBL_VERSION}.dylib" "libcblite.${CBL_MAJOR_VERSION}.dylib" && ln -s "libcblite.${CBL_MAJOR_VERSION}.dylib" "libcblite.dylib")
            
            # CBLiteDart
            download_file "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v${CBLITEDART_VERSION}/couchbase-lite-dart-${CBLITEDART_VERSION}-${EDITION}-macos.zip" "temp/cblitedart.zip"
            unzip -o -q "temp/cblitedart.zip" -d "temp"
            cp "temp/libcblitedart-${CBLITEDART_VERSION}/lib/libcblitedart."* "${platform_dir}/"
            (cd "${platform_dir}" && rm -f libcblitedart.${CBLITEDART_MAJOR_VERSION}.dylib libcblitedart.dylib)
            (cd "${platform_dir}" && ln -s "libcblitedart.${CBLITEDART_VERSION}.dylib" "libcblitedart.${CBLITEDART_MAJOR_VERSION}.dylib" && ln -s "libcblitedart.${CBLITEDART_MAJOR_VERSION}.dylib" "libcblitedart.dylib")
            
            # Vector Search
            download_file "https://packages.couchbase.com/releases/couchbase-lite-vector-search/${VECTOR_SEARCH_VERSION}/couchbase-lite-vector-search-${VECTOR_SEARCH_VERSION}-macos.zip" "temp/vector_search.zip"
            rm -rf "temp/vector_search"
            unzip -o -q "temp/vector_search.zip" -d "temp/vector_search"
            create_macos_framework "${platform_dir}/CouchbaseLiteVectorSearch.framework" "temp/vector_search/CouchbaseLiteVectorSearch.dylib"
            ;;
            
        windows)
            # CBLite
            download_file "https://packages.couchbase.com/releases/couchbase-lite-c/${CBL_VERSION}/couchbase-lite-c-${EDITION}-${CBL_VERSION}-windows-x86_64.zip" "temp/cblite.zip"
            unzip -o -q "temp/cblite.zip" -d "temp"
            cp "temp/libcblite-${CBL_VERSION}/bin/cblite."* "${platform_dir}/"
            
            # CBLiteDart
            download_file "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v${CBLITEDART_VERSION}/couchbase-lite-dart-${CBLITEDART_VERSION}-${EDITION}-windows-x86_64.zip" "temp/cblitedart.zip"
            unzip -o -q "temp/cblitedart.zip" -d "temp"
            cp "temp/libcblitedart-${CBLITEDART_VERSION}/bin/cblitedart."* "${platform_dir}/"
            
            # Vector Search
            download_file "https://packages.couchbase.com/releases/couchbase-lite-vector-search/${VECTOR_SEARCH_VERSION}/couchbase-lite-vector-search-${VECTOR_SEARCH_VERSION}-windows-x86_64.zip" "temp/vector_search.zip"
            rm -rf "temp/vector_search"
            unzip -o -q "temp/vector_search.zip" -d "temp/vector_search"
            cp "temp/vector_search/bin/CouchbaseLiteVectorSearch.dll" "${platform_dir}/"
            cp "temp/vector_search/bin/CouchbaseLiteVectorSearch.pdb" "${platform_dir}/"
            cp "temp/vector_search/bin/libomp140.x86_64.dll" "${platform_dir}/"
            cp "temp/vector_search/lib/CouchbaseLiteVectorSearch.lib" "${platform_dir}/"
            ;;
    esac
}

# Create temp directory
rm -rf temp
mkdir -p temp

# Setup platforms based on parameter
if [ "$PLATFORM" = "all" ]; then
    setup_platform "linux" 
    setup_platform "macos"
    setup_platform "windows"
else
    setup_platform "$PLATFORM"
fi

# Create zip files only for selected platform(s)
if [ "$PLATFORM" = "all" ]; then
    for platform in linux macos windows; do
        (cd "${BASE_DIR}" && zip -r "${platform}.zip" "${platform}")
    done
else
    (cd "${BASE_DIR}" && zip -r "${PLATFORM}.zip" "${PLATFORM}")
fi

# Cleanup
rm -rf temp

echo "Setup complete! Check the ${BASE_DIR} directory for the results."

# Verify directory structure matches expected
verify_structure() {
    local base_dir="${BASE_DIR}"
    local expected_dirs=()

    if [ "$PLATFORM" = "all" ]; then
        expected_dirs=("linux" "macos" "windows")
    else
        expected_dirs=("$PLATFORM")
    fi

    for dir in "${expected_dirs[@]}"; do
        if [ ! -d "${base_dir}/${dir}" ]; then
            echo "ERROR: Missing expected directory ${base_dir}/${dir}"
            exit 1
        fi

        case ${dir} in
            linux)
                local expected_files=(
                    "CouchbaseLiteVectorSearch.so"
                    "libcblite.so"
                    "libcblite.so.${CBL_MAJOR_VERSION}"
                    "libcblite.so.${CBL_VERSION}"
                    "libcblitedart.so"
                    "libcblitedart.so.${CBLITEDART_MAJOR_VERSION}"
                    "libcblitedart.so.${CBLITEDART_VERSION}"
                    "libgomp.so.1"
                    "libgomp.so.1.0.0"
                )
                ;;
            macos)
                local expected_files=(
                    "CouchbaseLiteVectorSearch.framework"
                    "libcblite.${CBL_VERSION}.dylib"
                    "libcblite.${CBL_MAJOR_VERSION}.dylib"
                    "libcblite.dylib"
                    "libcblitedart.${CBLITEDART_VERSION}.dylib"
                    "libcblitedart.${CBLITEDART_MAJOR_VERSION}.dylib"
                    "libcblitedart.dylib"
                )
                ;;
            windows)
                local expected_files=(
                    "CouchbaseLiteVectorSearch.dll"
                    "CouchbaseLiteVectorSearch.pdb"
                    "cblite.dll"
                    "cblitedart.dll"
                    "cblitedart.pdb"
                    "libomp140.x86_64.dll"
                )
                ;;
        esac

        for file in "${expected_files[@]}"; do
            if [ ! -e "${base_dir}/${dir}/${file}" ]; then
                echo "ERROR: Missing expected file ${base_dir}/${dir}/${file}"
                exit 1
            fi
        done

        # Special check for macOS framework structure
        if [[ ${dir} == macos ]]; then
            local framework_dir="${base_dir}/${dir}/CouchbaseLiteVectorSearch.framework"
            if [ ! -d "${framework_dir}/Versions/A" ] || \
               [ ! -e "${framework_dir}/CouchbaseLiteVectorSearch" ] || \
               [ ! -e "${framework_dir}/Versions/A/CouchbaseLiteVectorSearch" ]; then
                echo "ERROR: Invalid framework structure in ${framework_dir}"
                exit 1
            fi
        fi
    done

    echo "Directory structure verification complete - all files present and correct"
}

verify_structure

# remove assets/*.zip
rm -rf "${BASE_DIR}"/*.zip

# Print all downloaded files and their locations in tree structure
echo -e "\nDownloaded files and locations:"
echo "================================="

# Only show tree for selected platform(s)
if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "linux" ]; then
    echo -e "\n🐧 Linux Files:"
    echo "--------------"
    find "${BASE_DIR}/linux" -type d -o -type f -o -type l 2>/dev/null | sed -e "s/[^-][^\/]*\// |--/g" -e "s/|\([^ ]\)/|-\1/" | while read -r line; do
        file="${BASE_DIR}/linux/${line#*-- }"
        if [ -L "$file" ]; then
            target=$(readlink -f "$file")
            echo "$line -> $target 🔗" 
        else
            echo "$line"
        fi
    done || {
        echo "ERROR: Failed to list Linux files"
        exit 1
    }
fi

if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "macos" ]; then
    echo -e "\n🍎 macOS Files:"
    echo "--------------" 
    find "${BASE_DIR}/macos" -type d -o -type f -o -type l 2>/dev/null | sed -e "s/[^-][^\/]*\// |--/g" -e "s/|\([^ ]\)/|-\1/" | while read -r line; do
        file="${BASE_DIR}/macos/${line#*-- }"
        if [ -L "$file" ]; then
            target=$(readlink -f "$file")
            echo "$line -> $target 🔗"
        else
            echo "$line"
        fi
    done || {
        echo "ERROR: Failed to list macOS files"
        exit 1
    }
fi

if [ "$PLATFORM" = "all" ] || [ "$PLATFORM" = "windows" ]; then
    echo -e "\n🪟 Windows Files:"
    echo "---------------"
    find "${BASE_DIR}/windows" -type d -o -type f -o -type l 2>/dev/null | sed -e "s/[^-][^\/]*\// |--/g" -e "s/|\([^ ]\)/|-\1/" | while read -r line; do
        file="${BASE_DIR}/windows/${line#*-- }"
        if [ -L "$file" ]; then
            target=$(readlink -f "$file")
            echo "$line -> $target 🔗"
        else
            echo "$line"
        fi
    done || {
        echo "ERROR: Failed to list Windows files"
        exit 1
    }
fi
