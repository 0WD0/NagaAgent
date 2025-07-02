import requests
import json
import logging
import sys
import os

# 添加项目根目录到路径，以便导入config
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

try:
    from config import DEEPSEEK_API_KEY, DEEPSEEK_BASE_URL, DEEPSEEK_MODEL
    API_KEY = DEEPSEEK_API_KEY
    API_URL = f"{DEEPSEEK_BASE_URL.rstrip('/')}/chat/completions"
except ImportError:
    # 如果无法导入config，使用环境变量作为备选
    API_KEY = os.getenv("DEEPSEEK_API_KEY", "sk-placeholder-key-not-set")
    API_URL = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com/v1") + "/chat/completions"

# 设置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# 缓存最近处理的文本
recent_context = []

def set_context(texts):
    """设置查询上下文"""
    global recent_context
    recent_context = texts[:0]  # 限制上下文长度
    logger.info(f"更新查询上下文: {recent_context}")

def query_knowledge(user_question):
    """使用 DeepSeek API 提取关键词并查询知识图谱"""
    context_str = "\n".join(recent_context) if recent_context else "无上下文"
    prompt = (
        f"基于以下上下文和用户问题，提取与知识图谱相关的关键词（如实体、关系），"
        f"仅返回核心关键词，避免无关词。返回 JSON 格式的关键词列表：\n"
        f"上下文：\n{context_str}\n"
        f"问题：{user_question}\n"
        f"输出格式：```json\n[]\n```"
    )

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    body = {
        "model": DEEPSEEK_MODEL,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 150,
        "temperature": 0.5  # 降低温度，提高精准度
    }

    try:
        response = requests.post(API_URL, headers=headers, json=body, timeout=10)
        response.raise_for_status()
        content = response.json()

        if "choices" not in content or not content["choices"]:
            logger.error("DeepSeek API 响应中未找到 'choices' 字段")
            return "无法处理 API 响应，请稍后重试。"

        raw_content = content["choices"][0]["message"]["content"]
        try:
            raw_content = raw_content.strip()
            if raw_content.startswith("```json") and raw_content.endswith("```"):
                raw_content = raw_content[7:-3].strip()
            keywords = json.loads(raw_content)
            if not isinstance(keywords, list):
                raise ValueError("关键词应为列表")
        except (json.JSONDecodeError, ValueError) as e:
            logger.error(f"解析 DeepSeek 响应失败: {raw_content}, 错误: {e}")
            return f"无法解析关键词，请检查问题格式。"

        if not keywords:
            logger.warning("未提取到关键词")
            return "未找到相关关键词，请提供更具体的问题。"

        logger.info(f"提取关键词: {keywords}")
        from .graph import query_graph_by_keywords
        triples = query_graph_by_keywords(keywords)
        if not triples:
            logger.info(f"未找到相关三元组: {keywords}")
            return "未在知识图谱中找到相关信息。"

        answer = "我在知识图谱中找到以下相关信息：\n\n"
        for h, r, t in triples:
            answer += f"- {h} —[{r}]→ {t}\n"
        return answer

    except requests.exceptions.HTTPError as e:
        logger.error(f"DeepSeek API HTTP 错误: {e}")
        return "调用 DeepSeek API 失败，请检查 API 密钥或网络连接。"
    except requests.exceptions.RequestException as e:
        logger.error(f"DeepSeek API 请求失败: {e}")
        return "无法连接到 DeepSeek API，请检查网络。"
    except Exception as e:
        logger.error(f"查询过程中发生未知错误: {e}")
        return "查询过程中发生未知错误，请稍后重试。"