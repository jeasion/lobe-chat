#!/bin/bash

# ==================
# == Env settings ==
# ==================

# check operating system
# ref: https://github.com/lobehub/lobe-chat/pull/5247
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    SED_COMMAND="sed -i ''"
else
    # not macOS
    SED_COMMAND="sed -i"
fi

# ======================
# == Process the args ==
# ======================

# 1. Default values of arguments
# Arg: -f
# Determine force download asserts, default is not
FORCE_DOWNLOAD=false

# Arg: -l or --lang
# Determine the language to show, default is en
LANGUAGE="en_US"

# Arg: --url
# Determine the source URL to download files
SOURCE_URL="https://raw.githubusercontent.com/lobehub/lobe-chat/main"

# Arg: --host
# Determine the server host
HOST=""

# 2. Parse script arguments
while getopts "fl:-:" opt; do
    case $opt in
        f)
            FORCE_DOWNLOAD=true
        ;;
        l)
            LANGUAGE=$OPTARG
        ;;
        -)
            case "${OPTARG}" in
                lang)
                    LANGUAGE="${!OPTIND}"
                    OPTIND=$(($OPTIND + 1))
                ;;
                url)
                    SOURCE_URL="${!OPTIND}"
                    OPTIND=$(($OPTIND + 1))
                ;;
                host)
                    HOST="${!OPTIND}"
                    OPTIND=$(($OPTIND + 1))
                ;;
                *)
                    echo "Usage: $0 [-f] [-l language|--lang language] [--url source] [--host serverhost]" >&2
                    exit 1
                ;;
            esac
        ;;
        *)
            echo "Usage: $0 [-f] [-l language|--lang language] [--url source]" >&2
            exit 1
        ;;
    esac
done

#######################
## Helper Functions ##
#######################

