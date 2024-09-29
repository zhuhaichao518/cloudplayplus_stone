import os
import sys
import subprocess
from http.server import HTTPServer, SimpleHTTPRequestHandler

# 自定义的请求处理器，添加 CORS 头
class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # 添加 CORS 头
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

# 检查并安装依赖
def install_dependencies():
    try:
        # 确保 http.server 是内置的，只需确保 Python 环境正确
        subprocess.check_call([sys.executable, '-m', 'ensurepip', '--upgrade'])
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '--upgrade', 'pip'])
    except subprocess.CalledProcessError:
        print("Error installing pip or upgrading it.")
        sys.exit(1)

# 启动服务器
def start_server(directory):
    os.chdir(directory)
    handler = CORSRequestHandler
    port = 8000  # 你可以自定义端口
    server_address = ('0.0.0.0', port)  # 绑定到所有接口，使局域网可访问
    httpd = HTTPServer(server_address, handler)
    print(f"Serving HTTP on {server_address[0]} port {port} in {os.getcwd()} directory")
    print(f"Access the server on: http://<your-ip-address>:{port}")
    httpd.serve_forever()

# 主函数
def main():
    # 设置目标目录为当前目录下的 build/web
    target_directory = os.path.join(os.getcwd(), 'build', 'web')
    
    # 检查目标目录是否存在
    if not os.path.isdir(target_directory):
        print(f"Error: The target directory {target_directory} does not exist.")
        sys.exit(1)
    
    # 尝试启动服务器，若失败则安装依赖
    try:
        start_server(target_directory)
    except ModuleNotFoundError:
        print("Required dependencies are missing. Installing...")
        install_dependencies()
        start_server(target_directory)

if __name__ == "__main__":
    main()