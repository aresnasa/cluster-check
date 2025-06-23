#!/bin/bash

# ===========================================
# Kubernetes集群健康检查工具 - 统一入口脚本 v2.2
# 功能：支持详细HTML报告和简要报告两种模式
# 使用方法: ./cluster_check.sh [选项]
# ===========================================

set -e

# 脚本信息
SCRIPT_VERSION="2.2"
SCRIPT_NAME="Kubernetes集群健康检查工具"

# 默认配置
REPORT_MODE="detailed"  # detailed|simple
OUTPUT_FORMAT="html"    # html|text|markdown
ENVIRONMENT="demo"      # demo|production
PLAYBOOK_TAGS=""        # 可选的ansible tags
INVENTORY_FILE="inventory_unified.ini"
PLAYBOOK_FILE="unified_cluster_check_playbook_v2.yml"

# 显示帮助信息
show_help() {
    cat << EOF
${SCRIPT_NAME} v${SCRIPT_VERSION}

用法: $0 [选项]

选项:
  -m, --mode MODE         报告模式 (detailed|simple)
                          detailed: 生成详细的HTML报告 (默认)
                          simple: 生成简要报告，只显示通过/失败状态
  
  -f, --format FORMAT     输出格式 (html|text|markdown)
                          html: HTML格式报告 (默认)
                          text: 纯文本格式报告
                          markdown: Markdown格式报告
  
  -e, --env ENVIRONMENT   环境类型 (demo|production)
                          demo: 使用本地模拟环境 (默认)
                          production: 使用生产环境配置
  
  -t, --tags TAGS         指定ansible playbook标签 (可选)
                          例如: -t "p1_master_check,p2_cpu_worker_check"
  
  -i, --inventory FILE    指定inventory文件 (默认: inventory_unified.ini)
  
  -p, --playbook FILE     指定playbook文件 (默认: unified_cluster_check_playbook_v2.yml)
  
  -h, --help              显示此帮助信息

示例:
  # 生成详细HTML报告 (默认模式)
  $0
  
  # 生成简要HTML报告
  $0 --mode simple
  
  # 生成详细文本报告
  $0 --mode detailed --format text
  
  # 在生产环境生成简要报告
  $0 --mode simple --env production
  
  # 只检查Master节点并生成简要报告
  $0 --mode simple --tags "p1_master_check"
  
  # 生成Markdown格式的简要报告
  $0 --mode simple --format markdown

注意事项:
  - simple模式会在脚本生成时自动设置简化标志
  - detailed模式生成完整的检查报告，包含详细信息
  - demo环境使用localhost模拟，production环境使用实际服务器
  - 确保inventory文件中配置了正确的主机信息

EOF
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                REPORT_MODE="$2"
                if [[ "$REPORT_MODE" != "detailed" && "$REPORT_MODE" != "simple" ]]; then
                    echo "❌ 错误: 报告模式必须是 'detailed' 或 'simple'"
                    exit 1
                fi
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                if [[ "$OUTPUT_FORMAT" != "html" && "$OUTPUT_FORMAT" != "text" && "$OUTPUT_FORMAT" != "markdown" ]]; then
                    echo "❌ 错误: 输出格式必须是 'html', 'text' 或 'markdown'"
                    exit 1
                fi
                shift 2
                ;;
            -e|--env)
                ENVIRONMENT="$2"
                if [[ "$ENVIRONMENT" != "demo" && "$ENVIRONMENT" != "production" ]]; then
                    echo "❌ 错误: 环境类型必须是 'demo' 或 'production'"
                    exit 1
                fi
                shift 2
                ;;
            -t|--tags)
                PLAYBOOK_TAGS="$2"
                shift 2
                ;;
            -i|--inventory)
                INVENTORY_FILE="$2"
                if [[ ! -f "$INVENTORY_FILE" ]]; then
                    echo "❌ 错误: inventory文件 '$INVENTORY_FILE' 不存在"
                    exit 1
                fi
                shift 2
                ;;
            -p|--playbook)
                PLAYBOOK_FILE="$2"
                if [[ ! -f "$PLAYBOOK_FILE" ]]; then
                    echo "❌ 错误: playbook文件 '$PLAYBOOK_FILE' 不存在"
                    exit 1
                fi
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "❌ 错误: 未知参数 '$1'"
                echo "使用 '$0 --help' 查看帮助信息"
                exit 1
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    echo "🔍 检查依赖..."
    
    # 检查ansible
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        echo "❌ 错误: ansible-playbook 未安装"
        echo "请先安装Ansible: pip install ansible"
        exit 1
    fi
    
    # 检查必要文件
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        echo "❌ 错误: inventory文件 '$INVENTORY_FILE' 不存在"
        exit 1
    fi
    
    if [[ ! -f "$PLAYBOOK_FILE" ]]; then
        echo "❌ 错误: playbook文件 '$PLAYBOOK_FILE' 不存在"
        exit 1
    fi
    
    # 检查模板文件
    if [[ ! -d "templates" ]]; then
        echo "❌ 错误: templates目录不存在"
        exit 1
    fi
    
    local required_templates=(
        "templates/master_check_script.sh.j2"
        "templates/cpu_worker_check_script.sh.j2" 
        "templates/gpu_worker_check_script.sh.j2"
    )
    
    for template in "${required_templates[@]}"; do
        if [[ ! -f "$template" ]]; then
            echo "❌ 错误: 模板文件 '$template' 不存在"
            exit 1
        fi
    done
    
    echo "✅ 依赖检查通过"
}

