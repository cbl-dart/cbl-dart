#!/bin/bash

# Get destination directory from first argument or use default
BASE_DIR="${1:-assets}"

# Common variables
CBL_VERSION="3.2.0"
VECTOR_SEARCH_VERSION="1.0.0"
EDITION="enterprise"

# Create base directories
mkdir -p "${BASE_DIR}"/linux "${BASE_DIR}"/macos "${BASE_DIR}"/windows

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

# Hardcoded hashes from the actual structure
get_platform_hash() {
    local os=$1
    case ${os} in
        linux)
            echo "6af4f73a0a0e59cb7e1a272a9fa0828a"
            ;;
        macos)
            echo "c4f61c9bde1085be63f32dd54ca8829e"
            ;;
        windows)
            echo "c2ddf39c36bd6ab58d86b27ddc102286"
            ;;
    esac
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
    local hash=$(get_platform_hash "${os}")
    local lib_dir="${platform_dir}/${hash}"
    
    mkdir -p "${lib_dir}"

    case ${os} in
        linux)
            # CBLite
            download_file "https://packages.couchbase.com/releases/couchbase-lite-c/${CBL_VERSION}/couchbase-lite-c-${EDITION}-${CBL_VERSION}-linux-x86_64.tar.gz" "temp/cblite.tar.gz"
            tar xzf "temp/cblite.tar.gz" -C "temp"
            cp "temp/libcblite-${CBL_VERSION}/lib/x86_64-linux-gnu/libcblite.so."* "${lib_dir}/"
            (cd "${lib_dir}" && rm -f libcblite.so.3 libcblite.so)
            (cd "${lib_dir}" && ln -s "libcblite.so.${CBL_VERSION}" "libcblite.so.3" && ln -s "libcblite.so.3" "libcblite.so")
            
            # CBLiteDart
            download_file "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v8.0.0/couchbase-lite-dart-8.0.0-enterprise-linux-x86_64.tar.gz" "temp/cblitedart.tar.gz"
            tar xzf "temp/cblitedart.tar.gz" -C "temp"
            cp "temp/libcblitedart-8.0.0/lib/x86_64-linux-gnu/libcblitedart.so."* "${lib_dir}/"
            (cd "${lib_dir}" && rm -f libcblitedart.so.8 libcblitedart.so)
            (cd "${lib_dir}" && ln -s "libcblitedart.so.8.0.0" "libcblitedart.so.8" && ln -s "libcblitedart.so.8" "libcblitedart.so")
            
            # Vector Search
            download_file "https://packages.couchbase.com/releases/couchbase-lite-vector-search/${VECTOR_SEARCH_VERSION}/couchbase-lite-vector-search-${VECTOR_SEARCH_VERSION}-linux-x86_64.zip" "temp/vector_search.zip"
            rm -rf "temp/vector_search"
            unzip -o -q "temp/vector_search.zip" -d "temp/vector_search"
            cp "temp/vector_search/lib/CouchbaseLiteVectorSearch.so" "${lib_dir}/"
            cp "temp/vector_search/lib/libgomp.so.1.0.0" "${lib_dir}/"
            (cd "${lib_dir}" && rm -f libgomp.so.1)
            (cd "${lib_dir}" && ln -s "libgomp.so.1.0.0" "libgomp.so.1")
            ;;
            
        macos)
            # CBLite
            download_file "https://packages.couchbase.com/releases/couchbase-lite-c/${CBL_VERSION}/couchbase-lite-c-${EDITION}-${CBL_VERSION}-macos.zip" "temp/cblite.zip"
            unzip -o -q "temp/cblite.zip" -d "temp"
            cp "temp/libcblite-${CBL_VERSION}/lib/libcblite."* "${lib_dir}/"
            (cd "${lib_dir}" && rm -f libcblite.3.dylib libcblite.dylib)
            (cd "${lib_dir}" && ln -s "libcblite.${CBL_VERSION}.dylib" "libcblite.3.dylib" && ln -s "libcblite.3.dylib" "libcblite.dylib")
            
            # CBLiteDart
            download_file "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v8.0.0/couchbase-lite-dart-8.0.0-enterprise-macos.zip" "temp/cblitedart.zip"
            unzip -o -q "temp/cblitedart.zip" -d "temp"
            cp "temp/libcblitedart-8.0.0/lib/libcblitedart."* "${lib_dir}/"
            (cd "${lib_dir}" && rm -f libcblitedart.8.dylib libcblitedart.dylib)
            (cd "${lib_dir}" && ln -s "libcblitedart.8.0.0.dylib" "libcblitedart.8.dylib" && ln -s "libcblitedart.8.dylib" "libcblitedart.dylib")
            
            # Vector Search
            download_file "https://packages.couchbase.com/releases/couchbase-lite-vector-search/${VECTOR_SEARCH_VERSION}/couchbase-lite-vector-search-${VECTOR_SEARCH_VERSION}-macos.zip" "temp/vector_search.zip"
            rm -rf "temp/vector_search"
            unzip -o -q "temp/vector_search.zip" -d "temp/vector_search"
            create_macos_framework "${lib_dir}/CouchbaseLiteVectorSearch.framework" "temp/vector_search/CouchbaseLiteVectorSearch.dylib"
            ;;
            
        windows)
            # CBLite
            download_file "https://packages.couchbase.com/releases/couchbase-lite-c/${CBL_VERSION}/couchbase-lite-c-${EDITION}-${CBL_VERSION}-windows-x86_64.zip" "temp/cblite.zip"
            unzip -o -q "temp/cblite.zip" -d "temp"
            cp "temp/libcblite-${CBL_VERSION}/bin/cblite."* "${lib_dir}/"
            
            # CBLiteDart
            download_file "https://github.com/cbl-dart/cbl-dart/releases/download/libcblitedart-v8.0.0/couchbase-lite-dart-8.0.0-enterprise-windows-x86_64.zip" "temp/cblitedart.zip"
            unzip -o -q "temp/cblitedart.zip" -d "temp"
            cp "temp/libcblitedart-8.0.0/bin/cblitedart."* "${lib_dir}/"
            
            # Vector Search
            download_file "https://packages.couchbase.com/releases/couchbase-lite-vector-search/${VECTOR_SEARCH_VERSION}/couchbase-lite-vector-search-${VECTOR_SEARCH_VERSION}-windows-x86_64.zip" "temp/vector_search.zip"
            rm -rf "temp/vector_search"
            unzip -o -q "temp/vector_search.zip" -d "temp/vector_search"
            cp "temp/vector_search/bin/CouchbaseLiteVectorSearch.dll" "${lib_dir}/"
            cp "temp/vector_search/bin/CouchbaseLiteVectorSearch.pdb" "${lib_dir}/"
            cp "temp/vector_search/bin/libomp140.x86_64.dll" "${lib_dir}/"
            cp "temp/vector_search/lib/CouchbaseLiteVectorSearch.lib" "${lib_dir}/"
            
    esac
}

