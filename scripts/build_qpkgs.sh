#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 CyberXHN
#
# 环境变量：
#   CORE_VERSION     上游核心版本，用于产品目录、压缩包文件名和 QPKG_VER
#   RELEASE_VERSION  完整发布版本，用于 v* 发布目录；可包含任意 Beta 标识
#   QPKG_AUTHOR      QPKG 作者
#   OUTPUT_DIR       成品目录，默认为仓库下的 Lucky-build

set -Eeuo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
: "${CORE_VERSION:?请设置 CORE_VERSION}"
: "${RELEASE_VERSION:?请设置 RELEASE_VERSION}"
: "${QPKG_AUTHOR:?请设置 QPKG_AUTHOR}"
OUTPUT_DIR=${OUTPUT_DIR:-"$ROOT_DIR/Lucky-build"}

if [[ ! $CORE_VERSION =~ ^[0-9][A-Za-z0-9._+-]*$ ]]; then
    echo "无效的 CORE_VERSION: $CORE_VERSION" >&2
    exit 1
fi
if [[ ! $RELEASE_VERSION =~ ^[0-9][A-Za-z0-9._+-]*$ ]]; then
    echo "无效的 RELEASE_VERSION: $RELEASE_VERSION" >&2
    exit 1
fi

readonly RELEASE_BASE_URL="https://release.66666.host"
readonly -a VARIANTS=(
    "xiaojv|Lucky（XiaoJV）|Lucky_XiaoJV"
    "xiaojv_waf|Lucky（XiaoJV WAF）|Lucky_XiaoJV_WAF"
    "lucky|Lucky|Lucky"
    "lucky_docker|Lucky-Docker|Lucky_Docker"
    "xiaoman|Lucky（小满）|Lucky_Xiaoman"
    "wanji|Lucky（万吉）|Lucky_Wanji"
    "wanji_docker|Lucky（万吉Docker）|Lucky_Wanji_Docker"
)
readonly -a ARCHITECTURES=(
    "x86_64:x86_64"
    "arm_64:arm64"
)

WORK_DIR=$(mktemp -d /tmp/lucky-qpkg-build.XXXXXX)
trap 'rm -rf "$WORK_DIR"' EXIT
mkdir -p "$OUTPUT_DIR"

curl_args=()
for variant_spec in "${VARIANTS[@]}"; do
    IFS='|' read -r variant _ _ <<< "$variant_spec"
    for architecture_spec in "${ARCHITECTURES[@]}"; do
        IFS=':' read -r qpkg_arch upstream_arch <<< "$architecture_spec"
        download_dir="$WORK_DIR/$variant/download-$qpkg_arch"
        mkdir -p "$download_dir"

        suffix=""
        if [[ $variant != "lucky" ]]; then
            suffix="_$variant"
        fi
        archive="lucky_${CORE_VERSION}_Linux_${upstream_arch}${suffix}.tar.gz"
        # Beta 标识只拼入最外层发布目录，核心目录和文件名始终使用 CORE_VERSION。
        url="$RELEASE_BASE_URL/v$RELEASE_VERSION/${CORE_VERSION}_$variant/$archive"

        echo "    下载 $variant/$qpkg_arch: $url"
        curl_args+=(--output "$download_dir/core.tar.gz" "$url")
    done
done

echo "==> 并行下载全部核心"
curl --fail --location --show-error --progress-bar \
    --parallel --parallel-immediate --parallel-max 16 \
    --retry 3 --connect-timeout 15 \
    "${curl_args[@]}"

for variant_spec in "${VARIANTS[@]}"; do
    IFS='|' read -r variant display_name artifact_prefix <<< "$variant_spec"
    variant_dir="$WORK_DIR/$variant"
    package_dir="$variant_dir/Lucky"

    echo "==> 构建 $display_name"
    mkdir -p "$package_dir"
    cp -R "$ROOT_DIR/Lucky/." "$package_dir/"
    cp "$ROOT_DIR/LICENSE" "$package_dir/shared/LICENSE"
    cp "$ROOT_DIR/NOTICE" "$package_dir/shared/NOTICE"
    mkdir -p "$package_dir/shared/third-party-licenses"
    cp "$ROOT_DIR"/THIRD_PARTY_LICENSES/*.txt "$package_dir/shared/third-party-licenses/"

    for architecture_spec in "${ARCHITECTURES[@]}"; do
        IFS=':' read -r qpkg_arch _ <<< "$architecture_spec"
        download_dir="$variant_dir/download-$qpkg_arch"
        mkdir -p "$package_dir/$qpkg_arch"

        if [[ ! -s "$download_dir/core.tar.gz" ]]; then
            echo "核心压缩包缺失或为空: $display_name/$qpkg_arch" >&2
            exit 1
        fi
        tar -xzf "$download_dir/core.tar.gz" -C "$download_dir"
        if [[ ! -f "$download_dir/lucky" ]]; then
            echo "压缩包中缺少 lucky 核心: $display_name/$qpkg_arch" >&2
            exit 1
        fi
        install -m 0755 "$download_dir/lucky" "$package_dir/$qpkg_arch/lucky"
    done

    cat > "$package_dir/qpkg.cfg" <<EOF
QPKG_NAME="Lucky"
QPKG_DISPLAY_NAME="$display_name"
QPKG_VER="$CORE_VERSION"
QPKG_AUTHOR="$QPKG_AUTHOR"
QPKG_SUMMARY="$display_name"
QPKG_RC_NUM="101"
QPKG_SERVICE_PROGRAM="lucky.sh"
QPKG_WEB_PORT="16601"
QDK_DATA_DIR_ICONS="icons"
QDK_DATA_DIR_SHARED="shared"
EOF

    (
        cd "$package_dir"
        qbuild
    )

    shopt -s nullglob
    built_files=("$package_dir"/build/Lucky_*)
    shopt -u nullglob
    if (( ${#built_files[@]} == 0 )); then
        echo "QDK 未生成 $display_name 的安装包" >&2
        exit 1
    fi

    for built_file in "${built_files[@]}"; do
        filename=${built_file##*/}
        destination="$OUTPUT_DIR/${artifact_prefix}_${filename#Lucky_}"
        if [[ -e $destination ]]; then
            echo "成品文件已存在: $destination" >&2
            exit 1
        fi
        mv "$built_file" "$destination"
    done
    rm -rf "$variant_dir"
done

shopt -s nullglob
qpkg_files=("$OUTPUT_DIR"/*.qpkg)
shopt -u nullglob
expected_count=$(( ${#VARIANTS[@]} * ${#ARCHITECTURES[@]} ))
if (( ${#qpkg_files[@]} != expected_count )); then
    echo "预期生成 $expected_count 个 QPKG，实际为 ${#qpkg_files[@]} 个" >&2
    exit 1
fi

printf '构建完成：\n'
printf '  %s\n' "${qpkg_files[@]##*/}"