# Supported languages and messages
# Arg: -l --lang
# If the language is not supported, default to English
# Function to show messages
show_message() {
    local key="$1"
    case $key in
        downloading)
            case $LANGUAGE in
                zh_CN)
                    echo "正在下载文件..."
                ;;
                *)
                    echo "Downloading files..."
                ;;
            esac
        ;;
        downloaded)
            case $LANGUAGE in
                zh_CN)
                    echo " 已经存在，跳过下载。"
                ;;
                *)
                    echo " already exists, skipping download."
                ;;
            esac
        ;;
        extracted_success)
            case $LANGUAGE in
                zh_CN)
                    echo " 解压成功到目录："
                ;;
                *)
                    echo " extracted successfully to directory: "
                ;;
            esac
        ;;
        extracted_failed)
            case $LANGUAGE in
                zh_CN)
                    echo " 解压失败。"
                ;;
                *)
                    echo " extraction failed."
                ;;
            esac
        ;;
        file_not_exists)
            case $LANGUAGE in
                zh_CN)
                    echo " 不存在。"
                ;;
                *)
                    echo " does not exist."
                ;;
            esac
        ;;
        security_secrect_regenerate)
            case $LANGUAGE in
                zh_CN)
                    echo "重新生成安全密钥..."
                ;;
                *)
                    echo "Regenerate security secrets..."
                ;;
            esac
        ;;
        security_secrect_regenerate_failed)
            case $LANGUAGE in
                zh_CN)
                    echo "无法重新生成安全密钥："
                ;;
                *)
                    echo "Failed to regenerate security secrets: "
                ;;
            esac
        ;;
        host_regenerate)
            case $LANGUAGE in
                zh_CN)
                    echo "修改服务器域名配置中..."
                ;;
                *)
                    echo "Modifying server host configuration..."
                ;;
            esac
        ;;
        host_regenerate_failed)
            case $LANGUAGE in
                zh_CN)
                    echo "无法重新生成服务器域名："
                ;;
                *)
                    echo "Failed to regenerate server host: "
                ;;
            esac
        ;;
        security_secrect_regenerate_report)
            case $LANGUAGE in
                zh_CN)
                    echo "安全密钥生成结果如下："
                ;;
                *)
                    echo "Security secret generation results are as follows:"
                ;;
            esac
        ;;
        tips_already_installed)
            case $LANGUAGE in
                zh_CN)
                    echo "检测到您已经运行过 LobeChat Database，本安装程序只能完成初始化配置，并不能重复安装。如果你需要重新安装，请删除 data 和 s3_data 文件夹。"
                ;;
                *)
                    echo "It is detected that you have run LobeChat Database. This installation program can only complete the initialization configuration and cannot be reinstalled. If you need to reinstall, please delete the data and s3_data folders."
                ;;
            esac
        ;;
        tips_run_command)
            case $LANGUAGE in
                zh_CN)
                    echo "您已经完成了所有配置。请运行以下命令启动LobeChat："
                ;;
                *)
                    echo "You have completed all configurations. Please run this command to start LobeChat:"
                ;;
            esac
        ;;
        tips_show_documentation)
            case $LANGUAGE in
                zh_CN)
                    echo "完整的环境变量在'.env'中可以在文档中找到："
                ;;
                *)
                    echo "Full environment variables in the '.env' can be found at the documentation on "
                ;;
            esac
        ;;
        tips_show_documentation_url)
            case $LANGUAGE in
                zh_CN)
                    echo "https://lobehub.com/zh/docs/self-hosting/environment-variables"
                ;;
                *)
                    echo "https://lobehub.com/docs/self-hosting/environment-variables"
                ;;
            esac
        ;;
        tips_warning)
            case $LANGUAGE in
                zh_CN)
                    echo "警告：如果你正在生产环境中使用，请在日志中检查密钥是否已经生成！！！"
                ;;
                *)
                    echo "Warning: If you are using it in a production environment, please check if the keys have been generated in the logs!!!"
                ;;
            esac
        ;;
        tips_no_executable)
            case $LANGUAGE in
                zh_CN)
                    echo "没有找到，请先安装。"
                ;;
                *)
                    echo "not found, please install it first."
                ;;
            esac
        ;;
        tips_user_not_in_docker_group)
            current_user=$(whoami)
            case $LANGUAGE in
                zh_CN)
                    echo "用户 $current_user 不具备 Docker 命令的权限。"
                    echo "请将用户添加到 docker 组中，使用以下命令："
                    echo "sudo usermod -aG docker $current_user"
                    echo "如果您没有 sudo 权限，也可以在稍后使用以下指令启动。"
                    echo "docker compose up -d"
                ;;
                *)
                    echo "User $current_user does not have permission to run Docker commands."
                    echo "Please add the user to the docker group with the following command:"
                    echo "sudo usermod -aG docker $current_user"
                    echo "If you do not have sudo permissions, you can also start later with the following command."
                    echo "docker compose up -d"
                ;;
            esac
        ;;
        tips_allow_ports)
            case $LANGUAGE in
                zh_CN)
                    echo "请确保服务器以下端口未被占用且能被访问：3210, 9000, 9001, 7001"
                ;;
                *)
                    echo "Please make sure the following ports on the server are not occupied and can be accessed: 3210, 9000, 9001, 7001"
                ;;
            esac
        ;;
        ask_pull_images)
            case $LANGUAGE in
                zh_CN)
                    echo "是否要拉取最新镜像？"
                ;;
                *)
                    echo "Do you want to pull the latest images?"
                ;;
            esac
        ;;
        ask_regenerate_secrets)
            case $LANGUAGE in
                zh_CN)
                    echo "是否要重新生成安全密钥？"
                ;;
                *)
                    echo "Do you want to regenerate security secrets?"
                ;;
            esac
        ;;
        ask_deploy_mode)
            case $LANGUAGE in
                zh_CN)
                    echo "请选择部署模式："
                    echo "(0) 域名模式（访问时无需指明端口），需要使用反向代理服务 LobeChat, MinIO, Casdoor ，并分别分配一个域名；"
                    echo "(1) 端口模式（访问时需要指明端口，如使用IP访问，或域名+端口访问），需要放开指定端口；"
                    echo "(2) 本地模式（仅供本地测试使用）"
                    echo "如果你对这些内容疑惑，可以先选择使用本地模式进行部署，稍后根据文档指引再进行修改。"
                    echo "https://lobehub.com/docs/self-hosting/server-database/docker-compose"
                ;;
                *)
                    echo "Please select the deployment mode:"
                    echo "(0) Domain mode (no need to specify the port when accessing), you need to use the reverse proxy service LobeChat, MinIO, Casdoor, and assign a domain name respectively;"
                    echo "(1) Port mode (need to specify the port when accessing, such as using IP access, or domain name + port access), you need to open the specified port;"
                    echo "(2) Local mode (for local testing only)"
                    echo "If you are confused about these contents, you can choose to deploy in local mode first, and then modify according to the document guide later."
                    echo "https://lobehub.com/docs/self-hosting/server-database/docker-compose"
                ;;
            esac
        ;;
        ask_host)
            case $LANGUAGE in
                zh_CN)
                    echo " 服务的域名/IP（不含端口及http协议）："
                ;;
                *)
                    echo " Domain/IP of the service (without port and http protocol):"
                ;;
            esac
        ;;
        ask_protocol)
            case $LANGUAGE in
                zh_CN)
                    echo "请选择访问服务的协议（http/https）："
                    echo "注意，当前部署脚本不支持：为单一服务指定不同的协议、自签证书。"
                ;;
                *)
                    echo "Please select the protocol to access the service (http/https):"
                    echo "Note that the current deployment script does not support: specifying different protocols for a single service, self-signed certificates."
                ;;
            esac
        ;;
    esac
}

