#!/bin/bash

# 统一报告生成脚本  
# 用于汇总本地cluster_check_results目录下的所有节点检查结果并生成HTML表格报告
# 要求bash 4.0+支持关联数组
#
# 使用方法:
#   ./generate_unified_report.sh [源目录]
#
# 参数说明:
#   源目录: 包含HTML检查报告的目录，默认为 ./cluster_check_results
#
# 输出说明:
#   - 统一汇总报告: ./report/unified_cluster_report.html
#   - 详细报告副本: ./report/ 目录下的各节点HTML文件

echo "🔍 Kubernetes集群检查报告汇总工具"
echo "=========================================="

# 配置变量
SOURCE_DIR="${1:-./cluster_check_results}"
REPORT_DIR="./report"
OUTPUT_FILE="${REPORT_DIR}/unified_cluster_report.html"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 颜色定义
GREEN='#28a745'
RED='#dc3545'
YELLOW='#ffc107'
GRAY='#6c757d'
BLUE='#007bff'

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 检查源目录是否存在
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "❌ 错误: 源目录 $SOURCE_DIR 不存在"
    echo "请确保已运行集群检查并生成了检查结果"
    exit 1
fi

# 清理历史报告文件，只保留最新格式的文件
echo "🧹 清理历史报告文件..."
cleanup_old_reports() {
    local source_dir="$1"
    
    # 使用临时文件存储主机文件映射，兼容老版本bash
    local temp_mapping="/tmp/host_files_$$"
    touch "$temp_mapping"
    
    for file in "$source_dir"/*_check_report_*.html; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file" .html)
            
            # 跳过统一报告文件
            if [[ "$filename" == "unified_cluster_report"* ]]; then
                continue
            fi
            
            # 提取主机标识（去除IP后的部分）
            local host_key
            if [[ "$filename" =~ ^(.+_check_report_.+)_[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                # 带IP的新格式文件
                host_key="${BASH_REMATCH[1]}"
            else
                # 旧格式文件（不带IP）
                host_key="$filename"
            fi
            
            # 获取文件修改时间
            local file_time=$(stat -f "%m" "$file" 2>/dev/null || stat -c "%Y" "$file" 2>/dev/null)
            
            # 检查是否已有该主机的记录
            local existing_record=$(grep "^$host_key|" "$temp_mapping" 2>/dev/null)
            
            if [[ -z "$existing_record" ]]; then
                # 第一次遇到这个主机
                echo "$host_key|$file|$file_time" >> "$temp_mapping"
            else
                # 比较时间，保留最新的
                local existing_file=$(echo "$existing_record" | cut -d'|' -f2)
                local existing_time=$(echo "$existing_record" | cut -d'|' -f3)
                
                if [[ $file_time -gt $existing_time ]]; then
                    # 当前文件更新，删除旧文件
                    echo "  🗑️  删除旧版本: $(basename "$existing_file")"
                    rm -f "$existing_file"
                    # 更新记录
                    sed -i.bak "/^$host_key|/d" "$temp_mapping"
                    echo "$host_key|$file|$file_time" >> "$temp_mapping"
                else
                    # 当前文件是旧的，删除它
                    echo "  🗑️  删除旧版本: $(basename "$file")"
                    rm -f "$file"
                fi
            fi
        fi
    done
    
    # 清理临时文件
    rm -f "$temp_mapping" "$temp_mapping.bak"
}

# 执行清理
cleanup_old_reports "$SOURCE_DIR"

# 检查是否有报告文件（HTML优先，TXT为备选）
html_files_count=$(find "$SOURCE_DIR" -name "*.html" -type f | wc -l)
txt_files_count=$(find "$SOURCE_DIR" -name "*.txt" -type f | wc -l)

if [[ $html_files_count -gt 0 ]]; then
    echo "📁 源目录: $SOURCE_DIR"
    echo "📁 输出目录: $REPORT_DIR" 
    echo "📄 找到 $html_files_count 个最新HTML报告文件"
    file_pattern="*.html"
elif [[ $txt_files_count -gt 0 ]]; then
    echo "📁 源目录: $SOURCE_DIR"
    echo "📁 输出目录: $REPORT_DIR" 
    echo "📄 找到 $txt_files_count 个TXT报告文件（简化模式）"
    file_pattern="*.txt"
else
    echo "❌ 错误: 在 $SOURCE_DIR 目录下没有找到报告文件（HTML或TXT）"
    echo "请先运行集群检查生成各节点的检查报告"
    exit 1
fi

# 复制所有报告文件到报告目录，以便统一报告可以链接到详细报告
echo "📋 复制详细报告文件到输出目录..."
if [[ "$file_pattern" == "*.html" ]]; then
    find "$SOURCE_DIR" -name "*.html" -type f -exec cp {} "$REPORT_DIR/" \;
else
    find "$SOURCE_DIR" -name "*.txt" -type f -exec cp {} "$REPORT_DIR/" \;
fi

# 生成HTML头部
cat > "$OUTPUT_FILE" << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kubernetes 集群健康检查报告</title>
    <style>
        body {
            font-family: 'Microsoft YaHei', 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 20px;
            background-color: #f8f9fa;
            color: #333;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .header h1 {
            margin: 0;
            font-size: 2em;
        }
        .header .subtitle {
            margin: 5px 0 0 0;
            opacity: 0.9;
        }
        .summary {
            background: white;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .table-container {
            background: white;
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            overflow-x: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th, td {
            padding: 12px 8px;
            text-align: center;
            border: 1px solid #dee2e6;
            white-space: nowrap;
        }
        th {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            font-weight: bold;
            color: #495057;
        }
        tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .status-badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 0.85em;
            display: inline-block;
            min-width: 60px;
        }
        .status-ok { background-color: #d4edda; color: #155724; }
        .status-failed { background-color: #f8d7da; color: #721c24; }
        .status-warning { background-color: #fff3cd; color: #856404; }
        .status-na { background-color: #e2e3e5; color: #383d41; }
        .status-unknown { background-color: #cce7ff; color: #0c5460; }
        .node-type {
            font-weight: bold;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 0.85em;
        }
        .master { background-color: #e1f5fe; color: #01579b; }
        .gpu-worker { background-color: #f3e5f5; color: #4a148c; }
        .cpu-worker { background-color: #e8f5e8; color: #1b5e20; }
        .details-link {
            color: #007bff;
            text-decoration: none;
            font-size: 0.9em;
        }
        .details-link:hover {
            text-decoration: underline;
        }
        .summary-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 15px;
        }
        .stat-card {
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            border-left: 4px solid #007bff;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #007bff;
        }
        .stat-label {
            color: #6c757d;
            margin-top: 5px;
        }
        @media (max-width: 768px) {
            body { margin: 10px; }
            .header { padding: 15px; }
            .header h1 { font-size: 1.5em; }
            th, td { padding: 8px 4px; font-size: 0.9em; }
        }
    </style>
</head>
<body>
EOF

# 添加报告头部信息
echo "<div class=\"header\">" >> "$OUTPUT_FILE"
echo "<h1>🔍 Kubernetes 集群健康检查报告</h1>" >> "$OUTPUT_FILE"
echo "<div class=\"subtitle\">生成时间: $TIMESTAMP</div>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

# 状态提取函数
extract_status() {
    local report_file="$1"
    local check_type="$2"
    
    if [[ ! -f "$report_file" ]]; then
        echo "N/A"
        return
    fi
    
    # 判断文件类型
    local file_ext="${report_file##*.}"
    
    case "$check_type" in
        "system")
            # 系统检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查 - 优先检查问题状态
                if grep -q "❌.*系统配置检查\|❌.*防火墙\|❌.*SELinux\|❌.*Swap\|❌.*时区\|❌.*CPU调频策略.*powersave\|❌.*CPU调频.*powersave" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "⚠️.*系统配置检查\|⚠️.*防火墙\|⚠️.*SELinux\|⚠️.*Swap\|⚠️.*时区\|⚠️.*CPU调频策略\|⚠️.*CPU调频" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif grep -q "✅.*系统配置检查\|✅.*防火墙\|✅.*SELinux\|✅.*Swap\|✅.*时区\|✅.*CPU调频策略.*performance\|✅.*CPU调频.*performance" "$report_file" 2>/dev/null; then
                    echo "OK"
                else
                    echo "UNKNOWN"
                fi
            else
                # HTML文件格式检查 - 优先检查问题状态
                if grep -q "系统检查:.*error.*失败\|系统检查:.*<span.*error.*失败\|CPU调频策略.*error.*powersave\|CPU调频.*error.*powersave" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "系统检查:.*warning.*警告\|系统检查:.*<span.*warning.*警告\|CPU调频策略.*warning\|CPU调频.*warning" "$report_file" 2>/dev/null || \
                     (grep -q "CPU调频策略" "$report_file" && grep -q "status warning" "$report_file") 2>/dev/null; then
                    echo "WARNING"
                elif grep -q "系统检查:.*success.*成功\|系统检查:.*<span.*success.*成功\|CPU调频策略.*success.*performance\|CPU调频.*success.*performance" "$report_file" 2>/dev/null || \
                     (grep -q "CPU调频策略" "$report_file" && grep -q "status success" "$report_file") 2>/dev/null; then
                    echo "OK"
                else
                    echo "UNKNOWN"
                fi
            fi
            ;;
        "kubernetes")
            # Kubernetes检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查
                if grep -q "✅.*kubelet\|✅.*kubeadm\|✅.*kubectl" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "❌.*kubelet\|❌.*kubeadm" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "⚠️.*kubectl" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                else
                    echo "UNKNOWN"
                fi
            else
                # HTML文件格式检查
                if grep -q "Kubernetes检查:.*success.*成功\|Kubernetes检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "Kubernetes检查:.*error.*失败\|Kubernetes检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "Kubernetes检查:.*warning.*警告\|Kubernetes检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif grep -q "kubectl.*未找到" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "UNKNOWN"
                fi
            fi
            ;;
        "gpu")
            # GPU/DCGM检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查
                if grep -q "✅.*NVIDIA SMI\|✅.*DCGM" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "❌.*NVIDIA SMI\|❌.*DCGM" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "⚠️.*DCGM" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif ! grep -q "NVIDIA SMI\|DCGM" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "UNKNOWN"
                fi
            else
                # HTML文件格式检查
                if grep -q "GPU.*检查:.*success.*成功\|GPU.*检查:.*<span.*success.*成功\|DCGM.*检查:.*success.*成功\|DCGM.*检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "GPU.*检查:.*error.*失败\|GPU.*检查:.*<span.*error.*失败\|DCGM.*检查:.*error.*失败\|DCGM.*检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "GPU.*检查:.*warning.*警告\|GPU.*检查:.*<span.*warning.*警告\|DCGM.*检查:.*warning.*警告\|DCGM.*检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif ! grep -q "GPU.*检查\|DCGM.*检查" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "UNKNOWN"
                fi
            fi
            ;;
        "ib")
            # InfiniBand检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查
                if grep -q "✅.*ibstat工具.*已安装\|✅.*IB端口状态.*Active" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "❌.*ibstat工具\|❌.*IB端口状态" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "⚠️.*ibstat工具\|⚠️.*IB端口状态" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif ! grep -q "ibstat\|InfiniBand\|IB端口" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "UNKNOWN"
                fi
            else
                # HTML文件格式检查
                if grep -q "InfiniBand.*检查:.*success.*成功\|InfiniBand.*检查:.*<span.*success.*成功\|IB.*检查:.*success.*成功\|IB.*检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "InfiniBand.*检查:.*error.*失败\|InfiniBand.*检查:.*<span.*error.*失败\|IB.*检查:.*error.*失败\|IB.*检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                elif grep -q "InfiniBand.*检查:.*warning.*警告\|InfiniBand.*检查:.*<span.*warning.*警告\|IB.*检查:.*warning.*警告\|IB.*检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif ! grep -q "InfiniBand.*检查\|IB.*检查" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "UNKNOWN"
                fi
            fi
            ;;
        "resource")
            # 资源检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查 - 基于目录检查结果
                if grep -q "✅.*数据目录\|✅.*kubelet数据目录\|✅.*containerd数据目录\|✅.*docker数据目录" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "⚠️.*数据目录\|⚠️.*kubelet数据目录\|⚠️.*containerd数据目录\|⚠️.*docker数据目录" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif grep -q "❌.*数据目录\|❌.*kubelet数据目录\|❌.*containerd数据目录\|❌.*docker数据目录" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                else
                    echo "UNKNOWN"
                fi
            else
                # HTML文件格式检查
                if grep -q "资源状态:.*success.*成功\|资源状态:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                    echo "OK"
                elif grep -q "资源状态:.*warning.*警告\|资源状态:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                    echo "WARNING"
                elif grep -q "资源状态:.*error.*失败\|资源状态:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                    echo "FAILED"
                else
                    echo "UNKNOWN"
                fi
            fi
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# 生成状态徽章
generate_badge() {
    local status="$1"
    local class=""
    
    case "$status" in
        "OK") class="status-ok" ;;
        "FAILED") class="status-failed" ;;
        "WARNING") class="status-warning" ;;
        "N/A") class="status-na" ;;
        *) class="status-unknown" ;;
    esac
    
    echo "<span class=\"status-badge $class\">$status</span>"
}

# 获取节点类型
get_node_type() {
    local hostname="$1"
    
    # 基于主机名模式判断节点类型
    if [[ "$hostname" =~ master|control ]]; then
        echo "Master"
    elif [[ "$hostname" =~ gpu ]]; then
        echo "GPU Worker"
    else
        echo "CPU Worker"
    fi
}

# 生成节点类型徽章
generate_node_badge() {
    local node_type="$1"
    local class=""
    
    case "$node_type" in
        "Master") class="master" ;;
        "GPU Worker") class="gpu-worker" ;;
        "CPU Worker") class="cpu-worker" ;;
    esac
    
    echo "<span class=\"node-type $class\">$node_type</span>"
}

# 开始生成汇总表格
echo "<div class=\"table-container\">" >> "$OUTPUT_FILE"
echo "<h2>📊 集群检查结果汇总</h2>" >> "$OUTPUT_FILE"
echo "<table>" >> "$OUTPUT_FILE"
echo "<thead>" >> "$OUTPUT_FILE"
echo "<tr>" >> "$OUTPUT_FILE"
echo "<th>主机名</th>" >> "$OUTPUT_FILE"
echo "<th>节点类型</th>" >> "$OUTPUT_FILE"
echo "<th>系统检查</th>" >> "$OUTPUT_FILE"
echo "<th>Kubernetes</th>" >> "$OUTPUT_FILE"
echo "<th>GPU/DCGM</th>" >> "$OUTPUT_FILE"
echo "<th>InfiniBand</th>" >> "$OUTPUT_FILE"
echo "<th>资源状态</th>" >> "$OUTPUT_FILE"
echo "<th>整体状态</th>" >> "$OUTPUT_FILE"
echo "<th>详细报告</th>" >> "$OUTPUT_FILE"
echo "</tr>" >> "$OUTPUT_FILE"
echo "</thead>" >> "$OUTPUT_FILE"
echo "<tbody>" >> "$OUTPUT_FILE"

# 统计变量
total_nodes=0
healthy_nodes=0
warning_nodes=0
failed_nodes=0

# 使用临时文件存储已处理的主机名，避免重复统计
processed_hosts_file="/tmp/processed_hosts_$$"
touch "$processed_hosts_file"

# 遍历所有报告文件
for report_file in "$SOURCE_DIR"/$file_pattern; do
    # 检查文件是否存在（避免通配符无匹配时的问题）
    if [[ -f "$report_file" ]]; then
        # 提取主机名 - 从文件名中提取，保持完整格式
        hostname=$(basename "$report_file")
        # 移除文件扩展名
        hostname="${hostname%.*}"
        
        # 清理主机名（移除前缀，保留完整的hostname格式）
        if [[ "$hostname" =~ _check_report_ ]]; then
            hostname=$(echo "$hostname" | sed 's/.*_check_report_//')
        elif [[ "$hostname" =~ _check_simplified_ ]]; then
            hostname=$(echo "$hostname" | sed 's/.*_check_simplified_//' | sed 's/_[0-9]*$//')
        elif [[ "$hostname" =~ _check_ ]]; then
            hostname=$(echo "$hostname" | sed 's/.*_check_//' | sed 's/_[0-9]*$//')
        fi
        
        # 跳过可能的统一报告文件
        if [[ "$hostname" == "unified_cluster_report" || "$hostname" == "cluster_report" ]]; then
            continue
        fi
        
        # 进一步清理主机名：移除时间戳
        hostname=$(echo "$hostname" | sed 's/_[0-9]\{8\}_[0-9]\{6\}$//')
        
        # 如果hostname还是像20250623这样的数字，尝试从文件内容中提取
        if [[ "$hostname" =~ ^[0-9]+$ ]]; then
            # 尝试从文件内容中提取真实主机名
            local_hostname=""
            if [[ "$report_file" =~ \.html$ ]]; then
                # 从HTML文件的title标签或内容中提取主机名
                local_hostname=$(grep -o '<title>.*</title>' "$report_file" 2>/dev/null | sed 's/<title>.*- \([^<]*\)<\/title>/\1/' | tr -d ' ')
                if [[ -z "$local_hostname" || "$local_hostname" =~ ^[0-9]+$ ]]; then
                    local_hostname=$(grep -o "主机名:.*<" "$report_file" 2>/dev/null | sed 's/主机名: *\([^<]*\)<.*/\1/' | tr -d ' ')
                fi
            else
                # 从TXT文件中提取主机名
                local_hostname=$(grep "主机名:" "$report_file" 2>/dev/null | head -1 | sed 's/.*主机名: *\([^ ]*\).*/\1/')
            fi
            
            if [[ -n "$local_hostname" && ! "$local_hostname" =~ ^[0-9]+$ ]]; then
                hostname="$local_hostname"
            else
                # 如果还是无法提取，使用文件名基础部分
                base_name=$(basename "$report_file")
                if [[ "$base_name" =~ localhost ]]; then
                    hostname="localhost"
                elif [[ "$base_name" =~ test.*worker ]]; then
                    hostname=$(echo "$base_name" | grep -o 'test-[^_]*-[^_]*' | head -1)
                elif [[ "$base_name" =~ test.*master ]]; then
                    hostname=$(echo "$base_name" | grep -o 'test-[^_]*-[^_]*' | head -1)
                fi
            fi
        fi
        
        # 检查是否已处理过这个主机
        if grep -q "^$hostname$" "$processed_hosts_file" 2>/dev/null; then
            continue
        fi
        
        # 记录该主机已处理
        echo "$hostname" >> "$processed_hosts_file"
        
        total_nodes=$((total_nodes + 1))
        
        # 获取节点类型
        node_type=$(get_node_type "$hostname")
        
        # 提取各项检查状态
        system_status=$(extract_status "$report_file" "system")
        k8s_status=$(extract_status "$report_file" "kubernetes")
        gpu_status=$(extract_status "$report_file" "gpu")
        
        # IB状态检查只针对GPU Worker节点
        if [[ "$node_type" == "GPU Worker" ]]; then
            ib_status=$(extract_status "$report_file" "ib")
        else
            ib_status="N/A"
        fi
        
        resource_status=$(extract_status "$report_file" "resource")
        
        # 计算整体状态
        overall_status="OK"
        if [[ "$system_status" == "FAILED" || "$k8s_status" == "FAILED" || "$gpu_status" == "FAILED" || "$ib_status" == "FAILED" || "$resource_status" == "FAILED" ]]; then
            overall_status="FAILED"
            failed_nodes=$((failed_nodes + 1))
        elif [[ "$system_status" == "WARNING" || "$k8s_status" == "WARNING" || "$gpu_status" == "WARNING" || "$ib_status" == "WARNING" || "$resource_status" == "WARNING" ]]; then
            overall_status="WARNING"
            warning_nodes=$((warning_nodes + 1))
        else
            healthy_nodes=$((healthy_nodes + 1))
        fi
        
        # 生成表格行
        echo "<tr>" >> "$OUTPUT_FILE"
        echo "<td><strong>$hostname</strong></td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_node_badge "$node_type")</td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_badge "$system_status")</td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_badge "$k8s_status")</td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_badge "$gpu_status")</td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_badge "$ib_status")</td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_badge "$resource_status")</td>" >> "$OUTPUT_FILE"
        echo "<td>$(generate_badge "$overall_status")</td>" >> "$OUTPUT_FILE"
        echo "<td><a href=\"$(basename "$report_file")\" class=\"details-link\">查看详情</a></td>" >> "$OUTPUT_FILE"
        echo "</tr>" >> "$OUTPUT_FILE"
    fi
done

echo "</tbody>" >> "$OUTPUT_FILE"
echo "</table>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

# 生成统计汇总
echo "<div class=\"summary\">" >> "$OUTPUT_FILE"
echo "<h2>📈 集群状态统计</h2>" >> "$OUTPUT_FILE"
echo "<div class=\"summary-stats\">" >> "$OUTPUT_FILE"

echo "<div class=\"stat-card\">" >> "$OUTPUT_FILE"
echo "<div class=\"stat-number\">$total_nodes</div>" >> "$OUTPUT_FILE"
echo "<div class=\"stat-label\">总节点数</div>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

echo "<div class=\"stat-card\">" >> "$OUTPUT_FILE"
echo "<div class=\"stat-number\" style=\"color: #28a745;\">$healthy_nodes</div>" >> "$OUTPUT_FILE"
echo "<div class=\"stat-label\">健康节点</div>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

echo "<div class=\"stat-card\">" >> "$OUTPUT_FILE"
echo "<div class=\"stat-number\" style=\"color: #ffc107;\">$warning_nodes</div>" >> "$OUTPUT_FILE"
echo "<div class=\"stat-label\">警告节点</div>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

echo "<div class=\"stat-card\">" >> "$OUTPUT_FILE"
echo "<div class=\"stat-number\" style=\"color: #dc3545;\">$failed_nodes</div>" >> "$OUTPUT_FILE"
echo "<div class=\"stat-label\">异常节点</div>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

echo "</div>" >> "$OUTPUT_FILE"

# 健康率计算
if [[ $total_nodes -gt 0 ]]; then
    health_rate=$(( (healthy_nodes * 100) / total_nodes ))
    echo "<p><strong>集群健康率:</strong> ${health_rate}% ($healthy_nodes/$total_nodes)</p>" >> "$OUTPUT_FILE"
fi

echo "</div>" >> "$OUTPUT_FILE"

# DCGM功能说明
echo "<div class=\"summary\">" >> "$OUTPUT_FILE"
echo "<h2>🔧 DCGM 监控功能说明</h2>" >> "$OUTPUT_FILE"
echo "<p>本次检查包含了完整的 NVIDIA Data Center GPU Manager (DCGM) 监控功能：</p>" >> "$OUTPUT_FILE"
echo "<ul>" >> "$OUTPUT_FILE"
echo "<li><strong>DCGM服务状态检查:</strong> 验证DCGM服务是否正常运行</li>" >> "$OUTPUT_FILE"
echo "<li><strong>GPU健康检查:</strong> 通过DCGM进行GPU硬件健康状态检测</li>" >> "$OUTPUT_FILE"
echo "<li><strong>实时监控指标:</strong> 收集GPU利用率、内存使用、温度等关键指标</li>" >> "$OUTPUT_FILE"
echo "<li><strong>群组和字段组管理:</strong> 检查DCGM群组配置和监控字段设置</li>" >> "$OUTPUT_FILE"
echo "<li><strong>错误和事件监控:</strong> 检测GPU相关的错误和系统事件</li>" >> "$OUTPUT_FILE"
echo "</ul>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

# 添加页脚
echo "<div style=\"text-align: center; margin-top: 30px; padding: 20px; color: #6c757d; border-top: 1px solid #dee2e6;\">" >> "$OUTPUT_FILE"
echo "<p>🚀 Kubernetes 集群健康检查工具 v2.1.0 | 生成时间: $TIMESTAMP</p>" >> "$OUTPUT_FILE"
echo "<p>包含DCGM GPU监控 • HTML表格报告系统 • 中文本地化支持</p>" >> "$OUTPUT_FILE"
echo "</div>" >> "$OUTPUT_FILE"

echo "</body>" >> "$OUTPUT_FILE"
echo "</html>" >> "$OUTPUT_FILE"

echo ""
echo "✅ 统一报告已生成: $OUTPUT_FILE"
echo "📊 集群统计: 总节点 $total_nodes, 健康 $healthy_nodes, 警告 $warning_nodes, 异常 $failed_nodes"
echo "📁 详细报告目录: $REPORT_DIR"

# 如果健康率低于80%，输出警告
if [[ $total_nodes -gt 0 ]]; then
    health_rate=$(( (healthy_nodes * 100) / total_nodes ))
    if [[ $health_rate -lt 80 ]]; then
        echo "⚠️  警告: 集群健康率较低 (${health_rate}%)，请检查异常节点"
    fi
fi

# 清理临时文件
rm -f "$processed_hosts_file"
