#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2025-2026 CyberXHN
#
# 从 Lucky 官网 logo（SVG，内嵌 116x116 PNG）生成 QPKG 所需的两个图标：
#   Lucky.png       —— 应用常规图标（App Center 启用态显示）
#   Lucky_gray.png  —— 灰色图标（App Center 禁用态显示）
#
# 用法: python3 gen_icons.py <logo.svg 或 logo.png> <输出目录> [QPKG_NAME]
#
# 容错:
#   - 输入为 SVG 时提取 data:image/png;base64 内嵌图；提取失败则按 PNG 直接打开
#   - 图标版权归 Lucky 原作者所有，本项目仅打包分发，见 THIRD_PARTY_LICENSES/

import base64
import re
import sys
from pathlib import Path

from PIL import Image

# ITU-R BT.709 亮度权重（与 Photoshop 去色一致），保留原 alpha 通道
W_R, W_G, W_B = 0.2126, 0.7152, 0.0722


def extract_png_from_svg(svg_path: Path):
    """从 SVG 的 data URI 中提取内嵌 PNG。

    返回 (Image, raw_bytes)：raw_bytes 为提取到的原始 PNG 字节（可能为 None）。
    直接落盘原始字节可保证彩色图标与官网源图逐字节一致。
    提取失败则把输入直接当 PNG 打开。
    """
    raw = svg_path.read_bytes()
    m = re.search(rb"data:image/png;base64,([A-Za-z0-9+/=\s]+)[\"'\)]", raw)
    if m:
        try:
            png = base64.b64decode(re.sub(rb"\s", b"", m.group(1)))
            im = Image.open(__import__("io").BytesIO(png))
            im.load()
            return im, png
        except Exception as e:
            print(f"WARN: 内嵌 PNG 提取失败（{e}），尝试按 PNG 直接解析输入")
    return Image.open(svg_path), None


def make_gray(im: Image.Image) -> Image.Image:
    """去饱和为纯灰，保留原 alpha 通道。"""
    im = im.convert("RGBA")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            lum = round(W_R * r + W_G * g + W_B * b)
            px[x, y] = (lum, lum, lum, a)
    return im


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    src = Path(sys.argv[1])
    outdir = Path(sys.argv[2])
    name = sys.argv[3] if len(sys.argv) > 3 else "Lucky"

    if not src.is_file():
        print(f"ERROR: 输入文件不存在: {src}")
        return 1

    try:
        raw_png = None
        if src.suffix.lower() == ".svg":
            im, raw_png = extract_png_from_svg(src)
        else:
            im = Image.open(src)
        im = im.convert("RGBA")
    except Exception as e:
        print(f"ERROR: 无法解析 logo: {e}")
        return 1

    outdir.mkdir(parents=True, exist_ok=True)
    color_path = outdir / f"{name}.png"
    gray_path = outdir / f"{name}_gray.png"

    if raw_png is not None:
        color_path.write_bytes(raw_png)
    else:
        im.save(color_path, "PNG")
    make_gray(im).save(gray_path, "PNG")

    print(f"OK  {color_path}  {im.size[0]}x{im.size[1]}")
    print(f"OK  {gray_path}   {im.size[0]}x{im.size[1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
