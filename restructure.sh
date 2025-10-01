#!/usr/bin/env bash
set -euo pipefail

# Restructure Chatdo project into feature-first folders.
# This script is idempotent-ish: it checks for file existence before moving.
# Run from the repo root (where lib/ lives).

if [ ! -d "lib" ]; then
  echo "❌ This doesn't look like the repo root (lib/ not found)."
  exit 1
fi

# Ensure git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not inside a git repository."
  exit 1
fi

# Optional: require clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "⚠️  You have uncommitted changes. It's safer to commit or stash before restructuring."
  read -p "Continue anyway? [y/N] " yn
  case $yn in
    [Yy]*) ;;
    *) echo "Aborting."; exit 1;;
  esac
fi

echo "📁 Creating target directories..."
mkdir -p lib/{app,bootstrap,experimental,platform/webview,shared/{auth,data/{firestore,hive,repos,models},providers,services,utils,widgets/common},features/{chat,stock,tags,routine,text_dictionary,game}/{data,domain,presentation/{screens,widgets},utils}}
mkdir -p lib/features/stock/{services,domain/models}
mkdir -p lib/features/chat/presentation/widgets/blocks
mkdir -p lib/features/game/{core,flame,godot,overlay,progress,room,presentation/screens}
mkdir -p \
  lib/app \
  lib/bootstrap \
  lib/experimental \
  lib/features/chat/presentation/screens \
  lib/features/routine/presentation/screens \
  lib/features/tags/presentation/screens \
  lib/features/auth/presentation/screens \
  lib/features/profile/presentation/screens \
  lib/features/menu/presentation/screens \
  lib/features/webview/presentation/screens \
  lib/features/game/presentation/screens

move_if_exists () {
  local SRC="$1"
  local DST="$2"
  local DSTDIR
  DSTDIR="$(dirname "$DST")"
  mkdir -p "$DSTDIR"
  if git ls-files --error-unmatch "$SRC" >/dev/null 2>&1; then
    echo "➡️  git mv $SRC $DST"
    git mv "$SRC" "$DST"
  elif [ -e "$SRC" ]; then
    echo "➡️  mv $SRC $DST (untracked)"
    mv "$SRC" "$DST"
    git add "$DST" 2>/dev/null || true
  else
    echo "… skip (not found): $SRC"
    fi
    }

echo "🚚 Moving root/app files..."
move_if_exists lib/main.dart                          lib/bootstrap/
move_if_exists lib/firebase_options.dart              lib/bootstrap/
move_if_exists lib/tab_nav.dart                       lib/app/
move_if_exists lib/local_asset_server.dart            lib/experimental/

echo "🚚 Moving screens (chat/routine/tags/auth/profile/menu/webview/game)..."
move_if_exists lib/chatdo/screens/home_chat_screen.dart           lib/features/chat/presentation/screens/
move_if_exists lib/chatdo/screens/calendar_screen.dart            lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/routine_list_screen.dart        lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/schedule_overview_screen.dart   lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/day_schedule_list_screen.dart   lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/todo_list_screen.dart           lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/done_list_screen.dart           lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/schedule_list_screen.dart       lib/features/routine/presentation/screens/
move_if_exists lib/chatdo/screens/schedule_detail_screen.dart     lib/features/routine/presentation/screens/

move_if_exists lib/chatdo/screens/tag_list_screen.dart            lib/features/tags/presentation/screens/
move_if_exists lib/chatdo/screens/tag_log_screen.dart             lib/features/tags/presentation/screens/
move_if_exists lib/chatdo/screens/tag_management_screen.dart      lib/features/tags/presentation/screens/

move_if_exists lib/chatdo/screens/login_screen.dart               lib/features/auth/presentation/screens/
move_if_exists lib/chatdo/screens/profile_screen.dart             lib/features/profile/presentation/screens/
move_if_exists lib/chatdo/screens/menu_screen.dart                lib/app/menu/

move_if_exists lib/chatdo/screens/webview_flutter.dart            lib/platform/webview/
move_if_exists lib/chatdo/screens/room_screen.dart                lib/features/game/presentation/screens/
move_if_exists lib/chatdo/screens/hilohilo_game_view.dart         lib/features/game/presentation/screens/

echo "🚚 Moving widgets..."
move_if_exists lib/chatdo/widgets/chat_input_box.dart             lib/features/chat/presentation/widgets/
move_if_exists lib/chatdo/widgets/chat_message_card.dart          lib/features/chat/presentation/widgets/
move_if_exists lib/chatdo/widgets/image_upload_preview.dart       lib/features/chat/presentation/widgets/
move_if_exists lib/chatdo/widgets/blocks/block_editor.dart        lib/features/chat/presentation/widgets/blocks/
move_if_exists lib/chatdo/widgets/blocks/text_block_widget.dart   lib/features/chat/presentation/widgets/blocks/
move_if_exists lib/chatdo/widgets/blocks/image_block_widget.dart  lib/features/chat/presentation/widgets/blocks/
move_if_exists lib/chatdo/widgets/blocks/reorderable_block_list.dart lib/features/chat/presentation/widgets/blocks/
move_if_exists lib/chatdo/widgets/blocks/select_image_and_add.dart   lib/features/chat/presentation/widgets/blocks/

move_if_exists lib/chatdo/widgets/routine_edit_form.dart          lib/features/routine/presentation/widgets/
move_if_exists lib/chatdo/widgets/schedule_entry_tile.dart        lib/features/routine/presentation/widgets/
move_if_exists lib/chatdo/widgets/mode_date_selector.dart         lib/features/routine/presentation/widgets/

