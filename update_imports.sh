#!/usr/bin/env bash
set -euo pipefail

# Update import paths after restructure.
# macOS: sed -i '' -E  ; Linux: sed -i -E
SED_INPLACE=()
if sed --version >/dev/null 2>&1; then
  # GNU sed (Linux)
  SED_INPLACE=(-i -E)
else
  # BSD sed (macOS)
  SED_INPLACE=(-i '' -E)
fi

rewrite () {
  from="$1"
  to="$2"
  echo "🔁 $from  →  $to"
  # Replace both package: and relative-style imports that include the path
  sed "${SED_INPLACE[@]}" "s#package:[^\"']*/$from#package:chatdo/$to#g" $(git ls-files '*.dart') || true
  sed "${SED_INPLACE[@]}" "s#\"$from#\"$to#g" $(git ls-files '*.dart') || true
  sed "${SED_INPLACE[@]}" "s#'$from#'$to#g" $(git ls-files '*.dart') || true

}

# Root/app
rewrite "main.dart"                            "bootstrap/main.dart"
rewrite "firebase_options.dart"                "bootstrap/firebase_options.dart"
rewrite "tab_nav.dart"                         "app/tab_nav.dart"
rewrite "local_asset_server.dart"              "experimental/local_asset_server.dart"

# Screens - chat
rewrite "chatdo/screens/home_chat_screen.dart" "features/chat/presentation/screens/home_chat_screen.dart"

# Screens - routine & calendar
rewrite "chatdo/screens/calendar_screen.dart"            "features/routine/presentation/screens/calendar_screen.dart"
rewrite "chatdo/screens/routine_list_screen.dart"        "features/routine/presentation/screens/routine_list_screen.dart"
rewrite "chatdo/screens/schedule_overview_screen.dart"   "features/routine/presentation/screens/schedule_overview_screen.dart"
rewrite "chatdo/screens/day_schedule_list_screen.dart"   "features/routine/presentation/screens/day_schedule_list_screen.dart"
rewrite "chatdo/screens/todo_list_screen.dart"           "features/routine/presentation/screens/todo_list_screen.dart"
rewrite "chatdo/screens/done_list_screen.dart"           "features/routine/presentation/screens/done_list_screen.dart"
rewrite "chatdo/screens/schedule_list_screen.dart"       "features/routine/presentation/screens/schedule_list_screen.dart"
rewrite "chatdo/screens/schedule_detail_screen.dart"     "features/routine/presentation/screens/schedule_detail_screen.dart"

# Screens - tags
rewrite "chatdo/screens/tag_list_screen.dart"            "features/tags/presentation/screens/tag_list_screen.dart"
rewrite "chatdo/screens/tag_log_screen.dart"             "features/tags/presentation/screens/tag_log_screen.dart"
rewrite "chatdo/screens/tag_management_screen.dart"      "features/tags/presentation/screens/tag_management_screen.dart"

# Screens - auth/profile/menu/webview/game
rewrite "chatdo/screens/login_screen.dart"               "features/auth/presentation/screens/login_screen.dart"
rewrite "chatdo/screens/profile_screen.dart"             "features/profile/presentation/screens/profile_screen.dart"
rewrite "chatdo/screens/menu_screen.dart"                "app/menu/menu_screen.dart"
rewrite "chatdo/screens/webview_flutter.dart"            "platform/webview/webview_flutter.dart"
rewrite "chatdo/screens/room_screen.dart"                "features/game/presentation/screens/room_screen.dart"
rewrite "chatdo/screens/hilohilo_game_view.dart"         "features/game/presentation/screens/hilohilo_game_view.dart"

# Widgets - chat blocks
rewrite "chatdo/widgets/chat_input_box.dart"             "features/chat/presentation/widgets/chat_input_box.dart"
rewrite "chatdo/widgets/chat_message_card.dart"          "features/chat/presentation/widgets/chat_message_card.dart"
rewrite "chatdo/widgets/image_upload_preview.dart"       "features/chat/presentation/widgets/image_upload_preview.dart"
rewrite "chatdo/widgets/blocks/block_editor.dart"        "features/chat/presentation/widgets/blocks/block_editor.dart"
rewrite "chatdo/widgets/blocks/text_block_widget.dart"   "features/chat/presentation/widgets/blocks/text_block_widget.dart"
rewrite "chatdo/widgets/blocks/image_block_widget.dart"  "features/chat/presentation/widgets/blocks/image_block_widget.dart"
rewrite "chatdo/widgets/blocks/reorderable_block_list.dart" "features/chat/presentation/widgets/blocks/reorderable_block_list.dart"
rewrite "chatdo/widgets/blocks/select_image_and_add.dart"   "features/chat/presentation/widgets/blocks/select_image_and_add.dart"

# Widgets - routine
rewrite "chatdo/widgets/routine_edit_form.dart"          "features/routine/presentation/widgets/routine_edit_form.dart"
rewrite "chatdo/widgets/schedule_entry_tile.dart"        "features/routine/presentation/widgets/schedule_entry_tile.dart"
rewrite "chatdo/widgets/mode_date_selector.dart"         "features/routine/presentation/widgets/mode_date_selector.dart"

