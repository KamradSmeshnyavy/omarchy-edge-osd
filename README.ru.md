# Omarchy Edge OSD

[🇬🇧 English](README.md)

OSD [Omarchy](https://omarchy.org) (клон стокового `omarchy.osd`): громкость, яркость и микрофон — вертикальный
слайдер, выезжающий из края экрана. Со сплошным баром у края — например, скином `frame` из
[omarchy-bar-skins](https://github.com/KamradSmeshnyavy/omarchy-bar-skins) — растёт прямо из рамки с вогнутыми
углами; иначе — плавающая карточка с отступом и тенью. Сообщения и медиа-OSD остаются стоковой карточкой.
Клики OSD не перехватывает.

## Установка

```sh
git clone https://github.com/KamradSmeshnyavy/omarchy-edge-osd ~/.config/omarchy/plugins/kamradsmeshnyavy.osd
omarchy-shell shell rescanPlugins
omarchy plugin enable kamradsmeshnyavy.osd        # обратно к стоку: omarchy plugin enable omarchy.osd
```

## Настройки

`~/.config/omarchy/osd.json`, применяются на лету; [Customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) —
Окна → OSD. Ключи — в [README.md](README.md#settings): стиль (`edge` / `nihil` / `stock`), край, положение вдоль края,
размер, процент, время показа, «следовать стилю бара», режим прилипания, свой фон / альфа / скругление.

Правки стокового `Osd.qml` помечены `// edge:`.

**Токены стиля.** `~/.config/omarchy/style.json` (пишет
[omarchy-customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) → Пресеты → Стиль) настраивает панели поверх
бара: `elevation` 0–2 (тени), `motion` (множитель скорости анимаций, 0 — без них), `material` (`auto` / `solid` /
`glass`), `cornerScale` (0 — прямые углы), `typeface` (`shell` — шрифт Omarchy, `profile` — sans из
`~/.config/omarchy/fonts.json`; иконки всегда в шрифте Omarchy). Нет файла — вид как раньше.

## Лицензия

MIT (вместе со стоковым плагином Omarchy, из которого сделан клон).