# Create temp directory
rm -rf temp
mkdir -p temp

# Setup each platform
setup_platform "linux" 
setup_platform "macos"
setup_platform "windows"

# Create zip files
for platform in linux macos windows; do
    (cd "${BASE_DIR}" && zip -r "${platform}.zip" "${platform}")
done

# Cleanup
rm -rf temp

echo "Setup complete! Check the ${BASE_DIR} directory for the results."

# Verify directory structure matches expected
verify_structure() {
    local base_dir="${BASE_DIR}"
    local expected_dirs=("linux" "macos" "windows")
    local expected_hashes=(
        "6af4f73a0a0e59cb7e1a272a9fa0828a" # linux
        "c4f61c9bde1085be63f32dd54ca8829e" # macos
        "c2ddf39c36bd6ab58d86b27ddc102286" # windows
    )

    # Check base directories exist
    for dir in "${expected_dirs[@]}"; do
        if [ ! -d "${base_dir}/${dir}" ]; then
            echo "ERROR: Missing expected directory ${base_dir}/${dir}"
            exit 1
        fi
    done

    # Check hash directories exist with correct content
    for i in "${!expected_dirs[@]}"; do
        local dir="${expected_dirs[$i]}"
        local hash="${expected_hashes[$i]}"
        local hash_dir="${base_dir}/${dir}/${hash}"

        if [ ! -d "${hash_dir}" ]; then
            echo "ERROR: Missing hash directory ${hash_dir}"
            exit 1
        fi

        # Verify platform-specific files
        case ${dir} in
            linux)
                local expected_files=(
                    "CouchbaseLiteVectorSearch.so"
                    "libcblite.so"
                    "libcblite.so.3"
                    "libcblite.so.3.2.0"
                    "libcblitedart.so"
                    "libcblitedart.so.8"
                    "libcblitedart.so.8.0.0"
                    "libgomp.so.1"
                    "libgomp.so.1.0.0"
                )
                ;;
            macos)
                local expected_files=(
                    "CouchbaseLiteVectorSearch.framework"
                    "libcblite.3.2.0.dylib"
                    "libcblite.3.dylib"
                    "libcblite.dylib"
                    "libcblitedart.8.0.0.dylib"
                    "libcblitedart.8.dylib"
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
            if [ ! -e "${hash_dir}/${file}" ]; then
                echo "ERROR: Missing expected file ${hash_dir}/${file}"
                exit 1
            fi
        done

        # Special check for macOS framework structure
        if [[ ${dir} == macos ]]; then
            local framework_dir="${hash_dir}/CouchbaseLiteVectorSearch.framework"
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
rm -rf assets/*.zip