# Function to download files
download_file() {
    local file_url="$1"
    local local_file="$2"
    
    if [ "$FORCE_DOWNLOAD" = false ] && [ -e "$local_file" ]; then
        echo "$local_file" $(show_message "downloaded")
        return 0
    fi
    
    wget -q --show-progress "$file_url" -O "$local_file"
}

print_centered() {
    # Define colors
    declare -A colors
    colors=(
        [black]="\e[30m"
        [red]="\e[31m"
        [green]="\e[32m"
        [yellow]="\e[33m"
        [blue]="\e[34m"
        [magenta]="\e[35m"
        [cyan]="\e[36m"
        [white]="\e[37m"
        [reset]="\e[0m"
    )
    local text="$1"                                   # Get input texts
    local color="${2:-reset}"                         # Get color, default to reset
    local term_width=$(tput cols)                     # Get terminal width
    local text_length=${#text}                        # Get text length
    local padding=$(((term_width - text_length) / 2)) # Get padding
    # Check if the color is valid
    if [[ -z "${colors[$color]}" ]]; then
        echo "Invalid color specified. Available colors: ${!colors[@]}"
        return 1
    fi
    # Print the text with padding
    printf "%*s${colors[$color]}%s${colors[reset]}\n" $padding "" "$text"
}

# Usage:
# ```sh
#   ask "prompt" "default"
#   echo $ask_result
# ```
ask() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " result
        result=${result:-$default}
    else
        read -p "$prompt: " result
    fi
    # trim and assign to global variable
    ask_result=$(echo "$result" | xargs)
}

####################
## Main Process ##
####################

# ===============
# == Variables ==
# ===============
# File list
SUB_DIR="docker-compose/local"
FILES=(
    "$SUB_DIR/docker-compose.yml"
    "$SUB_DIR/init_data.json"
)
ENV_EXAMPLES=(
    "$SUB_DIR/.env.zh-CN.example"
    "$SUB_DIR/.env.example"
)
# Default values
CASDOOR_PASSWORD="123"
CASDOOR_SECRET="CASDOOR_SECRET"
MINIO_ROOT_PASSWORD="YOUR_MINIO_PASSWORD"
CASDOOR_HOST="localhost:8000"
MINIO_HOST="localhost:9000"
PROTOCOL="http"

section_download_files(){
    # Download files asynchronously
    if ! command -v wget &> /dev/null ; then
        echo "wget" $(show_message "tips_no_executable")
        exit 1
    fi
    
    download_file "$SOURCE_URL/${FILES[0]}" "docker-compose.yml"
    download_file "$SOURCE_URL/${FILES[1]}" "init_data.json"
    
    # Download .env.example with the specified language
    if [ "$LANGUAGE" = "zh_CN" ]; then
        download_file "$SOURCE_URL/${ENV_EXAMPLES[0]}" ".env"
    else
        download_file "$SOURCE_URL/${ENV_EXAMPLES[1]}" ".env"
    fi
}
# If the folder `data` or `s3_data` exists, warn the user
if [ -d "data" ] || [ -d "s3_data" ]; then
    show_message "tips_already_installed"
    exit 0
