import os
from blinker import Signal

from biz.entity.review_entity import MergeRequestReviewEntity, PushReviewEntity
from biz.service.review_service import ReviewService
from biz.utils.im import notifier

# 定义全局事件管理器（事件信号）
event_manager = {
    "merge_request_reviewed": Signal(),
    "push_reviewed": Signal(),
}


# 定义事件处理函数
def on_merge_request_reviewed(mr_review_entity: MergeRequestReviewEntity):
    # 检查是否启用简短通知模式
    brief_mode = os.getenv('BRIEF_NOTIFICATION_ENABLED', '0') == '1'

    lab_project = "<font color=#999999>项目: </font>"
    lab_author = "<font color=#999999>提交者: </font>"
    lab_source_branch = "<font color=#999999>源分支: </font>"
    lab_target_branch = "<font color=#999999>目标分支: </font>"
    lab_commit = "<font color=#999999>提交信息: </font>"
    lab_review = "<font color=#999999>PR链接: </font>"

    if brief_mode:
        # 简短通知：仅包含提交信息和评论链接
        s_msg = "\n".join(commit["message"].strip() for commit in mr_review_entity.commits)
        im_msg = f"""
{lab_project}"<font color=#00BB99>{mr_review_entity.project_name}</font>"
{lab_author}"<font color=#FF9C00>{mr_review_entity.author}</font>"
{lab_source_branch}{mr_review_entity.source_branch}
{lab_target_branch}{mr_review_entity.target_branch}
{lab_commit}{s_msg}
{lab_review}**[查看合并详情及AI评论]({mr_review_entity.url})**
        """
    else:
        # 完整通知：包含所有AI评论内容
        im_msg = f"""
### 🔀 {mr_review_entity.project_name}: Merge Request

#### 合并请求信息:
- **提交者:** {mr_review_entity.author}

- **源分支**: {mr_review_entity.source_branch}
- **目标分支**: {mr_review_entity.target_branch}
- **更新时间**: {mr_review_entity.updated_at}
- **提交信息:** {mr_review_entity.commit_messages}

- **[查看合并详情]({mr_review_entity.url})**

- **AI Review 结果:** 

{mr_review_entity.review_result}
        """

    msg_title = "<font color=#88ff00>Merge Request Review</font>"
    notifier.send_notification(content=im_msg, msg_type='markdown', title=msg_title,
                               project_name=mr_review_entity.project_name, url_slug=mr_review_entity.url_slug,
                               webhook_data=mr_review_entity.webhook_data)

    # 记录到数据库
    ReviewService().insert_mr_review_log(mr_review_entity)


def on_push_reviewed(entity: PushReviewEntity):
    # 检查是否启用简短通知模式
    brief_mode = os.getenv('BRIEF_NOTIFICATION_ENABLED', '0') == '1'
    
    # 发送IM消息通知
    im_msg = f"### 🚀 {entity.project_name}: Push\n\n"
    im_msg += "#### 提交记录:\n"

    for commit in entity.commits:
        message = commit.get('message', '').strip()
        author = commit.get('author', 'Unknown Author')
        timestamp = commit.get('timestamp', '')
        url = commit.get('url', '#')
        
        if brief_mode:
            # 简短模式：仅显示提交信息和链接
            im_msg += (
                f"- **提交信息**: {message}\n"
                f"- **提交者**: {author}\n"
                f"- [查看提交详情及AI评论]({url})\n\n"
            )
        else:
            # 完整模式：显示所有信息
            im_msg += (
                f"- **提交信息**: {message}\n"
                f"- **提交者**: {author}\n"
                f"- **时间**: {timestamp}\n"
                f"- [查看提交详情]({url})\n\n"
            )

    # 仅在非简短模式下显示AI Review结果
    if not brief_mode and entity.review_result:
        im_msg += f"#### AI Review 结果: \n {entity.review_result}\n\n"
    
    notifier.send_notification(content=im_msg, msg_type='markdown',title=f"{entity.project_name} Push Event",
                               project_name=entity.project_name, url_slug=entity.url_slug,
                               webhook_data=entity.webhook_data)

    # 记录到数据库
    ReviewService().insert_push_review_log(entity)


# 连接事件处理函数到事件信号
event_manager["merge_request_reviewed"].connect(on_merge_request_reviewed)
event_manager["push_reviewed"].connect(on_push_reviewed)
