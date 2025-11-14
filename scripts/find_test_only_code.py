#!/usr/bin/env python3
"""
用于识别仅被测试代码引用的生产代码元素的脚本
"""

import os
import re
import sys

# 定义项目根目录
PROJECT_ROOT = "/Users/bytedance/traeProjects/Contrail"
SRC_DIR = os.path.join(PROJECT_ROOT, "lib")
TEST_DIR = os.path.join(PROJECT_ROOT, "test")

# 存储所有生产代码元素
production_elements = set()
# 存储被测试代码引用的生产代码元素
referenced_in_test = set()


def get_production_files():
    """获取所有生产代码文件"""
    production_files = []
    for root, _, files in os.walk(SRC_DIR):
        for file in files:
            if file.endswith(".dart"):
                production_files.append(os.path.join(root, file))
    return production_files


def get_test_files():
    """获取所有测试代码文件"""
    test_files = []
    for root, _, files in os.walk(TEST_DIR):
        for file in files:
            if file.endswith(".dart"):
                test_files.append(os.path.join(root, file))
    return test_files


def extract_production_elements(file_path):
    """从生产代码文件中提取类、方法、变量等元素"""
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 提取类
    class_pattern = r'\b(class|enum|abstract class|mixin|extension)\s+([A-Z][a-zA-Z0-9_]*)\s*'
    classes = re.findall(class_pattern, content)
    for class_type, class_name in classes:
        production_elements.add(("class", class_name, file_path))

    # 提取公共方法
    method_pattern = r'\b(?:Future|void|int|double|bool|String|dynamic)\s+([a-zA-Z0-9_]+)\s*\('
    methods = re.findall(method_pattern, content)
    for method_name in methods:
        # 排除构造函数和getter/setter
        if not method_name.endswith("=") and not method_name[0].isupper():
            production_elements.add(("method", method_name, file_path))

    # 提取公共变量
    var_pattern = r'\b(?:static\s+)?(?:final|const|var|int|double|bool|String)\s+([a-zA-Z0-9_]+)\s*='
    vars = re.findall(var_pattern, content)
    for var_name in vars:
        production_elements.add(("variable", var_name, file_path))


def extract_test_references(file_path):
    """从测试文件中提取对生产代码元素的引用"""
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 提取所有可能的代码引用
    # 简单的实现：提取所有大写开头的可能类名和其他标识符
    reference_pattern = r'\b([A-Z][a-zA-Z0-9_]*|[a-zA-Z0-9_]+)\b'
    references = re.findall(reference_pattern, content)
    for ref in references:
        referenced_in_test.add(ref)


def find_test_only_code():
    """找到仅被测试引用的生产代码元素"""
    test_only_elements = []

    for element_type, element_name, file_path in production_elements:
        if element_name in referenced_in_test:
            # 检查是否在生产代码中被引用
            is_referenced_in_production = False
            for prod_file_path in get_production_files():
                if prod_file_path == file_path:
                    continue
                with open(prod_file_path, "r", encoding="utf-8") as f:
                    if element_name in f.read():
                        is_referenced_in_production = True
                        break
            if not is_referenced_in_production:
                test_only_elements.append((element_type, element_name, file_path))

    return test_only_elements


def main():
    print("正在提取生产代码元素...")
    for file_path in get_production_files():
        extract_production_elements(file_path)
    print(f"共识别到 {len(production_elements)} 个生产代码元素")

    print("\n正在提取测试代码引用...")
    for file_path in get_test_files():
        extract_test_references(file_path)
    print(f"共识别到 {len(referenced_in_test)} 个测试代码引用")

    print("\n正在查找仅被测试引用的生产代码...")
    test_only_elements = find_test_only_code()

    print(f"\n共找到 {len(test_only_elements)} 个仅被测试引用的生产代码元素:")
    for element_type, element_name, file_path in test_only_elements:
        relative_path = os.path.relpath(file_path, PROJECT_ROOT)
        print(f"{element_type}: {element_name} ({relative_path})")

    return 0


if __name__ == "__main__":
    sys.exit(main())