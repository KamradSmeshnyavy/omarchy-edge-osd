# Omarchy Edge OSD

[🇬🇧 English](README.md)

OSD [Omarchy](https://omarchy.org) (клон стокового `omarchy.osd`): громкость, яркость и микрофон — вертикальный
слайдер, выезжающий из края экрана. Со сплошным баром у края — например, скином `frame` из
[omarchy-bar-skins](https://github.com/KamradSmeshnyavy/omarchy-bar-skins) — растёт прямо из рамки с вогнутыми
углами; иначе — плавающая карточка с отступом и тенью. Сообщения и медиа-OSD остаются стоковой карточкой.
Клики OSD не перехватывает.

![Громкость и яркость в стилях Стекло, Бумага и DOT-MATRIX](screenshots/styles.webp)

<!-- Demo video: repo-videos/omarchy-edge-osd.mp4 — drag it here when editing this file on GitHub -->

## Установка

```sh
omarchy plugin add https://github.com/KamradSmeshnyavy/omarchy-edge-osd --enable
omarchy restart shell
```

## Требования

Omarchy 4 (Quattro) с его оболочкой. Проверено на Omarchy 4.0.6 и Quickshell 0.3.2.

- Ничего, кроме Omarchy.
- Необязательно: [Customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) — его стили (Flat, Glass, Fluent, DOT-MATRIX) пишут `~/.config/omarchy/style.json`, плагин их подхватывает; без него — значения по умолчанию.
- Дизайны DOT-MATRIX используют шрифты из [Customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) (Doto, Space Grotesk, Space Mono); без них — шрифт Omarchy.

## Удаление

```sh
omarchy plugin enable omarchy.osd      # сначала вернуть стоковый
omarchy plugin remove kamradsmeshnyavy.osd
omarchy restart shell
```

Настройки остаются в `~/.config/omarchy/osd.json` — удалите их вручную, если не нужны.

## Настройки

`~/.config/omarchy/osd.json`, применяются на лету; [Customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) —
Окна → OSD. Ключи — в [README.md](README.md#settings): стиль (`edge` / `dotmatrix` / `stock`), край, положение вдоль края,
размер, процент, время показа, «следовать стилю бара», режим прилипания, свой фон / альфа / скругление.

Правки стокового `Osd.qml` помечены `// edge:`.

**Токены стиля.** `~/.config/omarchy/style.json` (пишет
[omarchy-customizer](https://github.com/KamradSmeshnyavy/omarchy-customizer) → Пресеты → Стиль) настраивает панели поверх
бара: `elevation` 0–2 (тени), `motion` (множитель скорости анимаций, 0 — без них), `material` (`auto` / `solid` /
`glass`), `cornerScale` (0 — прямые углы), `typeface` (`shell` — шрифт Omarchy, `profile` — sans из
`~/.config/omarchy/fonts.json`, `hand` — рукописный Caveat; иконки всегда в шрифте Omarchy). `material` `paper` / `soft` /
`brutal` / `bevel` / `glow` рисует плавающие панели через `StyleCard.qml`: лист бумаги (рваный край, тайл `texture`, скотч),
неоморфный рельеф, толстая рамка с жёсткой тенью, ретро-кант, неоновое свечение. Нет файла — вид как раньше.

## Лицензия

MIT (вместе со стоковым плагином Omarchy, из которого сделан клон).
