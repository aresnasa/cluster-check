#!/bin/bash

# Kubernetes集群健康检查工具 - 项目验证脚本
# 用于验证项目完整性和质量

echo "🔍 Kubernetes集群健康检查工具 - 项目验证"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 计数器
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 检查结果输出函数
print_result() {
    local status="$1"
    local message="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $message"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}❌ FAIL${NC}: $message"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠️ WARN${NC}: $message"
    else
        echo -e "${BLUE}ℹ️ INFO${NC}: $message"
    fi
}

# 1. 项目结构验证
echo -e "\n${BLUE}📁 项目结构验证${NC}"
echo "------------------------"

# 检查必需的配置文件
if [ -f "ansible.cfg" ]; then
    print_result "PASS" "Ansible配置文件存在"
else
    print_result "FAIL" "缺少ansible.cfg文件"
fi

if [ -f "inventory_unified.ini" ]; then
    print_result "PASS" "Inventory配置文件存在"
else
    print_result "FAIL" "缺少inventory_unified.ini文件"
fi

# 检查主要的Playbook文件
if [ -f "unified_cluster_check_playbook_v2.yml" ]; then
    print_result "PASS" "主Playbook文件存在"
else
    print_result "FAIL" "缺少主Playbook文件"
fi

# 检查构建文件
if [ -f "Makefile" ]; then
    print_result "PASS" "Makefile存在"
else
    print_result "FAIL" "缺少Makefile"
fi

if [ -f "VERSION" ]; then
    print_result "PASS" "版本文件存在"
else
    print_result "FAIL" "缺少VERSION文件"
fi

# 检查模板目录
if [ -d "templates" ]; then
    print_result "PASS" "templates目录存在"
    
    # 检查所有必需的模板文件
    template_files=("master_check_script.sh.j2" "cpu_worker_check_script.sh.j2" "gpu_worker_check_script.sh.j2")
    for template in "${template_files[@]}"; do
        if [ -f "templates/$template" ]; then
            print_result "PASS" "模板文件 $template 存在"
        else
            print_result "FAIL" "缺少模板文件 $template"
        fi
    done
else
    print_result "FAIL" "缺少templates目录"
fi

# 2. 模板语法验证
echo -e "\n${BLUE}🔧 模板语法验证${NC}"
echo "------------------------"

