#!/bin/bash

# Параметры:
# $1 - путь к конфиг директории
# $2 - префикс переменных для генерации
# $3 - имя XML файла (например core-site.xml)
# $4 - путь к env файлу (по умолчанию settings.env)
generate_config() {
    local conf_dir=$1
    local prefix=$2
    local xml_file=$3
    local env_file=${4:-settings.env}

    mkdir -p "$conf_dir"
    local full_path="$conf_dir/$xml_file"

    echo "<configuration>" > "$full_path"

    grep "^${prefix}_" "$env_file" | while IFS='=' read -r var value; do
        local key=${var#${prefix}_}
        key=$(echo "$key" | sed 's/___/-/g; s/__/_/g; s/_/./g')
        local escaped_value=$(echo "$value" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        echo "  <property><name>$key</name><value>$escaped_value</value></property>" >> "$full_path"
    done

    echo "</configuration>" >> "$full_path"
    echo "Generated $full_path from prefix $prefix"
}