# 准备执行环境
prepare_environment() {
    echo "🚀 准备执行环境..."
    
    # 创建必要目录
    mkdir -p cluster_check_results
    mkdir -p report
    
    # 清理旧的结果文件
    if [[ -d "cluster_check_results" ]]; then
        find cluster_check_results -name "*.html" -o -name "*.txt" -mtime +7 -delete 2>/dev/null || true
    fi
    
    echo "✅ 环境准备完成"
}

# 构建ansible命令
build_ansible_command() {
    local ansible_cmd="ansible-playbook"
    
    # 添加inventory
    ansible_cmd="$ansible_cmd -i $INVENTORY_FILE"
    
    # 添加额外变量
    ansible_cmd="$ansible_cmd -e output_format=$OUTPUT_FORMAT"
    
    # 根据报告模式设置简化标志
    if [[ "$REPORT_MODE" == "simple" ]]; then
        ansible_cmd="$ansible_cmd -e simplified_report=true"
    else
        ansible_cmd="$ansible_cmd -e simplified_report=false"
    fi
    
    # 设置是否生成markdown报告
    if [[ "$OUTPUT_FORMAT" == "markdown" ]]; then
        ansible_cmd="$ansible_cmd -e generate_markdown=true"
    else
        ansible_cmd="$ansible_cmd -e generate_markdown=false"
    fi
    
    # 添加tags（如果指定）
    if [[ -n "$PLAYBOOK_TAGS" ]]; then
        ansible_cmd="$ansible_cmd --tags $PLAYBOOK_TAGS"
    fi
    
    # 根据环境选择主机组
    case "$ENVIRONMENT" in
        "demo")
            if [[ -z "$PLAYBOOK_TAGS" ]]; then
                ansible_cmd="$ansible_cmd --limit k8s_masters_demo,k8s_cpu_workers_demo,k8s_gpu_workers_demo"
            else
                # 当指定了tags时，也要限制到demo环境的主机
                if [[ "$PLAYBOOK_TAGS" == *"p1_master_check"* ]]; then
                    ansible_cmd="$ansible_cmd --limit k8s_masters_demo"
                elif [[ "$PLAYBOOK_TAGS" == *"p2_cpu_worker_check"* ]]; then
                    ansible_cmd="$ansible_cmd --limit k8s_cpu_workers_demo"
                elif [[ "$PLAYBOOK_TAGS" == *"p3_gpu_worker_check"* ]]; then
                    ansible_cmd="$ansible_cmd --limit k8s_gpu_workers_demo"
                else
                    ansible_cmd="$ansible_cmd --limit k8s_masters_demo,k8s_cpu_workers_demo,k8s_gpu_workers_demo"
                fi
            fi
            ;;
        "production")
            if [[ -z "$PLAYBOOK_TAGS" ]]; then
                ansible_cmd="$ansible_cmd --limit k8s_masters,k8s_cpu_workers,k8s_gpu_workers"
            else
                # 当指定了tags时，也要限制到生产环境的主机
                if [[ "$PLAYBOOK_TAGS" == *"p1_master_check"* ]]; then
                    ansible_cmd="$ansible_cmd --limit k8s_masters"
                elif [[ "$PLAYBOOK_TAGS" == *"p2_cpu_worker_check"* ]]; then
                    ansible_cmd="$ansible_cmd --limit k8s_cpu_workers"
                elif [[ "$PLAYBOOK_TAGS" == *"p3_gpu_worker_check"* ]]; then
                    ansible_cmd="$ansible_cmd --limit k8s_gpu_workers"
                else
                    ansible_cmd="$ansible_cmd --limit k8s_masters,k8s_cpu_workers,k8s_gpu_workers"
                fi
            fi
            ;;
    esac
    
    # 添加playbook文件
    ansible_cmd="$ansible_cmd $PLAYBOOK_FILE"
    
    echo "$ansible_cmd"
}