else
    section_download_files
fi

section_configurate_host() {
    DEPLOY_MODE=$ask_result
    show_message "host_regenerate"
    # If run in local mode, skip this step
    if [[ "$DEPLOY_MODE" == "2" ]]; then
        HOST="localhost:3210"
        LOBE_HOST="$HOST"
        return 0
    fi
    
    # Check if sed is installed
    if ! command -v $SED_COMMAND &> /dev/null ; then
        echo "sed" $(show_message "tips_no_executable")
        exit 1
    fi
    
    # If user not specify host, try to get the server ip
    if [ -z "$HOST" ]; then
        HOST=$(hostname -I | awk '{print $1}')
    fi
    
    echo "LobeChat" $(show_message "ask_host")
    ask "(<yourip/domain>)" "$HOST"
    LOBE_HOST="$ask_result"
    
    case $DEPLOY_MODE in
        0)
            DEPLOY_MODE="domain"
            # If user use domain mode, ask for the domain of Minio and Casdoor
            echo "Minio S3 API" $(show_message "ask_host")
            ask "(<yourip/domain>)" ""
            MINIO_HOST="$ask_result"
            echo "Casdoor API" $(show_message "ask_host")
            ask "(<yourip/domain>)" ""
            CASDOOR_HOST="$ask_result"
            # Setup callback url for Casdoor
            $SED_COMMAND "s/"example.com"/${LOBE_HOST}/" init_data.json
        ;;
        1)
            DEPLOY_MODE="ip"
            # If user use ip mode, append the port to the host
            LOBE_HOST="${HOST}:3210"
            MINIO_HOST="${MINIO_HOST}:9000"
            # Setup callback url for Casdoor
            $SED_COMMAND "s/"localhost"/${LOBE_HOST}/" init_data.json
        ;;
        *)
            echo "Invalid deploy mode: $ask_result"
            exit 1
        ;;
    esac
    
    # lobe host
    $SED_COMMAND "s#^APP_URL=.*#APP_URL=http://$LOBE_HOST#" .env
    # auth related
    $SED_COMMAND "s#^AUTH_URL=.*#AUTH_URL=http://$LOBE_HOST/api/auth#" .env
    $SED_COMMAND "s#^AUTH_CASDOOR_ISSUER=.*#AUTH_CASDOOR_ISSUER=http://$CASDOOR_HOST#" .env
    $SED_COMMAND "s#^origin=.*#origin=http://$CASDOOR_HOST#" .env
    # s3 related
    $SED_COMMAND "s#^S3_PUBLIC_DOMAIN=.*#S3_PUBLIC_DOMAIN=http://$MINIO_HOST#" .env
    $SED_COMMAND "s#^S3_ENDPOINT=.*#S3_ENDPOINT=http://$MINIO_HOST#" .env

    # Configurate protocol
    if [[ "$DEPLOY_MODE" == "domain" ]]; then
        echo $(show_message "host_regenerate")
        ask "(http/https)" "http"
        if [[ "$ask_result" == "https" ]]; then
            PROTOCOL="https"
            # Replace all http with https
            $SED_COMMAND "s#http://#https://#" .env
        fi
    fi
    
    # Check if env modified success
    if [ $? -ne 0 ]; then
        echo $(show_message "host_regenerate_failed") "$HOST in \`.env\`"
    fi
}
show_message "ask_deploy_mode"
ask "(0,1,2)" "2"
if [[ "$ask_result" == "0" ]] || [[ "$ask_result" == "1" ]] || [[ "$ask_result" == "2" ]]; then
    section_configurate_host
else
    echo "Invalid deploy mode: $ask_result, please select 0, 1 or 2."
    exit 1
fi

