#!/bin/bash

# ===========================================
# 简化版Markdown报告生成脚本
# 功能：从HTML报告提取关键检查项的通过/失败状态，生成简洁的Markdown报告
# 使用方法: ./generate_simplified_markdown_report.sh [源目录]
# ===========================================

echo "📝 Kubernetes集群简化Markdown报告生成工具"
echo "=============================================="

# 配置变量
SOURCE_DIR="${1:-./cluster_check_results}"
REPORT_DIR="./report"
OUTPUT_FILE="${REPORT_DIR}/simplified_cluster_report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 检查源目录是否存在
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "❌ 错误: 源目录 $SOURCE_DIR 不存在"
    echo "请确保已运行集群检查并生成了检查结果"
    exit 1
fi

# 检查是否有HTML报告文件
html_files_count=$(find "$SOURCE_DIR" -name "*.html" -type f | wc -l)
if [[ $html_files_count -eq 0 ]]; then
    echo "❌ 错误: 在 $SOURCE_DIR 目录下没有找到HTML报告文件"
    echo "请先运行集群检查生成各节点的检查报告"
    exit 1
fi

echo "📁 源目录: $SOURCE_DIR"
echo "📁 输出目录: $REPORT_DIR" 
echo "📄 找到 $html_files_count 个HTML报告文件"

# 提取检查项状态的函数
extract_check_status() {
    local report_file="$1"
    local check_type="$2"
    
    if [[ ! -f "$report_file" ]]; then
        echo "❓"
        return
    fi
    
    case "$check_type" in
        "system")
            # 系统配置检查
            if grep -q "status success.*✅\|status success.*成功" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "status error.*❌\|status error.*失败" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "status warning.*⚠️\|status warning.*警告" "$report_file" 2>/dev/null; then
                echo "⚠️"
            else
                echo "❓"
            fi
            ;;
        "firewall")
            # 防火墙检查
            if grep -q "Firewalld.*status success.*已关闭\|UFW.*status success.*已关闭" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "Firewalld.*status error.*运行中\|UFW.*status error.*运行中" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "selinux")
            # SELinux检查
            if grep -q "SELinux.*status success.*已禁用\|SELinux.*status success.*未安装" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "SELinux.*status error" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "swap")
            # Swap检查
            if grep -q "Swap.*status success.*已禁用" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "Swap.*status error.*启用中" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "timezone")
            # 时区检查
            if grep -q "时区.*status success.*Asia/Shanghai" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "时区.*status error" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "time_sync")
            # 时间同步检查
            if grep -q "Chronyd.*status success.*运行中\|NTP.*status success.*运行中" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "时间同步.*status error.*未配置" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "kubelet")
            # kubelet检查
            if grep -q "kubelet.*status success.*✅" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "kubelet.*status error.*未安装" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "kubectl")
            # kubectl检查
            if grep -q "kubectl.*status success.*✅" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "kubectl.*status error.*未安装\|kubectl.*status warning.*未安装" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "kubeadm")
            # kubeadm检查
            if grep -q "kubeadm.*status success.*✅" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "kubeadm.*status error.*未安装" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "container_runtime")
            # 容器运行时检查
            if grep -q "Docker.*status success.*✅\|Containerd.*status success.*✅" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "Docker.*status error.*未安装\|Containerd.*status warning.*未找到" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "data_directory")
            # 数据目录检查 (新增功能)
            if grep -q "数据目录检查.*status success.*正确位置\|数据目录.*status success.*✅" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "数据目录检查.*status error.*位于/home\|数据目录.*status error.*❌" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "数据目录检查.*status warning.*部分位于/home\|数据目录.*status warning.*⚠️" "$report_file" 2>/dev/null; then
                echo "⚠️"
            else
                echo "❓"
            fi
            ;;
        "kubernetes_components")
            # Kubernetes组件检查 (仅Master节点)
            if grep -q "kube-apiserver.*status success.*运行中\|kube-controller-manager.*status success.*运行中\|kube-scheduler.*status success.*运行中" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "kube-apiserver.*status error.*状态异常\|kube-controller-manager.*status error.*状态异常\|kube-scheduler.*status error.*状态异常" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        "etcd")
            # etcd检查 (仅Master节点)
            if grep -q "etcd.*status success.*运行中\|etcd Pod模式.*status success.*检测到" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "etcd.*status error.*未找到" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "etcd.*status warning.*未运行或使用Pod模式" "$report_file" 2>/dev/null; then
                echo "⚠️"
            else
                echo "❓"
            fi
            ;;
        "gpu")
            # GPU检查 (仅GPU Worker节点)
            if grep -q "NVIDIA SMI.*status success.*可用\|GPU.*status success.*✅" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "NVIDIA SMI.*status error.*不可用\|GPU.*status error.*❌" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "NVIDIA.*status warning.*未加载" "$report_file" 2>/dev/null; then
                echo "⚠️"
            else
                echo "❓"
            fi
            ;;
        "dcgm")
            # DCGM检查 (仅GPU Worker节点)
            if grep -q "DCGM.*status success.*可用" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "DCGM.*status warning.*不可用" "$report_file" 2>/dev/null; then
                echo "⚠️"
            else
                echo "❓"
            fi
            ;;
        *)
            echo "❓"
            ;;
    esac
}

