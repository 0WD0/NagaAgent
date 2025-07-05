import sys
import os
import json
from PyQt5.QtWidgets import QApplication, QWidget, QLabel, QVBoxLayout, QLineEdit, QPushButton
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
from config import config

def read_api_key():
    # 从统一配置系统读取
    return config.api.api_key if config.api.api_key != "sk-placeholder-key-not-set" else ""

def write_api_key(new_key):
    # 写入config.json统一配置文件
    config_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config.json')
    
    try:
        # 加载现有配置
        with open(config_path, 'r', encoding='utf-8') as f:
            config_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        config_data = {}
    
    # 更新API密钥
    if "api" not in config_data:
        config_data["api"] = {}
    config_data["api"]["api_key"] = new_key
    
    # 保存配置
    with open(config_path, 'w', encoding='utf-8') as f:
        json.dump(config_data, f, ensure_ascii=False, indent=2)
    
    # 重新加载配置
    from config import load_config
    global config
    config = load_config()

class ApiConfigWidget(QWidget):
    def __init__(s, parent=None):
        super().__init__(parent)
        s.setWindowTitle("API配置")
        s.setStyleSheet("border-radius:24px;")
        layout = QVBoxLayout(s)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(0)

        # 标题
        title = QLabel("API配置", s)
        title.setFont(QFont("Consolas", 20, QFont.Bold))  # 字号略小
        title.setStyleSheet("color:#fff;margin:0;padding:0;line-height:16px;")
        layout.addWidget(title, alignment=Qt.AlignLeft | Qt.AlignTop)

        # 输入框
        s.api_input = QLineEdit(s)
        s.api_input.setText(read_api_key())
        s.api_input.setStyleSheet(
            "background:#222;color:#fff;font:16pt 'Consolas';"
            "border-radius:8px;padding:6px 12px 6px 12px;margin:0;margin-top:-6px;border:none;"
        )
        layout.addWidget(s.api_input)

        # 保存按钮
        save_btn = QPushButton("保存", s)
        save_btn.setStyleSheet("background:#444;color:#fff;font:14pt 'Consolas';border-radius:8px;padding:6px 18px;")
        save_btn.clicked.connect(s.save_api_key)
        layout.addWidget(save_btn, alignment=Qt.AlignRight)

    def save_api_key(s):
        new_key = s.api_input.text().strip()
        write_api_key(new_key)
        s.api_input.setText(new_key)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = ApiConfigWidget()
    win.show()
    sys.exit(app.exec_()) 