# ==========================
# === Regenerate Secrets ===
# ==========================
section_regenerate_secrets() {
    # Check if openssl is installed
    if ! command -v openssl &> /dev/null ; then
        echo "openssl" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! command -v tr &> /dev/null ; then
        echo "tr" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! command -v fold &> /dev/null ; then
        echo "fold" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! command -v head &> /dev/null ; then
        echo "head" $(show_message "tips_no_executable")
        exit 1
    fi
    
    generate_key() {
        if [[ -z "$1" ]]; then
            echo "Usage: generate_key <length>"
            return 1
        fi
        echo $(openssl rand -hex $1 | tr -d '\n' | fold -w $1 | head -n 1)
    }
    
    if ! command -v sed &> /dev/null ; then
        echo "sed" $(show_message "tips_no_executable")
        exit 1
    fi
    echo $(show_message "security_secrect_regenerate")
    
    # Generate CASDOOR_SECRET
    CASDOOR_SECRET=$(generate_key 32)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_SECRET"
    else
        # Search and replace the value of CASDOOR_SECRET in .env
        $SED_COMMAND "s#^AUTH_CASDOOR_SECRET=.*#AUTH_CASDOOR_SECRET=${CASDOOR_SECRET}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "AUTH_CASDOOR_SECRET in \`.env\`"
        fi
        # replace `clientSecrect` in init_data.json
        $SED_COMMAND "s#dbf205949d704de81b0b5b3603174e23fbecc354#${CASDOOR_SECRET}#" init_data.json
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "AUTH_CASDOOR_SECRET in \`init_data.json\`"
        fi
    fi
    
    # Generate Casdoor User
    CASDOOR_USER="admin"
    CASDOOR_PASSWORD=$(generate_key 6)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_PASSWORD"
        CASDOOR_PASSWORD="123"
    else
        # replace `password` in init_data.json
        $SED_COMMAND "s/"123"/${CASDOOR_PASSWORD}/" init_data.json
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "CASDOOR_PASSWORD in \`init_data.json\`"
        fi
    fi
    # Generate Minio S3 User Password
    MINIO_ROOT_PASSWORD=$(generate_key 8)
    if [ $? -ne 0 ]; then
        echo $(show_message "security_secrect_regenerate_failed") "MINIO_ROOT_PASSWORD"
        MINIO_ROOT_PASSWORD="YOUR_MINIO_PASSWORD"
    else
        # Search and replace the value of S3_SECRET_ACCESS_KEY in .env
        $SED_COMMAND "s#^MINIO_ROOT_PASSWORD=.*#MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}#" .env
        if [ $? -ne 0 ]; then
            echo $(show_message "security_secrect_regenerate_failed") "MINIO_ROOT_PASSWORD in \`.env\`"
        fi
    fi
}
show_message "ask_regenerate_secrets"
ask "(y/n)" "y"
if [[ "$ask_result" == "y" ]]; then
    section_regenerate_secrets
fi

# ========================
# == Pull Docker Images ==
# ========================
section_pull_images() {
    current_user=$(whoami)
    # If user is not in docker group, show message
    if ! groups "$current_user" | grep -q "\bdocker\b"; then
        show_message "tips_user_not_in_docker_group"
        sleep 3
    fi
    if ! command -v docker &> /dev/null ; then
        echo "docker" $(show_message "tips_no_executable")
        exit 1
    fi
    if ! docker compose &> /dev/null ; then
        echo "docker-compose" $(show_message "tips_no_executable")
        exit 1
    fi
    docker compose pull
}
show_message "ask_pull_images"
ask "(y/n)" "y"
if [[ "$ask_result" == "y" ]]; then
    section_pull_images
fi

section_display_configurated_report() {
    # Display configuration reports
    echo $(show_message "security_secrect_regenerate_report")
    
    echo -e "LobeChat: \n  - URL: $PROTOCOL://$LOBE_HOST"
    echo -e "Casdoor: \n  - URL: $PROTOCOL://$CASDOOR_HOST \n  - Admin: admin\n  - User: user\n  - Password: ${CASDOOR_PASSWORD}\n  - Client Secret: ${CASDOOR_SECRET}"
    echo -e "Minio: \n - URL: $PROTOCOL://$MINIO_HOST \n - Username: admin\n  - Password: ${MINIO_ROOT_PASSWORD}\n"
    
    # Display final message
    printf "\n%s\n\n" "$(show_message "tips_run_command")"
    print_centered "docker compose up -d" "green"
    printf "\n%s" "$(show_message "tips_show_documentation")"
    printf "%s\n" $(show_message "tips_show_documentation_url")
    printf "\n\e[33m%s\e[0m\n" "$(show_message "tips_warning")"
}
section_display_configurated_report