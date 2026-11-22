#!/bin/bash
# Сборка темы PS4 из видео.
# Использование: ./build_theme.sh /путь/к/video.mp4
# Переменные:
#   PKG_TOOL  - путь к твоему инструменту упаковки (orbis-pub-cmd или аналог), опционально
#   THEME_DIR - папка с шаблоном проекта темы, опционально
set -euo pipefail

SRC="${1:?Укажи путь к video.mp4}"
OUT="theme_build"

command -v ffmpeg >/dev/null || { echo "Нужен ffmpeg"; exit 1; }

# 1. Перекодирование: 1920x1080, H.264 High, 30 fps, без звука
ffmpeg -y -v error -i "$SRC" \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1,fps=30,format=yuv420p" \
  -c:v libx264 -profile:v high -level 4.1 -preset slow -crf 18 \
  -maxrate 12M -bufsize 24M -movflags +faststart -an theme_video.mp4

# 2. Обложка (первый кадр)
ffmpeg -y -v error -ss 0.5 -i theme_video.mp4 -frames:v 1 cover_1920x1080.png

# 3. Структура сборки
rm -rf "$OUT" && mkdir -p "$OUT/sce_sys"
cp theme_video.mp4 "$OUT/sce_sys/theme_video.mp4"
cp cover_1920x1080.png "$OUT/sce_sys/pic1.png"
cp cover_1920x1080.png "$OUT/sce_sys/pic0.png"
cp cover_1920x1080.png "$OUT/sce_sys/icon0.png"
# Если есть шаблон темы, подкладываем его поверх (param.sfo, файлы сборки и т.д.)
if [ -n "${THEME_DIR:-}" ] && [ -d "$THEME_DIR" ]; then
  cp -r "$THEME_DIR"/. "$OUT"/
  cp theme_video.mp4 "$OUT/sce_sys/theme_video.mp4"
fi

# 4. Упаковка в PKG
if [ -n "${PKG_TOOL:-}" ]; then
  echo "Запускаю упаковку: $PKG_TOOL"
  "$PKG_TOOL" "$OUT" || { echo "Упаковка не удалась"; exit 1; }
else
  echo "PKG_TOOL не задан. Файлы подготовлены в $OUT/."
  echo "Запусти свой инструмент упаковки на этой папке и проверь структуру по его документации."
fi
echo "Готово."
