module LineBot
  class MenuListBuilder
    # rubocop:disable Metrics/MethodLength
    def self.menu_list(message)
      {
        type: "text",
        text: message,
        quickReply: {
          items: [
            {
              type: "action",
              action: {
                type: "message",
                label: "タスクの開始日変更",
                text: "タスクの開始日変更"
              }
            },
            {
              type: "action",
              action: {
                type: "message",
                label: "タスクの終了日変更",
                text: "タスクの終了日変更"
              }
            },
            {
              type: "action",
              action: {
                type: "message",
                label: "タスク確認",
                text: "タスク確認"
              }
            },
            {
              type: "action",
              action: {
                type: "message",
                label: "星座確認",
                text: "星座確認"
              }
            },
            {
              type: "action",
              action: {
                type: "message",
                label: "両方確認",
                text: "両方確認"
              }
            },
            {
              type: "action",
              action: {
                type: "message",
                label: "星座の名前で確認",
                text: "星座の名前で確認"
              }
            },
            {
              type: "action",
              action: {
                type: "message",
                label: "タイトルか詳細から検索",
                text: "タイトルか詳細から検索"
              }
            }
          ]
        }
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
end