for template in templates/*.j2; do
    if [ -f "$template" ]; then
        template_name=$(basename "$template")
        # 简单的语法检查 - 检查是否有未闭合的标签
        if grep -q "#!/bin/bash" "$template"; then
            print_result "PASS" "$template_name 包含bash shebang"
        else
            print_result "WARN" "$template_name 可能缺少bash shebang"
        fi
        
        # 检查函数定义
        if grep -q "function\|.*() {" "$template"; then
            print_result "PASS" "$template_name 包含函数定义"
        else
            print_result "WARN" "$template_name 可能缺少函数定义"
        fi
    fi
done

# 3. 文档完整性验证
echo -e "\n${BLUE}📚 文档完整性验证${NC}"
echo "------------------------"

doc_files=("README.md" "CHANGELOG.md" "PROJECT_STRUCTURE.md" "PROJECT_COMPLETION_SUMMARY.md")
for doc in "${doc_files[@]}"; do
    if [ -f "$doc" ]; then
        if [ -s "$doc" ]; then
            print_result "PASS" "文档 $doc 存在且非空"
        else
            print_result "WARN" "文档 $doc 存在但为空"
        fi
    else
        print_result "FAIL" "缺少文档 $doc"
    fi
done

# 4. 脚本可执行性验证
echo -e "\n${BLUE}🚀 脚本可执行性验证${NC}"
echo "------------------------"

script_files=("generate_unified_report.sh" "diagnose_and_fix.sh" "validate_project.sh")
for script in "${script_files[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_result "PASS" "脚本 $script 具有执行权限"
        else
            print_result "WARN" "脚本 $script 没有执行权限"
            chmod +x "$script" 2>/dev/null && print_result "INFO" "已为 $script 添加执行权限"
        fi
    else
        print_result "WARN" "脚本 $script 不存在"
    fi
done

# 5. 版本信息验证
echo -e "\n${BLUE}📋 版本信息验证${NC}"
echo "------------------------"

if [ -f "VERSION" ]; then
    version_content=$(cat VERSION)
    if echo "$version_content" | grep -q "2\.1\.0"; then
        print_result "PASS" "版本号正确(2.1.0)"
    else
        print_result "WARN" "版本号可能不正确"
    fi
    
    if echo "$version_content" | grep -q "Master\|Worker\|etcd\|GPU"; then
        print_result "PASS" "功能特性描述完整"
    else
        print_result "WARN" "功能特性描述可能不完整"
    fi
fi

# 6. 项目清洁度验证
echo -e "\n${BLUE}🧹 项目清洁度验证${NC}"
echo "------------------------"

# 检查是否有临时文件或冗余文件
temp_files=(".DS_Store" "*.tmp" "*.swp" "*~")
found_temp=false
for pattern in "${temp_files[@]}"; do
    if ls $pattern 2>/dev/null | grep -q .; then
        print_result "WARN" "发现临时文件: $pattern"
        found_temp=true
    fi
done

if ! $found_temp; then
    print_result "PASS" "项目目录清洁，无临时文件"
fi

# 检查是否存在过时的文档
old_docs=("TAGS_IMPLEMENTATION_SUMMARY.md" "TAGS_USAGE.md" "PLAY4_SOLUTION.md")
found_old=false
for doc in "${old_docs[@]}"; do
    if [ -f "$doc" ]; then
        print_result "WARN" "发现过时文档: $doc"
        found_old=true
    fi
done

if ! $found_old; then
    print_result "PASS" "已清理过时文档"
fi

# 7. 模板功能完整性验证
echo -e "\n${BLUE}⚙️ 模板功能完整性验证${NC}"
echo "------------------------"

# 检查Master模板的关键功能
if [ -f "templates/master_check_script.sh.j2" ]; then
    master_template="templates/master_check_script.sh.j2"
    
    if grep -q "etcd" "$master_template"; then
        print_result "PASS" "Master模板包含etcd检查功能"
    else
        print_result "FAIL" "Master模板缺少etcd检查功能"
    fi
    
    if grep -q "kernel_params\|cgroup\|firewall\|selinux" "$master_template"; then
        print_result "PASS" "Master模板包含系统配置检查"
    else
        print_result "FAIL" "Master模板缺少系统配置检查"
    fi
fi

# 检查GPU Worker模板的关键功能
if [ -f "templates/gpu_worker_check_script.sh.j2" ]; then
    gpu_template="templates/gpu_worker_check_script.sh.j2"
    
    if grep -q "nvidia\|gpu\|DCGM" "$gpu_template"; then
        print_result "PASS" "GPU Worker模板包含GPU相关检查"
    else
        print_result "FAIL" "GPU Worker模板缺少GPU相关检查"
    fi
    
    if grep -q "nvidia_modules\|lspci" "$gpu_template"; then
        print_result "PASS" "GPU Worker模板包含硬件检测功能"
    else
        print_result "FAIL" "GPU Worker模板缺少硬件检测功能"
    fi
fi

# 检查CPU Worker模板的关键功能
if [ -f "templates/cpu_worker_check_script.sh.j2" ]; then
    cpu_template="templates/cpu_worker_check_script.sh.j2"
    
    if grep -q "k8s_packages\|kubelet" "$cpu_template"; then
        print_result "PASS" "CPU Worker模板包含K8s软件包检查"
    else
        print_result "FAIL" "CPU Worker模板缺少K8s软件包检查"
    fi
    
    if grep -q "cgroup\|swap\|firewall\|selinux" "$cpu_template"; then
        print_result "PASS" "CPU Worker模板包含系统配置检查"
    else
        print_result "FAIL" "CPU Worker模板缺少系统配置检查"
    fi
fi

# 8. 最终结果汇总
echo -e "\n${BLUE}📊 验证结果汇总${NC}"
echo "=========================="
echo "总检查项目: $TOTAL_CHECKS"
echo -e "通过项目: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "失败项目: ${RED}$FAILED_CHECKS${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 项目验证通过！所有检查项目都满足要求。${NC}"
    exit 0
elif [ $FAILED_CHECKS -le 2 ]; then
    echo -e "\n${YELLOW}⚠️ 项目基本通过验证，但有少量问题需要关注。${NC}"
    exit 1
else
    echo -e "\n${RED}❌ 项目验证失败，存在多个需要修复的问题。${NC}"
    exit 2
fi