# Widgets - tags
rewrite "chatdo/widgets/tag_selector.dart"               "features/tags/presentation/widgets/tag_selector.dart"
rewrite "chatdo/widgets/tag_tile.dart"                   "features/tags/presentation/widgets/tag_tile.dart"
rewrite "chatdo/widgets/tag_filter_bar.dart"             "features/tags/presentation/widgets/tag_filter_bar.dart"
rewrite "chatdo/widgets/custom_tag_dialog.dart"          "features/tags/presentation/widgets/custom_tag_dialog.dart"

# Data/repos
rewrite "chatdo/data/firestore/repos/message_repo.dart"          "features/chat/data/message_repo.dart"
rewrite "chatdo/data/firestore/repos/routine_repo.dart"          "features/routine/data/routine_repo.dart"
rewrite "chatdo/data/firestore/repos/tags_repo.dart"             "features/tags/data/tags_repo.dart"
rewrite "chatdo/data/firestore/repos/text_dictionary_repo.dart"  "features/text_dictionary/data/text_dictionary_repo.dart"
rewrite "chatdo/data/tag_repository.dart"                        "features/tags/data/tag_repository.dart"

# Shared models/services/providers/utils
for from in \
  "chatdo/models/content_block.dart" \
  "chatdo/models/enums.dart" \
  "chatdo/models/message.dart" \
  "chatdo/models/routine_model.dart" \
  "chatdo/models/schedule_entry.dart" \
  "chatdo/models/upload_item.dart" \
  "chatdo/models/weather_data.dart" \
  "chatdo/models/user_tag.dart" \
  "chatdo/models/message.g.dart"
do
  rewrite "$from" "shared/data/models/$(basename "$from")"
done

rewrite "chatdo/services/auth_service.dart"         "shared/auth/auth_service.dart"
rewrite "chatdo/services/firestore_service.dart"    "shared/data/firestore/firestore_service.dart"
rewrite "chatdo/services/image_upload_service.dart" "shared/services/image_upload_service.dart"
rewrite "chatdo/services/sync_service.dart"         "shared/services/sync_service.dart"
rewrite "chatdo/services/weather_service.dart"      "shared/services/weather_service.dart"
rewrite "chatdo/services/message_service.dart"      "shared/services/message_service.dart"

rewrite "chatdo/providers/audio_manager.dart"       "shared/providers/audio_manager.dart"
rewrite "chatdo/providers/schedule_provider.dart"   "shared/providers/schedule_provider.dart"

rewrite "chatdo/utils/schedule_actions.dart"        "features/routine/utils/schedule_actions.dart"
rewrite "chatdo/utils/schedule_sorter.dart"         "shared/utils/schedule_sorter.dart"
rewrite "chatdo/utils/friendly_date_utils.dart"     "shared/utils/friendly_date_utils.dart"
rewrite "chatdo/utils/image_uploader.dart"          "shared/utils/image_uploader.dart"
rewrite "chatdo/utils/image_source_selector.dart"   "shared/utils/image_source_selector.dart"
rewrite "chatdo/utils/nlp_parser.dart"              "shared/utils/nlp_parser.dart"
rewrite "chatdo/utils/weekdays.dart"                "shared/utils/weekdays.dart"

# text_dictionary root folder move (paths inside may not need changes if using relative imports)
# Stock
rewrite "chatdo/stock/stock_items_screen.dart"      "features/stock/presentation/screens/stock_items_screen.dart"
rewrite "chatdo/stock/stock_list_screen.dart"       "features/stock/presentation/screens/stock_list_screen.dart"
rewrite "chatdo/stock/stock_sub_list_screen.dart"   "features/stock/presentation/screens/stock_sub_list_screen.dart"
rewrite "chatdo/stock/stock_repo.dart"              "features/stock/data/stock_repo.dart"
rewrite "chatdo/stock/hive_stock_repo.dart"         "features/stock/data/hive_stock_repo.dart"
rewrite "chatdo/stock/firebase_stock_repo.dart"     "features/stock/data/firebase_stock_repo.dart"
rewrite "chatdo/stock/hybrid_stock_repo.dart"       "features/stock/data/hybrid_stock_repo.dart"
rewrite "chatdo/stock/stock_sync_service.dart"      "features/stock/services/stock_sync_service.dart"
rewrite "chatdo/stock/stock_item.dart"              "features/stock/domain/models/stock_item.dart"
rewrite "chatdo/stock/stock_item.manual.dart"       "features/stock/domain/models/stock_item.manual.dart"

# Game
rewrite "game/"                                     "features/game/"
rewrite "chatdo/godot/godot_embed_screen.dart"      "features/game/godot/godot_embed_screen.dart"



echo "✅ Imports rewritten. Now run:"
echo "   flutter analyze"
echo "   dart format ."