# 执行检查
run_cluster_check() {
    echo "🎯 开始执行Kubernetes集群健康检查..."
    echo "📋 配置信息:"
    echo "   报告模式: $REPORT_MODE"
    echo "   输出格式: $OUTPUT_FORMAT"
    echo "   执行环境: $ENVIRONMENT"
    echo "   Inventory: $INVENTORY_FILE"
    echo "   Playbook: $PLAYBOOK_FILE"
    if [[ -n "$PLAYBOOK_TAGS" ]]; then
        echo "   标签: $PLAYBOOK_TAGS"
    fi
    echo ""
    
    # 构建和执行ansible命令
    local ansible_cmd=$(build_ansible_command)
    echo "🚀 执行命令: $ansible_cmd"
    echo ""
    
    # 执行ansible playbook
    eval "$ansible_cmd"
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo "✅ 集群健康检查执行完成"
    else
        echo ""
        echo "❌ 集群健康检查执行失败"
        exit 1
    fi
}

# 生成后处理报告
post_process_reports() {
    echo ""
    echo "📊 后处理报告..."
    
    # 检查生成的报告文件
    local report_count=$(find cluster_check_results -name "*.html" -o -name "*.txt" | wc -l)
    echo "📄 生成了 $report_count 个报告文件"
    
    # 如果是简要模式且格式是markdown，生成额外的简化markdown报告
    if [[ "$REPORT_MODE" == "simple" && "$OUTPUT_FORMAT" == "markdown" ]]; then
        echo "📝 生成简化Markdown报告..."
        if [[ -x "./generate_simplified_markdown_report.sh" ]]; then
            ./generate_simplified_markdown_report.sh cluster_check_results
        else
            echo "⚠️  简化Markdown报告生成脚本不可执行或不存在"
        fi
    fi
    
    echo "✅ 后处理完成"
}

# 显示结果摘要
show_summary() {
    echo ""
    echo "🎉 Kubernetes集群健康检查完成！"
    echo "=================================================="
    echo ""
    echo "📋 执行摘要:"
    echo "   报告模式: $REPORT_MODE"
    echo "   输出格式: $OUTPUT_FORMAT"
    echo "   执行环境: $ENVIRONMENT"
    echo ""
    
    echo "📁 生成的文件:"
    echo "   检查结果: cluster_check_results/"
    if [[ -d "cluster_check_results" ]]; then
        find cluster_check_results -name "*.html" -o -name "*.txt" | while read -r file; do
            echo "     - $(basename "$file")"
        done
    fi
    
    echo "   统一报告: report/"
    if [[ -d "report" ]]; then
        find report -name "*.html" -o -name "*.md" -o -name "*.txt" | while read -r file; do
            echo "     - $(basename "$file")"
        done
    fi
    
    echo ""
    echo "💡 提示:"
    case "$REPORT_MODE" in
        "detailed")
            echo "   - 查看 report/ 目录下的统一报告获取整体状况"
            echo "   - 查看 cluster_check_results/ 目录下各节点的详细报告"
            ;;
        "simple")
            echo "   - 简要报告只显示通过/失败状态，便于快速查看"
            echo "   - 如需详细信息，请使用 --mode detailed 重新运行"
            if [[ "$OUTPUT_FORMAT" == "markdown" ]]; then
                echo "   - Markdown报告可在支持的编辑器中查看"
            fi
            ;;
    esac
    
    echo ""
    echo "🔗 其他操作:"
    echo "   - 重新运行: $0 --mode $REPORT_MODE --format $OUTPUT_FORMAT --env $ENVIRONMENT"
    echo "   - 查看帮助: $0 --help"
}

# 主执行函数
main() {
    echo "🎯 ${SCRIPT_NAME} v${SCRIPT_VERSION}"
    echo "=================================================="
    echo ""
    
    # 解析参数
    parse_arguments "$@"
    
    # 检查依赖
    check_dependencies
    
    # 准备环境
    prepare_environment
    
    # 执行检查
    run_cluster_check
    
    # 后处理报告
    post_process_reports
    
    # 显示摘要
    show_summary
}

# 如果脚本被直接执行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