move_if_exists lib/chatdo/widgets/tag_selector.dart               lib/features/tags/presentation/widgets/
move_if_exists lib/chatdo/widgets/tag_tile.dart                   lib/features/tags/presentation/widgets/
move_if_exists lib/chatdo/widgets/tag_filter_bar.dart             lib/features/tags/presentation/widgets/
move_if_exists lib/chatdo/widgets/custom_tag_dialog.dart          lib/features/tags/presentation/widgets/
move_if_exists lib/chatdo/widgets/kakao_chat_style.dart           lib/features/chat/presentation/styles/

echo "🚚 Moving data/repos/models/services/providers/utils..."
move_if_exists lib/chatdo/data/firestore/repos/message_repo.dart          lib/features/chat/data/
move_if_exists lib/chatdo/data/firestore/repos/routine_repo.dart          lib/features/routine/data/
move_if_exists lib/chatdo/data/firestore/repos/tags_repo.dart             lib/features/tags/data/
move_if_exists lib/chatdo/data/firestore/repos/text_dictionary_repo.dart  lib/features/text_dictionary/data/
move_if_exists lib/chatdo/data/tag_repository.dart                        lib/features/tags/data/

# Shared models
for f in \
  lib/chatdo/models/content_block.dart \
  lib/chatdo/models/enums.dart \
  lib/chatdo/models/message.dart \
  lib/chatdo/models/routine_model.dart \
  lib/chatdo/models/schedule_entry.dart \
  lib/chatdo/models/upload_item.dart \
  lib/chatdo/models/weather_data.dart \
  lib/chatdo/models/user_tag.dart \
  lib/chatdo/models/message.g.dart
do
  move_if_exists "$f" lib/shared/data/models/
done

# Shared services/providers/utils
move_if_exists lib/chatdo/services/auth_service.dart         lib/shared/auth/
move_if_exists lib/chatdo/services/firestore_service.dart    lib/shared/data/firestore/
move_if_exists lib/chatdo/services/image_upload_service.dart lib/shared/services/
move_if_exists lib/chatdo/services/sync_service.dart         lib/shared/services/
move_if_exists lib/chatdo/services/weather_service.dart      lib/shared/services/
move_if_exists lib/chatdo/services/message_service.dart      lib/shared/services/

move_if_exists lib/chatdo/providers/audio_manager.dart       lib/shared/providers/
move_if_exists lib/chatdo/providers/schedule_provider.dart   lib/shared/providers/

move_if_exists lib/chatdo/utils/schedule_actions.dart        lib/features/routine/utils/
move_if_exists lib/chatdo/utils/schedule_sorter.dart         lib/shared/utils/
move_if_exists lib/chatdo/utils/friendly_date_utils.dart     lib/shared/utils/
move_if_exists lib/chatdo/utils/image_uploader.dart          lib/shared/utils/
move_if_exists lib/chatdo/utils/image_source_selector.dart   lib/shared/utils/
move_if_exists lib/chatdo/utils/nlp_parser.dart              lib/shared/utils/
move_if_exists lib/chatdo/utils/weekdays.dart                lib/shared/utils/

echo "🚚 Moving text_dictionary feature..."
# Preserve existing sub-structure
if [ -d lib/chatdo/features/text_dictionary ]; then
  git mv lib/chatdo/features/text_dictionary lib/features/text_dictionary
fi

echo "🚚 Moving stock feature..."
move_if_exists lib/chatdo/stock/stock_items_screen.dart      lib/features/stock/presentation/screens/
move_if_exists lib/chatdo/stock/stock_list_screen.dart       lib/features/stock/presentation/screens/
move_if_exists lib/chatdo/stock/stock_sub_list_screen.dart   lib/features/stock/presentation/screens/

move_if_exists lib/chatdo/stock/stock_repo.dart              lib/features/stock/data/
move_if_exists lib/chatdo/stock/hive_stock_repo.dart         lib/features/stock/data/
move_if_exists lib/chatdo/stock/firebase_stock_repo.dart     lib/features/stock/data/
move_if_exists lib/chatdo/stock/hybrid_stock_repo.dart       lib/features/stock/data/
move_if_exists lib/chatdo/stock/stock_sync_service.dart      lib/features/stock/services/

move_if_exists lib/chatdo/stock/stock_item.dart              lib/features/stock/domain/models/
move_if_exists lib/chatdo/stock/stock_item.manual.dart       lib/features/stock/domain/models/

echo "🚚 Moving game feature (Godot/Flame/etc.)..."
# If a top-level lib/game exists, move its contents
if [ -d lib/game ]; then
  # Move subfolders individually to preserve structure
  for dir in components core overlay progress room story flame; do
    if [ -d "lib/game/$dir" ]; then
      git mv "lib/game/$dir" "lib/features/game/$dir"
    fi
  done
fi

move_if_exists lib/chatdo/godot/godot_embed_screen.dart      lib/features/game/godot/

echo "🧹 Optional: remove zipped artifacts from lib/chatdo (if any)"
for z in lib/chatdo/*.zip; do
  if [ -f "$z" ]; then
    echo "🗑️  Removing $z"
    git rm -f "$z"
  fi
done

echo "✅ Done moving files. Next steps:"
echo "  1) Run ./update_imports.sh to rewrite import paths"
echo "  2) Run: flutter analyze"
echo "  3) Fix any remaining imports manually if needed"
echo "  4) Commit: git commit -m 'Restructure to feature-first layout'"
