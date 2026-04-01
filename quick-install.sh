#!/bin/bash
# AI DevCopilot 快捷安装脚本
# 使用方法: curl -fsSL https://raw.githubusercontent.com/weieast1314/ai-devcopilot/main/quick-install.sh | bash

set -e

# 切换到 HOME 目录，避免当前目录不存在导致 git clone 失败
cd "$HOME" 2>/dev/null || cd /tmp

# --- 颜色定义 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- 默认配置 ---
REPO_URL="https://github.com/weieast1314/ai-devcopilot.git"
INSTALL_DIR="$HOME/ai-devcopilot"

echo -e "${CYAN}--- AI DevCopilot 快捷安装程序 ---${NC}"
echo ""

# --- 检查依赖 ---
echo -e "${YELLOW}[1/2] 检查依赖${NC}"
check_cmd() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "  ${RED}✗ 未找到命令: $1${NC}"
        return 1
    else
        echo -e "  ${GREEN}✓${NC} $1 已安装"
        return 0
    fi
}

CHECK_FAILED=0
check_cmd "git" || CHECK_FAILED=1

if [ $CHECK_FAILED -eq 1 ]; then
    echo -e "\n${RED}✗ 缺少必需依赖，请安装后重试。${NC}"
    echo "macOS: brew install git"
    echo "Ubuntu/Debian: sudo apt install git"
    exit 1
fi
echo ""

# --- 克隆/更新仓库 ---
echo -e "${YELLOW}[2/2] 下载 AI DevCopilot${NC}"
echo ""

backup_install_dir() {
    local backup_dir
    backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    mv "$INSTALL_DIR" "$backup_dir"
    echo -e "  ${YELLOW}已备份现有目录到: $backup_dir${NC}"
}

clone_repo() {
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR" 2>&1 | while read -r line; do
        echo -e "  $line"
    done
}

update_repo() {
    local current_remote
    local repo_status
    current_remote=$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null || true)
    repo_status=$(git -C "$INSTALL_DIR" status --short --untracked-files=all 2>/dev/null || true)

    if [ "$current_remote" != "$REPO_URL" ]; then
        echo -e "  ${YELLOW}检测到同名目录但远端仓库不匹配，将保留现有目录并重新下载。${NC}"
        backup_install_dir
        clone_repo
        return
    fi

    if [ -n "$repo_status" ]; then
        echo -e "  ${YELLOW}检测到现有安装目录包含本地修改，将保留现有目录并重新下载。${NC}"
        backup_install_dir
        clone_repo
        return
    fi

    echo -e "  ${YELLOW}检测到已有安装目录，正在执行快速更新...${NC}"
    git -C "$INSTALL_DIR" fetch --depth 1 origin main 2>&1 | while read -r line; do
        echo -e "  $line"
    done
    git -C "$INSTALL_DIR" reset --hard FETCH_HEAD >/dev/null 2>&1
    git -C "$INSTALL_DIR" clean -fd >/dev/null 2>&1
}

if [ -d "$INSTALL_DIR/.git" ]; then
    update_repo
elif [ -d "$INSTALL_DIR" ]; then
    echo -e "  ${YELLOW}检测到已有同名目录但不是 Git 仓库，将保留现有目录并重新下载。${NC}"
    backup_install_dir
    clone_repo
else
    clone_repo
fi

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}✗ 下载失败${NC}"
    exit 1
fi

echo -e "  ${GREEN}✓${NC} 下载完成"
echo ""

# --- 打印安装命令 ---
echo -e "${GREEN}--- 下载完成！请复制以下命令执行安装：---${NC}"
echo ""
echo -e "  ${CYAN}cd $INSTALL_DIR && ./install.sh${NC}"
echo ""
echo -e "${YELLOW}可选参数：${NC}"
echo "  -e, --editor <name>   指定编辑器 (claude, codebuddy, opencode)"
echo "  -y, --yes             跳过交互式配置，使用默认值"
echo "      --dry-run         仅输出安装计划，不写入文件"
echo "      --validate-only   校验安装目标与配置路径"
echo ""
echo -e "${YELLOW}示例：${NC}"
echo "  # 交互式安装"
echo "  cd $INSTALL_DIR && ./install.sh"
echo ""
echo "  # 安装到 CodeBuddy"
echo "  cd $INSTALL_DIR && ./install.sh -e codebuddy"
echo ""
echo "  # 安装到 Claude 并跳过配置"
echo "  cd $INSTALL_DIR && ./install.sh -e claude -y"
echo ""
echo "  # 预览安装计划"
echo "  cd $INSTALL_DIR && ./install.sh -e all --dry-run"
echo ""
