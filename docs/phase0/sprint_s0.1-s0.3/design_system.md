# Design System - Worktrace

**Phase:** S0.3 - Visual Identity & Design System
**Status:** Active

---

## 1. Brand Direction

Worktrace communicates **modularity, continuity, and traceability**.
The visual identity should feel like a practical developer tool - clean,
focused, and uncluttered - not a generic productivity dashboard.

**Brand asset:** `assets/images/WorkTrace.png`
**Status:** Owner-provided logo. Integrated with error fallback.

## 2. Color Tokens

All colors defined in `lib/app/theme/app_tokens.dart`.

### Brand

| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `#1A73E8` | Primary actions, active states, brand accent |
| `secondary` | `#00897B` | Supporting accent, snippet feature color |

### Light Theme

| Token | Value | Usage |
|-------|-------|-------|
| `lightBackground` | `#F8F9FA` | Scaffold background |
| `lightSurface` | `#FFFFFF` | Cards, surfaces |
| `lightOnSurface` | `#1F1F1F` | Primary text |
| `lightOnSurfaceVariant` | `#5F6368` | Secondary text, hints |
| `lightBorder` | `#DADCE0` | Dividers, card borders |

### Dark Theme

| Token | Value | Usage |
|-------|-------|-------|
| `darkBackground` | `#121212` | Scaffold background |
| `darkSurface` | `#1E1E1E` | Cards, surfaces |
| `darkOnSurface` | `#E8EAED` | Primary text |
| `darkOnSurfaceVariant` | `#9AA0A6` | Secondary text, hints |
| `darkBorder` | `#3C4043` | Dividers, card borders |

### Status

| Token | Value | Usage |
|-------|-------|-------|
| `success` | `#34A853` | Completed tasks, confirmations |
| `warning` | `#FBBC04` | Attention needed |
| `error` | `#EA4335` | Errors, destructive actions |

## 3. Typography

Defined in `AppTypography.textTheme`. Based on the default Material 3
type scale with adjusted weights.

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| `headlineLarge` | 28 | 700 | Screen titles (rare) |
| `headlineMedium` | 24 | 600 | Hero headings |
| `titleLarge` | 20 | 600 | App bar title |
| `titleMedium` | 16 | 500 | Section headings, card titles |
| `bodyLarge` | 16 | 400 | Primary body text |
| `bodyMedium` | 14 | 400 | Secondary body, descriptions |
| `labelLarge` | 14 | 500 | Button labels |
| `labelSmall` | 11 | 500 | Chips, captions, version |

## 4. Spacing

Defined in `AppSpacing`. Use these constants instead of magic numbers.

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4 | Tight gaps, icon-to-text |
| `sm` | 8 | Related element spacing |
| `md` | 12 | Card internal padding |
| `lg` | 16 | Standard padding, section gaps |
| `xl` | 24 | Section separation |
| `xxl` | 32 | Major section breaks |

## 5. Shapes

Defined in `AppShapes`.

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSm` | 8 | Buttons, chips |
| `radiusMd` | 12 | Cards, surfaces |
| `radiusLg` | 16 | Dialogs, bottom sheets |
| `radiusFull` | 999 | Avatars, pills |

## 6. Theme Behavior

- **Mode:** `ThemeMode.system` - follows device preference.
- **No manual toggle** in V1.
- Both themes use the same `ColorScheme.fromSeed()` with `AppColors.primary`.
- Cards use zero elevation with border outlines (not shadows).
- AppBar is flat with subtle scroll elevation.

## 7. Reusable Components

Located in `lib/shared/widgets/wt_primitives.dart`.

| Component | Purpose |
|-----------|---------|
| `WtPrimaryButton` | Branded CTA button with optional icon |
| `WtCard` | Consistent padded surface card |
| `WtEmptyState` | Empty screen with icon, title, and message |

**Rule:** Only add components when a current screen needs them.
Do not pre-build a library for hypothetical screens.

## 8. How Features Should Consume the Design System

```dart
// ✅ Do: use theme tokens
final theme = Theme.of(context);
Text('Hello', style: theme.textTheme.titleMedium);

// ❌ Don't: hard-code values
Text('Hello', style: TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)));
```

- Reference Theme.of(context) for colors and text styles.
- Reference AppSpacing and AppShapes for layout values.
- Use WtCard, WtPrimaryButton, WtEmptyState where appropriate.
- Request new tokens or components through the design system doc,
- not by inventing local styles.

## 9. Known Limitations

- Logo is owner-provided; no alternate sizes or icon-only variant yet.
- No custom font - uses platform default (Roboto on Android).
- No animation or motion tokens defined yet.
- Accessibility audit limited to contrast and touch targets;
- full audit deferred to feature sprints.
- Update this document when tokens, components, or brand assets change.