# 获取节点信息的函数
get_node_info() {
    local report_file="$1"
    local info_type="$2"
    
    case "$info_type" in
        "hostname")
            grep -o "节点: [^|]*" "$report_file" 2>/dev/null | cut -d' ' -f2 | head -1 || echo "Unknown"
            ;;
        "node_type")
            if [[ "$report_file" =~ master ]]; then
                echo "Master"
            elif [[ "$report_file" =~ gpu_worker ]]; then
                echo "GPU Worker"
            elif [[ "$report_file" =~ cpu_worker ]]; then
                echo "CPU Worker"
            else
                echo "Unknown"
            fi
            ;;
        "check_time")
            grep -o "时间: [^)]*" "$report_file" 2>/dev/null | cut -d' ' -f2- | head -1 || echo "Unknown"
            ;;
    esac
}

# 开始生成Markdown报告
echo "🔄 生成简化Markdown报告..."

cat > "$OUTPUT_FILE" << EOF
# Kubernetes集群健康检查报告 (简化版)

**生成时间**: $TIMESTAMP  
**报告类型**: 仅显示通过/失败状态的简化报告

---

## 📊 集群状态总览

EOF

# 处理每个HTML报告文件
declare -a all_reports=()
for report_file in "$SOURCE_DIR"/*.html; do
    if [[ -f "$report_file" ]]; then
        all_reports+=("$report_file")
    fi
done

# 按节点类型分组处理
echo "### Master节点" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| 节点名称 | 防火墙 | SELinux | Swap | 时区 | 时间同步 | kubelet | kubectl | kubeadm | 容器运行时 | 数据目录 | K8s组件 | etcd |" >> "$OUTPUT_FILE"
echo "|----------|--------|---------|------|------|----------|---------|---------|---------|------------|----------|---------|------|" >> "$OUTPUT_FILE"

master_found=false
for report_file in "${all_reports[@]}"; do
    if [[ "$report_file" =~ master ]]; then
        master_found=true
        hostname=$(get_node_info "$report_file" "hostname")
        firewall=$(extract_check_status "$report_file" "firewall")
        selinux=$(extract_check_status "$report_file" "selinux")
        swap=$(extract_check_status "$report_file" "swap")
        timezone=$(extract_check_status "$report_file" "timezone")
        time_sync=$(extract_check_status "$report_file" "time_sync")
        kubelet=$(extract_check_status "$report_file" "kubelet")
        kubectl=$(extract_check_status "$report_file" "kubectl")
        kubeadm=$(extract_check_status "$report_file" "kubeadm")
        container_runtime=$(extract_check_status "$report_file" "container_runtime")
        data_directory=$(extract_check_status "$report_file" "data_directory")
        k8s_components=$(extract_check_status "$report_file" "kubernetes_components")
        etcd=$(extract_check_status "$report_file" "etcd")
        
        echo "| $hostname | $firewall | $selinux | $swap | $timezone | $time_sync | $kubelet | $kubectl | $kubeadm | $container_runtime | $data_directory | $k8s_components | $etcd |" >> "$OUTPUT_FILE"
    fi
done

if [[ "$master_found" == false ]]; then
    echo "| - | - | - | - | - | - | - | - | - | - | - | - | - |" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "### CPU Worker节点" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| 节点名称 | 防火墙 | SELinux | Swap | 时区 | 时间同步 | kubelet | kubectl | kubeadm | 容器运行时 | 数据目录 |" >> "$OUTPUT_FILE"
echo "|----------|--------|---------|------|------|----------|---------|---------|---------|------------|----------|" >> "$OUTPUT_FILE"

cpu_worker_found=false
for report_file in "${all_reports[@]}"; do
    if [[ "$report_file" =~ cpu_worker ]]; then
        cpu_worker_found=true
        hostname=$(get_node_info "$report_file" "hostname")
        firewall=$(extract_check_status "$report_file" "firewall")
        selinux=$(extract_check_status "$report_file" "selinux")
        swap=$(extract_check_status "$report_file" "swap")
        timezone=$(extract_check_status "$report_file" "timezone")
        time_sync=$(extract_check_status "$report_file" "time_sync")
        kubelet=$(extract_check_status "$report_file" "kubelet")
        kubectl=$(extract_check_status "$report_file" "kubectl")
        kubeadm=$(extract_check_status "$report_file" "kubeadm")
        container_runtime=$(extract_check_status "$report_file" "container_runtime")
        data_directory=$(extract_check_status "$report_file" "data_directory")
        
        echo "| $hostname | $firewall | $selinux | $swap | $timezone | $time_sync | $kubelet | $kubectl | $kubeadm | $container_runtime | $data_directory |" >> "$OUTPUT_FILE"
    fi
done

if [[ "$cpu_worker_found" == false ]]; then
    echo "| - | - | - | - | - | - | - | - | - | - | - |" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"
echo "### GPU Worker节点" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| 节点名称 | 防火墙 | SELinux | Swap | 时区 | 时间同步 | kubelet | kubectl | kubeadm | 容器运行时 | 数据目录 | GPU | DCGM |" >> "$OUTPUT_FILE"
echo "|----------|--------|---------|------|------|----------|---------|---------|---------|------------|----------|-----|------|" >> "$OUTPUT_FILE"

gpu_worker_found=false
for report_file in "${all_reports[@]}"; do
    if [[ "$report_file" =~ gpu_worker ]]; then
        gpu_worker_found=true
        hostname=$(get_node_info "$report_file" "hostname")
        firewall=$(extract_check_status "$report_file" "firewall")
        selinux=$(extract_check_status "$report_file" "selinux")
        swap=$(extract_check_status "$report_file" "swap")
        timezone=$(extract_check_status "$report_file" "timezone")
        time_sync=$(extract_check_status "$report_file" "time_sync")
        kubelet=$(extract_check_status "$report_file" "kubelet")
        kubectl=$(extract_check_status "$report_file" "kubectl")
        kubeadm=$(extract_check_status "$report_file" "kubeadm")
        container_runtime=$(extract_check_status "$report_file" "container_runtime")
        data_directory=$(extract_check_status "$report_file" "data_directory")
        gpu=$(extract_check_status "$report_file" "gpu")
        dcgm=$(extract_check_status "$report_file" "dcgm")
        
        echo "| $hostname | $firewall | $selinux | $swap | $timezone | $time_sync | $kubelet | $kubectl | $kubeadm | $container_runtime | $data_directory | $gpu | $dcgm |" >> "$OUTPUT_FILE"
    fi
done

if [[ "$gpu_worker_found" == false ]]; then
    echo "| - | - | - | - | - | - | - | - | - | - | - | - | - |" >> "$OUTPUT_FILE"
fi

# 添加图例说明
cat >> "$OUTPUT_FILE" << 'EOF'

---

## 📖 状态图例

- ✅ **通过**: 检查项配置正确
- ❌ **失败**: 检查项存在问题，需要修复
- ⚠️ **警告**: 检查项可能存在潜在问题
- ❓ **未知**: 无法获取检查状态

## 🔍 检查项说明

### 通用检查项
- **防火墙**: firewalld和ufw应该关闭
- **SELinux**: 应该禁用或未安装
- **Swap**: 应该禁用
- **时区**: 建议设置为Asia/Shanghai
- **时间同步**: chronyd或ntp应该运行
- **kubelet**: Kubernetes节点代理
- **kubectl**: Kubernetes命令行工具
- **kubeadm**: Kubernetes集群初始化工具
- **容器运行时**: Docker或Containerd
- **数据目录**: kubelet、containerd、docker数据目录不应位于/home

### Master节点专用检查项
- **K8s组件**: kube-apiserver, kube-controller-manager, kube-scheduler
- **etcd**: 集群数据存储

### GPU Worker节点专用检查项
- **GPU**: NVIDIA驱动和工具
- **DCGM**: GPU监控和管理工具

---

**生成工具**: Kubernetes集群健康检查工具 v2.2  
**详细报告**: 请查看同目录下的HTML报告文件获取详细信息
EOF

echo "✅ 简化Markdown报告生成完成"
echo "📄 报告文件: $OUTPUT_FILE"
echo ""
echo "📋 报告摘要:"
echo "   Master节点: $(grep -c master <<< "${all_reports[*]}")"
echo "   CPU Worker节点: $(grep -c cpu_worker <<< "${all_reports[*]}")"
echo "   GPU Worker节点: $(grep -c gpu_worker <<< "${all_reports[*]}")"
echo ""
echo "💡 提示: 可以使用Markdown查看器或编辑器打开报告文件"
