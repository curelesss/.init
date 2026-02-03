#!/usr/bin/env bash
# =============================================================================
# configure-cjk-font-priority.sh
# 幂等地设置 Noto CJK 字體優先順序（簡中優先）
# 適用於 Arch Linux 及類似使用 fontconfig 的系統
# =============================================================================

set -u -e -o pipefail

CONFIG_FILE="/etc/fonts/conf.avail/64-language-selector-prefer.conf"
CONFIG_DIR="/etc/fonts/conf.d"
LINK_TARGET="$CONFIG_DIR/64-language-selector-prefer.conf"

# ──────────────────────────────────────────────
# 期望的 XML 內容（完全一致才視為已設定）
# ──────────────────────────────────────────────
read -r -d '' EXPECTED_CONTENT << 'EOF' || true
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
<alias>
<family>sans-serif</family>
<prefer>
<family>Noto Sans CJK SC</family>
<family>Noto Sans CJK TC</family>
<family>Noto Sans CJK JP</family>
</prefer>
</alias>
<!--以上为设置无衬线字体优先度-->
<alias>
<family>monospace</family>
<prefer>
<family>Noto Sans Mono CJK SC</family>
<family>Noto Sans Mono CJK TC</family>
<family>Noto Sans Mono CJK JP</family>
</prefer>
</alias>
<!--以上为设置等宽字体优先度-->
</fontconfig>
EOF

# ──────────────────────────────────────────────
# 自動提升權限
# ──────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo "需要 root 權限，正在重新以 sudo 執行..."
    exec sudo -- "$BASH_SOURCE" "$@"
fi

# ──────────────────────────────────────────────
# 函數：判斷是否需要更新配置文件
# ──────────────────────────────────────────────
needs_update() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 0  # 需要建立
    fi

    local current
    current=$(<"$CONFIG_FILE")

    # 移除所有空白、換行後比較（較寬鬆比對）
    local norm_expected norm_current
    norm_expected=$(echo "$EXPECTED_CONTENT" | tr -d ' \t\n\r')
    norm_current=$(echo "$current"         | tr -d ' \t\n\r')

    if [[ "$norm_expected" != "$norm_current" ]]; then
        return 0  # 內容不同，需要更新
    fi

    return 1  # 已正確，無需修改
}

# ──────────────────────────────────────────────
# 主邏輯
# ──────────────────────────────────────────────
changed=false

echo "正在檢查/設定 Noto CJK 字體優先順序..."

if needs_update; then
    echo "→ 配置文件需要建立或更新：$CONFIG_FILE"
    mkdir -p "$(dirname "$CONFIG_FILE")" 2>/dev/null || true
    printf '%s\n' "$EXPECTED_CONTENT" > "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"
    changed=true
    echo "→ 已寫入配置文件"
else
    echo "→ 配置文件已是期望內容，跳過寫入"
fi

# ──────────────────────────────────────────────
# 處理 conf.d 軟連結
# ──────────────────────────────────────────────
if [[ -d "$CONFIG_DIR" ]]; then
    if [[ -L "$LINK_TARGET" ]]; then
        # 檢查連結是否正確
        if [[ "$(readlink -f "$LINK_TARGET")" = "$(readlink -f "$CONFIG_FILE")" ]]; then
            echo "→ 軟連結已存在且正確，跳過"
        else
            echo "→ 軟連結存在但目標錯誤，正在修正..."
            ln -sf "$CONFIG_FILE" "$LINK_TARGET"
            changed=true
            echo "→ 軟連結已修正"
        fi
    else
        echo "→ 建立軟連結：$LINK_TARGET -> $CONFIG_FILE"
        ln -sf "$CONFIG_FILE" "$LINK_TARGET"
        changed=true
    fi
else
    echo "→ 目錄 $CONFIG_DIR 不存在，跳過建立軟連結"
    echo "   （部分系統不使用 conf.d/ 拆分方式）"
fi

# ──────────────────────────────────────────────
# 更新快取（僅在有實際變更時執行完整重建）
# ──────────────────────────────────────────────
if $changed; then
    echo ""
    echo "→ 檢測到變更，正在更新字體快取..."
    fc-cache -fv
    echo "→ 字體快取更新完成"
else
    echo ""
    echo "→ 無需變更，跳過 fc-cache"
fi

echo ""
echo "設定完成！"
echo "建議：重新啟動應用程式 或 登出/登入 以確保新設定完全生效。"
echo "可安全重複執行此腳本，已正確設定的部分會被自動跳過。"
echo ""

exit 0
