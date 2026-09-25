# Dissecção do Dashboard HTML → Flutter

## 1. Visão Geral da Estrutura

O HTML é um **SPA (Single Page Application) estático** com Tailwind CSS via CDN. A estrutura macro é:

```
<body>
  <aside>          ← Sidebar fixa (w-72 = 288px)
  <div class="pl-72">
    <header>       ← Topbar fixa (h-20)
    <main>
      ├─ Welcome Banner
      ├─ Stats Cards (4-grid)
      ├─ Left Col (8/12)
      │   ├─ ~~Gráfico SVG~~ ← REMOVIDO
      │   ├─ Category Breakdown
      │   └─ RSVP Table
      └─ Right Col (4/12)
          ├─ Presentes Recentes
          ├─ Atividades Recentes
          └─ Atalhos de Configuração (Toggles)
```

---

## 2. Paleta de Cores (Design Tokens)

O HTML define um tema **Material You / Warm Neutral** via `tailwind.config`. A conversão direta para Flutter usa `ColorScheme` personalizado:

| Token HTML | Hex | Uso | Flutter equivalente |
|---|---|---|---|
| `primary` | `#6d5b4c` | Botões, ícones ativos | `ColorScheme.primary` |
| `secondary` | `#735c00` | Badges dourados, barras | `ColorScheme.secondary` |
| `background` / `surface` | `#fbf9f8` | Fundo geral | `ColorScheme.surface` |
| `surface-container-lowest` | `#ffffff` | Cards | `ColorScheme.surfaceContainerLowest` |
| `surface-container-low` | `#f6f3f2` | Sidebar, fundos suaves | `ColorScheme.surfaceContainerLow` |
| `surface-container` | `#f0eded` | Inputs, chips | `ColorScheme.surfaceContainer` |
| `surface-container-high` | `#eae8e7` | Hover states | `ColorScheme.surfaceContainerHigh` |
| `on-surface` | `#1b1c1c` | Texto principal | `ColorScheme.onSurface` |
| `on-surface-variant` | `#4e453f` | Texto secundário | `ColorScheme.onSurfaceVariant` |
| `outline` | `#80756e` | Labels, bordas | `ColorScheme.outline` |
| `outline-variant` | `#d1c4bb` | Divisores | `ColorScheme.outlineVariant` |
| `primary-container` | `#b8a291` | Fundo nav ativo | `ColorScheme.primaryContainer` |
| `secondary-container` | `#fed65b` | Amarelo / dourado claro | `ColorScheme.secondaryContainer` |
| `secondary-fixed` | `#ffe088` | Badges amarelos | `ColorScheme.secondaryFixed` |
| `error` | `#ba1a1a` | Status recusado | `ColorScheme.error` |
| `error-container` | `#ffdad6` | Chip de recusa | `ColorScheme.errorContainer` |

---

## 3. Tipografia

O HTML usa 4 fontes do Google Fonts com papéis distintos:

| Fonte | Papel | Uso no HTML | Flutter (google_fonts) |
|---|---|---|---|
| **Playfair Display** | `headline-lg` | H1 principal (48px, bold) | `GoogleFonts.playfairDisplay` |
| **Bodoni Moda** | `section-title` | Títulos de seção (36px, weight 400) | `GoogleFonts.bodoniModa` |
| **Work Sans** | `body-md` | Corpo de texto (16px) | `GoogleFonts.workSans` |
| **Plus Jakarta Sans** | `label-caps` | Rótulos uppercase (12px, tracked) | `GoogleFonts.plusJakartaSans` |

> **Diferença Flutter:** O Flutter não suporta `letter-spacing` em `em`; usa `sp` (`letterSpacing` em pixels lógicos). `0.15em` em 12px = ~1.8px, `0.02em` em 48px = ~1.0px.

---

## 4. Componentes e Mapeamento Flutter

### 4.1 Sidebar (`<aside>`)
| HTML | Flutter |
|---|---|
| `fixed left-0 w-72 h-full` | `SizedBox(width: 288)` dentro de `Row` |
| `shadow-[0_1px_8px_...]` | `BoxDecoration(boxShadow: [...])` |
| `<nav>` com itens `<a>` | `ListView` com `_NavItem` widgets |
| `aria-current="page"` + classes ativas | `bool isActive` + `AnimatedContainer` |
| Seção inferior com data + logout | `Column(mainAxisAlignment: end)` |

### 4.2 Header (`<header>`)
| HTML | Flutter |
|---|---|
| `fixed top-0 h-20 backdrop-blur-xl` | `PreferredSizeWidget` custom ou `SliverAppBar` — no shell: `Container` fixo + `ImageFilter.blur` |
| Breadcrumb texto | `Row` com `Text` separados |
| Badge "Faltam X dias" | `Container` com `BorderRadius` + `Row(Icon + Text)` |
| Botão notificação + badge ponto | `Stack(IconButton + Positioned dot)` |
| Avatar | `CircleAvatar` |

### 4.3 Welcome Banner
| HTML | Flutter |
|---|---|
| `absolute blur-3xl rounded-full` (ambient blobs) | `Positioned` + `BackdropFilter` ou `Container(decoration: BoxDecoration(shape: circle, color: ...withOpacity))` |
| `xl:flex-row` (breakpoint) | `LayoutBuilder` → `flex-row` quando `constraints.maxWidth > 900` |
| Botões de ação rápida | `OutlinedButton` e `FilledButton` |

### 4.4 Stat Cards (4-grid)
| HTML | Flutter |
|---|---|
| `grid grid-cols-4 gap-6` | `Wrap` ou `GridView.count` com `crossAxisCount` responsivo |
| Ícone + badge no topo | `Row(mainAxisAlignment: spaceBetween)` |
| Progress bar `h-1.5` | `ClipRRect + LinearProgressIndicator` ou `Container` manual |
| Hover `shadow-md` | `MouseRegion` + `AnimatedContainer` |

### 4.5 Category Breakdown (mantido, sem gráfico)
| HTML | Flutter |
|---|---|
| Grid de 3 colunas | `Row` com `Expanded` filhos |
| Barra de progresso colorida | `LinearProgressIndicator` com `color` e `backgroundColor` |
| Label + percentual | `Row(mainAxisAlignment: spaceBetween)` |

### 4.6 Tabela RSVP
| HTML | Flutter |
|---|---|
| `<table>` com `<thead>/<tbody>` | `DataTable` ou tabela custom com `Column + Row` |
| Avatar iniciais | `CircleAvatar(child: Text('MS'))` |
| Badge de categoria | `Chip` ou `Container` decorado |
| Status pill (confirmado/recusado) | `Container(decoration: BoxDecoration(borderRadius: ..., color: ...))` |
| Botões de ação ícone | `IconButton` |
| `hover:bg-surface-container-low` | `DataRow(color: MaterialStateProperty.resolveWith(...))` |

### 4.7 Presentes Recentes
| HTML | Flutter |
|---|---|
| `<img>` 48×48 rounded | `ClipRRect(borderRadius: 8, child: Image.network(...))` |
| Status badge "Enviado/Pendente" | `Container` com cor condicional |
| Item hover | `InkWell` ou `ListTile` customizado |

### 4.8 Toggle Switches
| HTML | Flutter |
|---|---|
| `<input type="checkbox" class="sr-only peer">` + div customizado | `Switch` (Material 3 nativo) |
| `peer-checked:bg-secondary` | `Switch(activeColor: secondary, ...)` |

---

## 5. Principais Diferenças de Construção

| Aspecto | HTML/Tailwind | Flutter |
|---|---|---|
| **Layout responsivo** | Classes breakpoint (`xl:`, `lg:`, `md:`) | `LayoutBuilder` + `MediaQuery` |
| **Posicionamento fixo** | `fixed` CSS | `Stack` com `Positioned` ou estrutura com `Column(AppBar + Expanded(Row))` |
| **Hover states** | `:hover` pseudo-class | `MouseRegion` + `setState` ou `InkWell` |
| **Fontes variáveis** | `font-weight: 100..900` range | `GoogleFonts.xxx(fontWeight: FontWeight.w600)` |
| **Sombras** | `shadow-sm`, `shadow-[custom]` | `BoxShadow(blurRadius, offset, color)` |
| **Blur decorativo** | `blur-3xl` + `opacity` | `BackdropFilter(ImageFilter.blur)` ou apenas `Color.withOpacity` |
| **Transições** | `transition-all duration-200` | `AnimatedContainer`, `AnimatedOpacity` |
| **Scroll** | `::-webkit-scrollbar {display:none}` | `ScrollbarTheme(thumbVisibility: false)` |
| **Z-index** | `z-50`, `z-40` | Ordem natural no widget tree + `Stack` |
| **Tabela** | `<table>` nativo HTML | `DataTable` do Material 3 ou custom |

---

## 6. O que foi REMOVIDO (conforme solicitado)

A seção de gráficos SVG que foi **removida** compreendia:

```html
<!-- Inline Visual Chart (SVG Area & Bar Combo) -->
<div class="w-full h-56 pt-2 pb-4">
  <svg viewbox="0 0 680 180">
    <defs>...</defs>           ← Gradiente da área
    <!-- Grid lines -->         ← 3 linhas horizontais tracejadas
    <!-- Bar columns -->        ← 6 retângulos (barras de arrecadação)
    <!-- RSVP Curve Line -->    ← Path SVG bezier suavizado
    <!-- Area fill -->          ← Polígono preenchido com gradiente
    <!-- Node points -->        ← 6 círculos nos pontos de dados
    <!-- Month labels -->       ← Textos MAI/JUN/JUL/AGO/SET/OUT
  </svg>
</div>
```

Em Flutter, esse SVG exigiria o package `fl_chart` ou `syncfusion_flutter_charts`. Como a decisão foi remover essa seção, o espaço é ocupado diretamente pelo **Category Breakdown** sem gap visual.

---

## 7. Estrutura de Arquivos Flutter Criados

```
lib/features/admin/presentation/
├── admin_page.dart              ← Atualizado: usa AdminShell
├── admin_image_picker_io.dart   ← Inalterado
├── admin_image_picker_web.dart  ← Inalterado
├── widgets/
│   └── admin_shell.dart         ← NOVO: sidebar + header + conteúdo
└── pages/
    └── admin_dashboard_page.dart ← NOVO: dashboard sem gráficos
```
HTML usado de exemplo: 
<!DOCTYPE html>

<html lang="pt-BR"><head><meta charset="utf-8"/><meta content="width=device-width, initial-scale=1.0" name="viewport"/><meta content="web_dashboard" name="shell-type"/><link href="https://fonts.googleapis.com/css2?family=Bodoni+Moda:ital,opsz,wght@0,6..96,400..900;1,6..96,400..900&amp;family=Playfair+Display:ital,wght@0,400..900;1,400..900&amp;family=Plus+Jakarta+Sans:wght@300;400;500;600;700&amp;family=Work+Sans:wght@300;400;500;600&amp;display=swap" rel="stylesheet"/><link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/><style>@layer base{html,body{margin:0;padding:0;}body{overscroll-behavior:none;}main>:first-child{margin-top:0!important;}main>:last-child{margin-bottom:0!important;}}::-webkit-scrollbar{display:none;}</style><script src="https://cdn.tailwindcss.com"></script><script id="tailwind-config">tailwind.config={darkMode:"class",theme:{extend:{colors:{"tertiary-container":"#a8a6a3","primary-container":"#b8a291","on-surface":"#1b1c1c","surface-container-high":"#eae8e7","on-tertiary-fixed":"#1c1c1a","surface-variant":"#e4e2e1","surface-container-highest":"#e4e2e1","on-secondary-fixed-variant":"#574500","error":"#ba1a1a","outline-variant":"#d1c4bb","on-primary":"#ffffff","secondary-container":"#fed65b","on-background":"#1b1c1c","surface-dim":"#dcd9d9","secondary-fixed":"#ffe088","on-surface-variant":"#4e453f","surface-container":"#f0eded","on-secondary-container":"#745c00","secondary":"#735c00","background":"#fbf9f8","surface":"#fbf9f8","inverse-primary":"#dac2b0","inverse-on-surface":"#f3f0f0","on-tertiary-container":"#3c3c39","on-primary-container":"#48392c","inverse-surface":"#303030","primary-fixed":"#f7decb","on-error":"#ffffff","on-primary-fixed-variant":"#544436","on-secondary-fixed":"#241a00","surface-container-low":"#f6f3f2","surface-container-lowest":"#ffffff","primary-fixed-dim":"#dac2b0","on-error-container":"#93000a","tertiary-fixed-dim":"#c8c6c2","on-primary-fixed":"#26190e","primary":"#6d5b4c","surface-bright":"#fbf9f8","surface-tint":"#6d5b4c","on-secondary":"#ffffff","tertiary-fixed":"#e5e2de","outline":"#80756e","on-tertiary":"#ffffff","error-container":"#ffdad6","secondary-fixed-dim":"#e9c349","on-tertiary-fixed-variant":"#474744","tertiary":"#5f5e5b"},borderRadius:{"DEFAULT":"0.125rem","lg":"0.25rem","xl":"0.5rem","full":"0.75rem"},spacing:{"gutter":"24px","section-padding":"80px","unit-base":"8px","container-max":"1200px","margin-mobile":"20px"},fontFamily:{"headline-lg":["Playfair Display"],"body-md":["Work Sans"],"label-caps":["Plus Jakarta Sans"],"headline-lg-mobile":["Playfair Display"],"section-title":["Bodoni Moda"]},fontSize:{"headline-lg":["48px",{lineHeight:"56px",letterSpacing:"-0.02em",fontWeight:"700"}],"body-md":["16px",{lineHeight:"28px",fontWeight:"400"}],"label-caps":["12px",{lineHeight:"16px",letterSpacing:"0.15em",fontWeight:"600"}],"headline-lg-mobile":["32px",{lineHeight:"40px",fontWeight:"700"}],"section-title":["36px",{lineHeight:"44px",fontWeight:"400"}]}}}}</script></head><body class="bg-surface font-body-md text-on-surface antialiased"><aside class="fixed left-0 top-0 h-full w-72 bg-surface-container-low z-50 flex flex-col justify-between shadow-[0_1px_8px_rgba(0,0,0,0.04)]"><div class="flex flex-col"><div class="h-20 px-8 flex flex-col justify-center bg-surface-container-low"><div class="flex items-center gap-2"><span class="material-symbols-outlined text-primary text-[22px]">favorite</span><span class="font-section-title text-section-title text-on-surface tracking-wide">Kleyon &amp; Liandra</span></div><span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-widest mt-1">Cerimonial Privé</span></div><div class="px-8 py-3"><div class="h-[1px] w-full bg-outline-variant/30"></div></div><div class="px-6 py-2"><span class="font-label-caps text-label-caps text-outline uppercase tracking-widest px-2">Menu Principal</span></div><nav class="flex flex-col gap-1 px-4" data-active-classes="bg-primary-container text-on-primary-container font-medium rounded-lg shadow-sm"><a aria-current="page" class="flex items-center gap-3.5 px-4 py-3 transition-all duration-200 bg-primary-container text-on-primary-container font-medium rounded-lg shadow-sm" data-path="dashboard" href="#"><span class="material-symbols-outlined text-[20px]">grid_view</span><span class="font-body-md text-body-md">Dashboard</span></a><a class="flex items-center gap-3.5 px-4 py-3 rounded-lg text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-all duration-200" data-path="produtos" href="#"><span class="material-symbols-outlined text-[20px]">featured_seasonal_and_gifts</span><span class="font-body-md text-body-md">Produtos</span></a><a class="flex items-center gap-3.5 px-4 py-3 rounded-lg text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-all duration-200" data-path="pagamentos" href="#"><span class="material-symbols-outlined text-[20px]">payments</span><span class="font-body-md text-body-md">Pagamentos</span></a><a class="flex items-center gap-3.5 px-4 py-3 rounded-lg text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-all duration-200" data-path="presenca" href="#"><span class="material-symbols-outlined text-[20px]">how_to_reg</span><span class="font-body-md text-body-md">Presença</span></a><a class="flex items-center gap-3.5 px-4 py-3 rounded-lg text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-all duration-200" data-path="logs" href="#"><span class="material-symbols-outlined text-[20px]">history</span><span class="font-body-md text-body-md">Logs</span></a><a class="flex items-center gap-3.5 px-4 py-3 rounded-lg text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-all duration-200" data-path="configuracoes" href="#"><span class="material-symbols-outlined text-[20px]">settings</span><span class="font-body-md text-body-md">Configurações</span></a><a class="flex items-center gap-3.5 px-4 py-3 rounded-lg text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-all duration-200" data-path="seguranca" href="#"><span class="material-symbols-outlined text-[20px]">shield</span><span class="font-body-md text-body-md">Segurança</span></a></nav></div><div class="p-6 flex flex-col gap-4"><div class="bg-surface-container-highest/60 rounded-xl p-4 flex items-center justify-between"><div class="flex flex-col"><span class="font-label-caps text-label-caps text-on-surface-variant">Data do Evento</span><span class="font-body-md text-body-md font-medium text-on-surface">14 Outubro 2025</span></div><span class="material-symbols-outlined text-secondary text-[22px]">event</span></div><a class="flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg bg-surface-container text-on-surface-variant hover:text-error hover:bg-surface-container-high transition-colors" href="#"><span class="material-symbols-outlined text-[18px]">logout</span><span class="font-label-caps text-label-caps uppercase">Encerrar Sessão</span></a></div></aside><div class="pl-72"><header class="fixed top-0 left-72 right-0 h-20 bg-surface/80 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.04)] z-40 px-8 flex items-center justify-between"><div class="flex items-center gap-4"><span class="font-label-caps text-label-caps text-on-surface-variant uppercase tracking-wider">Painel Administrativo</span><span class="text-outline-variant font-light">/</span><span class="font-body-md text-body-md text-on-surface font-medium">Kleyon &amp; Liandra</span><div class="hidden md:flex items-center gap-1.5 ml-4 px-3 py-1 bg-secondary-fixed/50 rounded-full"><span class="material-symbols-outlined text-secondary text-[16px]">schedule</span><span class="font-label-caps text-label-caps text-on-secondary-fixed font-semibold">Faltam 184 dias</span></div></div><div class="flex items-center gap-4"><button class="w-10 h-10 rounded-full flex items-center justify-center bg-surface-container text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high transition-colors relative" type="button"><span class="material-symbols-outlined text-[20px]">notifications</span><span class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full bg-secondary"></span></button><button class="w-10 h-10 rounded-full flex items-center justify-center bg-surface-container text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high transition-colors" type="button"><span class="material-symbols-outlined text-[20px]">tune</span></button><div class="h-8 w-[1px] bg-outline-variant/30 mx-1"></div><div class="flex items-center gap-3 pl-1"><div class="flex flex-col text-right hidden sm:flex"><span class="font-body-md text-body-md font-medium text-on-surface leading-snug">Liandra &amp; Kleyon</span><span class="font-label-caps text-label-caps text-outline uppercase tracking-wider">Casal • Gestores</span></div><div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center"><span class="material-symbols-outlined text-on-primary text-[18px]">person</span></div></div></div></header><main class="w-full pt-20 px-8 bg-surface min-h-screen"><div class="flex flex-col w-full pb-16 space-y-10">
<!-- Editorial Welcome Banner with Ambient Warmth -->
<div class="relative overflow-hidden rounded-xl bg-surface-container-low p-8 lg:p-10 shadow-sm">
<div class="absolute -right-20 -top-24 w-96 h-96 bg-primary-container/20 rounded-full blur-3xl pointer-events-none"></div>
<div class="absolute right-40 -bottom-20 w-80 h-80 bg-secondary-container/15 rounded-full blur-2xl pointer-events-none"></div>
<div class="relative z-10 flex flex-col xl:flex-row xl:items-end justify-between gap-8">
<div class="max-w-2xl">
<div class="flex items-center gap-3 mb-3">
<span class="inline-flex items-center justify-center w-6 h-6 rounded-full bg-secondary text-on-secondary">
<span class="material-symbols-outlined text-[14px]">auto_awesome</span>
</span>
<span class="font-label-caps text-label-caps uppercase text-secondary font-semibold tracking-widest">Painel Nupcial Exclusivo</span>
</div>
<h1 class="font-headline-lg text-headline-lg text-on-surface tracking-tight leading-none mb-3">
          Bem-vindo de volta, <span class="italic font-normal text-primary">Kleyon &amp; Liandra</span>
</h1>
<p class="font-body-md text-body-md text-on-surface-variant flex items-center gap-2">
<span>Visão geral da organização e métricas do seu casamento</span>
<span class="w-1.5 h-1.5 rounded-full bg-outline-variant inline-block"></span>
<span class="text-primary font-medium">Faltam 122 dias para 26.12.2026</span>
</p>
</div>
<!-- Quick Action Group -->
<div class="flex flex-wrap items-center gap-3">
<a class="inline-flex items-center gap-2 px-5 py-3 rounded-lg bg-surface-container-highest text-on-surface hover:bg-surface-variant transition-all duration-200 shadow-sm" href="#site">
<span class="material-symbols-outlined text-[18px] text-primary">open_in_new</span>
<span class="font-label-caps text-label-caps uppercase text-on-surface">Ver Site ao Vivo</span>
</a>
<button class="inline-flex items-center gap-2 px-5 py-3 rounded-lg bg-surface-container-highest text-on-surface hover:bg-surface-variant transition-all duration-200 shadow-sm" type="button">
<span class="material-symbols-outlined text-[18px] text-secondary">file_download</span>
<span class="font-label-caps text-label-caps uppercase text-on-surface">Exportar RSVP</span>
</button>
<button class="inline-flex items-center gap-2 px-6 py-3 rounded-lg bg-primary text-on-primary hover:bg-on-primary-container transition-all duration-200 shadow-md hover:shadow-lg" type="button">
<span class="material-symbols-outlined text-[20px]">add</span>
<span class="font-label-caps text-label-caps uppercase text-on-primary tracking-wider">+ Novo Presente</span>
</button>
</div>
</div>
</div>
<!-- Luxury Top Stat Cards (4-Grid Bento) -->
<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
<!-- Card 1: Presença -->
<div class="relative overflow-hidden rounded-xl bg-surface-container-lowest p-6 shadow-sm hover:shadow-md transition-all duration-300">
<div class="flex items-start justify-between mb-4">
<div class="w-12 h-12 rounded-lg bg-surface-container-low flex items-center justify-center text-primary">
<span class="material-symbols-outlined text-[26px]">how_to_reg</span>
</div>
<span class="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-secondary-fixed/50 text-on-secondary-fixed font-label-caps text-label-caps font-semibold">
<span class="material-symbols-outlined text-[14px]">trending_up</span> +12 esta semana
        </span>
</div>
<span class="font-label-caps text-label-caps text-outline uppercase tracking-wider block mb-1">Presença Confirmada</span>
<div class="flex items-baseline gap-2 mb-3">
<span class="font-headline-lg text-headline-lg text-on-surface font-semibold leading-tight">184</span>
<span class="font-body-md text-body-md text-on-surface-variant">/ 220 convidados</span>
</div>
<!-- Progress Bar -->
<div class="w-full bg-surface-container rounded-full h-1.5 overflow-hidden">
<div class="bg-primary h-1.5 rounded-full transition-all duration-500" style="width: 83.6%"></div>
</div>
<div class="flex justify-between items-center mt-2">
<span class="font-label-caps text-label-caps text-outline">Meta de quórum</span>
<span class="font-label-caps text-label-caps text-primary font-bold">83.6%</span>
</div>
</div>
<!-- Card 2: Presentes Arrecadados -->
<div class="relative overflow-hidden rounded-xl bg-surface-container-lowest p-6 shadow-sm hover:shadow-md transition-all duration-300">
<div class="flex items-start justify-between mb-4">
<div class="w-12 h-12 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary">
<span class="material-symbols-outlined text-[26px]">savings</span>
</div>
<span class="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-primary-fixed/60 text-on-primary-fixed-variant font-label-caps text-label-caps font-semibold">
<span class="material-symbols-outlined text-[14px]">north_east</span> +R$ 3.200 ontem
        </span>
</div>
<span class="font-label-caps text-label-caps text-outline uppercase tracking-wider block mb-1">Presentes Arrecadados</span>
<div class="flex items-baseline gap-2 mb-3">
<span class="font-headline-lg text-headline-lg text-on-surface font-semibold leading-tight">R$ 42.850</span>
</div>
<!-- Progress Bar -->
<div class="w-full bg-surface-container rounded-full h-1.5 overflow-hidden">
<div class="bg-secondary h-1.5 rounded-full transition-all duration-500" style="width: 71.4%"></div>
</div>
<div class="flex justify-between items-center mt-2">
<span class="font-label-caps text-label-caps text-outline">Alvo: R$ 60.000,00</span>
<span class="font-label-caps text-label-caps text-secondary font-bold">71.4%</span>
</div>
</div>
<!-- Card 3: Itens Resgatados -->
<div class="relative overflow-hidden rounded-xl bg-surface-container-lowest p-6 shadow-sm hover:shadow-md transition-all duration-300">
<div class="flex items-start justify-between mb-4">
<div class="w-12 h-12 rounded-lg bg-surface-container-low flex items-center justify-center text-primary">
<span class="material-symbols-outlined text-[26px]">redeem</span>
</div>
<span class="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-surface-container-high text-on-surface-variant font-label-caps text-label-caps font-medium">
          59.3% ativo
        </span>
</div>
<span class="font-label-caps text-label-caps text-outline uppercase tracking-wider block mb-1">Itens Adquiridos</span>
<div class="flex items-baseline gap-2 mb-3">
<span class="font-headline-lg text-headline-lg text-on-surface font-semibold leading-tight">38</span>
<span class="font-body-md text-body-md text-on-surface-variant">/ 64 itens no catálogo</span>
</div>
<div class="w-full bg-surface-container rounded-full h-1.5 overflow-hidden">
<div class="bg-primary-container h-1.5 rounded-full transition-all duration-500" style="width: 59.3%"></div>
</div>
<div class="flex justify-between items-center mt-2">
<span class="font-label-caps text-label-caps text-outline">Disponíveis</span>
<span class="font-label-caps text-label-caps text-on-surface-variant font-semibold">26 cotas restantes</span>
</div>
</div>
<!-- Card 4: Mensagens de Recados -->
<div class="relative overflow-hidden rounded-xl bg-surface-container-lowest p-6 shadow-sm hover:shadow-md transition-all duration-300">
<div class="flex items-start justify-between mb-4">
<div class="w-12 h-12 rounded-lg bg-surface-container-low flex items-center justify-center text-secondary">
<span class="material-symbols-outlined text-[26px]">mark_chat_read</span>
</div>
<span class="inline-flex items-center gap-1 px-2.5 py-1 rounded bg-secondary-fixed/50 text-on-secondary-fixed font-label-caps text-label-caps font-semibold">
          4 novas hoje
        </span>
</div>
<span class="font-label-caps text-label-caps text-outline uppercase tracking-wider block mb-1">Mural do Casal</span>
<div class="flex items-baseline gap-2 mb-3">
<span class="font-headline-lg text-headline-lg text-on-surface font-semibold leading-tight">56</span>
<span class="font-body-md text-body-md text-on-surface-variant">mensagens afetuosas</span>
</div>
<div class="w-full bg-surface-container rounded-full h-1.5 overflow-hidden">
<div class="bg-secondary-container h-1.5 rounded-full transition-all duration-500" style="width: 90%"></div>
</div>
<div class="flex justify-between items-center mt-2">
<span class="font-label-caps text-label-caps text-outline">Aprovação pendente</span>
<span class="font-label-caps text-label-caps text-secondary font-bold">2 para revisar</span>
</div>
</div>
</div>
<!-- Two-Column Core Layout (65% / 35%) -->
<div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
<!-- Left Column (65% -> 8 columns on 12-grid) -->
<div class="lg:col-span-8 flex flex-col space-y-8">
<!-- Visual Analytics & Category Breakdown -->
<div class="bg-surface-container-lowest rounded-xl p-8 shadow-sm">
<div class="flex flex-col sm:flex-row sm:items-center justify-between pb-6 gap-4">
<div>
<span class="font-label-caps text-label-caps uppercase text-outline tracking-widest block mb-1">Métricas &amp; Desempenho</span>
<h2 class="font-section-title text-section-title text-on-surface">Fluxo de Confirmações &amp; Arrecadação</h2>
</div>
<div class="inline-flex rounded-lg bg-surface-container p-1 text-on-surface-variant">
<button class="px-3 py-1 text-label-caps font-label-caps rounded-md bg-surface-container-lowest text-on-surface shadow-xs" type="button">Últimos 6 Meses</button>
<button class="px-3 py-1 text-label-caps font-label-caps text-outline hover:text-on-surface transition-colors" type="button">Semanal</button>
</div>
</div>
<!-- Inline Visual Chart (SVG SVG Line / Area & Bar Combo) -->
<div class="w-full h-56 pt-2 pb-4">
<svg class="w-full h-full overflow-visible" fill="none" viewbox="0 0 680 180" xmlns="http://www.w3.org/2000/svg">
<defs>
<lineargradient id="primaryAreaGrad" x1="0" x2="0" y1="0" y2="1">
<stop offset="0%" stop-color="#b8a291" stop-opacity="0.35"></stop>
<stop offset="100%" stop-color="#b8a291" stop-opacity="0.0"></stop>
</lineargradient>
</defs>
<!-- Grid Guides -->
<line stroke="#f0eded" stroke-dasharray="4 4" stroke-width="1.5" x1="0" x2="680" y1="30" y2="30"></line>
<line stroke="#f0eded" stroke-dasharray="4 4" stroke-width="1.5" x1="0" x2="680" y1="80" y2="80"></line>
<line stroke="#f0eded" stroke-dasharray="4 4" stroke-width="1.5" x1="0" x2="680" y1="130" y2="130"></line>
<!-- Bar Columns (Arrecadação R$ em milhares) -->
<rect fill="#eae8e7" height="35" rx="3" width="22" x="55" y="115"></rect>
<rect fill="#eae8e7" height="55" rx="3" width="22" x="165" y="95"></rect>
<rect fill="#eae8e7" height="80" rx="3" width="22" x="275" y="70"></rect>
<rect fill="#eae8e7" height="102" rx="3" width="22" x="385" y="48"></rect>
<rect fill="#dac2b0" height="118" rx="3" width="22" x="495" y="32"></rect>
<rect fill="#735c00" height="132" opacity="0.85" rx="3" width="22" x="605" y="18"></rect>
<!-- RSVP Smooth Curve Line -->
<path d="M 66 128 C 120 120, 150 102, 176 96 C 220 86, 260 74, 286 64 C 330 48, 370 42, 396 36 C 440 28, 480 25, 506 20 C 550 14, 590 12, 616 10" stroke="#6d5b4c" stroke-linecap="round" stroke-width="2.5"></path>
<path d="M 66 128 C 120 120, 150 102, 176 96 C 220 86, 260 74, 286 64 C 330 48, 370 42, 396 36 C 440 28, 480 25, 506 20 C 550 14, 590 12, 616 10 L 616 150 L 66 150 Z" fill="url(#primaryAreaGrad)"></path>
<!-- Node Points -->
<circle cx="66" cy="128" fill="#fbf9f8" r="4.5" stroke="#6d5b4c" stroke-width="2.5"></circle>
<circle cx="176" cy="96" fill="#fbf9f8" r="4.5" stroke="#6d5b4c" stroke-width="2.5"></circle>
<circle cx="286" cy="64" fill="#fbf9f8" r="4.5" stroke="#6d5b4c" stroke-width="2.5"></circle>
<circle cx="396" cy="36" fill="#fbf9f8" r="4.5" stroke="#6d5b4c" stroke-width="2.5"></circle>
<circle cx="506" cy="20" fill="#fbf9f8" r="4.5" stroke="#6d5b4c" stroke-width="2.5"></circle>
<circle cx="616" cy="10" fill="#735c00" r="5" stroke="#fbf9f8" stroke-width="2"></circle>
<!-- Month Labels -->
<text fill="#80756e" font-family="'Work Sans', sans-serif" font-size="11" text-anchor="middle" x="66" y="170">MAI</text>
<text fill="#80756e" font-family="'Work Sans', sans-serif" font-size="11" text-anchor="middle" x="176" y="170">JUN</text>
<text fill="#80756e" font-family="'Work Sans', sans-serif" font-size="11" text-anchor="middle" x="286" y="170">JUL</text>
<text fill="#80756e" font-family="'Work Sans', sans-serif" font-size="11" text-anchor="middle" x="396" y="170">AGO</text>
<text fill="#80756e" font-family="'Work Sans', sans-serif" font-size="11" text-anchor="middle" x="506" y="170">SET</text>
<text fill="#1b1c1c" font-family="'Work Sans', sans-serif" font-size="11" font-weight="600" text-anchor="middle" x="616" y="170">OUT (Atual)</text>
</svg>
</div>
<!-- Category Progress Breakdown -->
<div class="mt-8 pt-6 grid grid-cols-1 md:grid-cols-3 gap-6 bg-surface-container-low/60 p-5 rounded-lg">
<div>
<div class="flex justify-between items-center mb-1.5">
<span class="font-body-md text-body-md text-on-surface font-medium">Padrinhos &amp; Madrinhas</span>
<span class="font-label-caps text-label-caps text-secondary font-bold">100%</span>
</div>
<div class="w-full bg-surface-container-high rounded-full h-2">
<div class="bg-secondary h-2 rounded-full" style="width: 100%"></div>
</div>
<span class="font-label-caps text-label-caps text-outline mt-1 block">24 de 24 convidados</span>
</div>
<div>
<div class="flex justify-between items-center mb-1.5">
<span class="font-body-md text-body-md text-on-surface font-medium">Familiares Diretos</span>
<span class="font-label-caps text-label-caps text-primary font-bold">92%</span>
</div>
<div class="w-full bg-surface-container-high rounded-full h-2">
<div class="bg-primary h-2 rounded-full" style="width: 92%"></div>
</div>
<span class="font-label-caps text-label-caps text-outline mt-1 block">68 de 74 convidados</span>
</div>
<div>
<div class="flex justify-between items-center mb-1.5">
<span class="font-body-md text-body-md text-on-surface font-medium">Amigos &amp; Colegas</span>
<span class="font-label-caps text-label-caps text-on-surface-variant font-bold">76%</span>
</div>
<div class="w-full bg-surface-container-high rounded-full h-2">
<div class="bg-primary-container h-2 rounded-full" style="width: 76%"></div>
</div>
<span class="font-label-caps text-label-caps text-outline mt-1 block">92 de 122 convidados</span>
</div>
</div>
</div>
<!-- Recent RSVP Table Card -->
<div class="bg-surface-container-lowest rounded-xl p-8 shadow-sm">
<div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
<div>
<span class="font-label-caps text-label-caps uppercase text-outline tracking-widest block mb-1">Mesa de Controle</span>
<h2 class="font-section-title text-section-title text-on-surface">Últimas Confirmações de Presença</h2>
</div>
<div class="flex items-center gap-2">
<span class="font-label-caps text-label-caps text-outline">Total listado: 5 recentes</span>
<a class="px-3 py-1.5 rounded-lg bg-surface-container text-on-surface hover:bg-surface-container-high font-label-caps text-label-caps transition-colors" href="#">Ver Todos</a>
</div>
</div>
<div class="overflow-x-auto -mx-8 px-8">
<table class="w-full text-left">
<thead>
<tr class="bg-surface-container-low text-outline font-label-caps text-label-caps uppercase">
<th class="py-3 px-4 rounded-l-md font-semibold tracking-wider">Convidado</th>
<th class="py-3 px-4 font-semibold tracking-wider">Categoria</th>
<th class="py-3 px-4 font-semibold tracking-wider text-center">Adultos</th>
<th class="py-3 px-4 font-semibold tracking-wider text-center">Crianças</th>
<th class="py-3 px-4 font-semibold tracking-wider">Status</th>
<th class="py-3 px-4 font-semibold tracking-wider">Data</th>
<th class="py-3 px-4 rounded-r-md text-right font-semibold tracking-wider">Ações</th>
</tr>
</thead>
<tbody class="divide-y divide-surface-container">
<!-- Guest Row 1 -->
<tr class="hover:bg-surface-container-low/40 transition-colors">
<td class="py-4 px-4">
<div class="flex items-center gap-3">
<div class="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center font-bold text-primary text-sm">
                      MS
                    </div>
<div>
<span class="font-body-md text-body-md text-on-surface font-medium block">Mariana &amp; Stefan Albuquerque</span>
<span class="font-label-caps text-label-caps text-outline">mariana.alb@gmail.com</span>
</div>
</div>
</td>
<td class="py-4 px-4">
<span class="px-2.5 py-1 text-label-caps font-label-caps bg-secondary-fixed/40 text-on-secondary-fixed font-semibold uppercase tracking-wider">
                    Padrinho
                  </span>
</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">2</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">0</td>
<td class="py-4 px-4">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-on-surface-variant font-label-caps text-label-caps font-medium">
<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span> Confirmado
                  </span>
</td>
<td class="py-4 px-4 font-body-md text-body-md text-on-surface-variant">Hoje, 14:28</td>
<td class="py-4 px-4 text-right">
<div class="inline-flex items-center gap-1">
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" title="Ver Detalhes" type="button">
<span class="material-symbols-outlined text-[18px]">visibility</span>
</button>
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" title="Contatar" type="button">
<span class="material-symbols-outlined text-[18px]">chat</span>
</button>
</div>
</td>
</tr>
<!-- Guest Row 2 -->
<tr class="hover:bg-surface-container-low/40 transition-colors">
<td class="py-4 px-4">
<div class="flex items-center gap-3">
<div class="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center font-bold text-primary text-sm">
                      CA
                    </div>
<div>
<span class="font-body-md text-body-md text-on-surface font-medium block">Carlos Eduardo de Andrada</span>
<span class="font-label-caps text-label-caps text-outline">+55 (11) 98834-0012</span>
</div>
</div>
</td>
<td class="py-4 px-4">
<span class="px-2.5 py-1 text-label-caps font-label-caps bg-primary-fixed/40 text-on-primary-fixed font-semibold uppercase tracking-wider">
                    Família
                  </span>
</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">3</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">1</td>
<td class="py-4 px-4">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-on-surface-variant font-label-caps text-label-caps font-medium">
<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span> Confirmado
                  </span>
</td>
<td class="py-4 px-4 font-body-md text-body-md text-on-surface-variant">Hoje, 11:05</td>
<td class="py-4 px-4 text-right">
<div class="inline-flex items-center gap-1">
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">visibility</span>
</button>
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">chat</span>
</button>
</div>
</td>
</tr>
<!-- Guest Row 3 -->
<tr class="hover:bg-surface-container-low/40 transition-colors">
<td class="py-4 px-4">
<div class="flex items-center gap-3">
<div class="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center font-bold text-primary text-sm">
                      FR
                    </div>
<div>
<span class="font-body-md text-body-md text-on-surface font-medium block">Fernanda Ramos &amp; Acompanhante</span>
<span class="font-label-caps text-label-caps text-outline">f.ramos@design.com.br</span>
</div>
</div>
</td>
<td class="py-4 px-4">
<span class="px-2.5 py-1 text-label-caps font-label-caps bg-surface-container-high text-on-surface-variant font-semibold uppercase tracking-wider">
                    Convidado
                  </span>
</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">2</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">0</td>
<td class="py-4 px-4">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-on-surface-variant font-label-caps text-label-caps font-medium">
<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span> Confirmado
                  </span>
</td>
<td class="py-4 px-4 font-body-md text-body-md text-on-surface-variant">Ontem, 20:14</td>
<td class="py-4 px-4 text-right">
<div class="inline-flex items-center gap-1">
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">visibility</span>
</button>
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">chat</span>
</button>
</div>
</td>
</tr>
<!-- Guest Row 4 (Declined) -->
<tr class="hover:bg-surface-container-low/40 transition-colors">
<td class="py-4 px-4">
<div class="flex items-center gap-3">
<div class="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center font-bold text-outline text-sm">
                      VR
                    </div>
<div>
<span class="font-body-md text-body-md text-on-surface font-medium block">Vinicius Rocha Silveira</span>
<span class="font-label-caps text-label-caps text-outline">vini.rocha@outlook.com</span>
</div>
</div>
</td>
<td class="py-4 px-4">
<span class="px-2.5 py-1 text-label-caps font-label-caps bg-surface-container-high text-on-surface-variant font-semibold uppercase tracking-wider">
                    Convidado
                  </span>
</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-outline">0</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-outline">0</td>
<td class="py-4 px-4">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-error-container text-on-error-container font-label-caps text-label-caps font-medium">
<span class="w-1.5 h-1.5 rounded-full bg-error"></span> Não poderá ir
                  </span>
</td>
<td class="py-4 px-4 font-body-md text-body-md text-on-surface-variant">Ontem, 16:50</td>
<td class="py-4 px-4 text-right">
<div class="inline-flex items-center gap-1">
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">visibility</span>
</button>
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">chat</span>
</button>
</div>
</td>
</tr>
<!-- Guest Row 5 -->
<tr class="hover:bg-surface-container-low/40 transition-colors">
<td class="py-4 px-4">
<div class="flex items-center gap-3">
<div class="w-9 h-9 rounded-full bg-surface-container flex items-center justify-center font-bold text-primary text-sm">
                      GL
                    </div>
<div>
<span class="font-body-md text-body-md text-on-surface font-medium block">Dra. Gabriela Lins de Vasconcelos</span>
<span class="font-label-caps text-label-caps text-outline">+55 (21) 99120-7744</span>
</div>
</div>
</td>
<td class="py-4 px-4">
<span class="px-2.5 py-1 text-label-caps font-label-caps bg-secondary-fixed/40 text-on-secondary-fixed font-semibold uppercase tracking-wider">
                    Padrinho
                  </span>
</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">2</td>
<td class="py-4 px-4 text-center font-body-md text-body-md text-on-surface">0</td>
<td class="py-4 px-4">
<span class="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-surface-container-high text-on-surface-variant font-label-caps text-label-caps font-medium">
<span class="w-1.5 h-1.5 rounded-full bg-secondary"></span> Confirmado
                  </span>
</td>
<td class="py-4 px-4 font-body-md text-body-md text-on-surface-variant">22 Out, 09:12</td>
<td class="py-4 px-4 text-right">
<div class="inline-flex items-center gap-1">
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">visibility</span>
</button>
<button class="p-1.5 rounded hover:bg-surface-container text-on-surface-variant hover:text-on-surface transition-colors" type="button">
<span class="material-symbols-outlined text-[18px]">chat</span>
</button>
</div>
</td>
</tr>
</tbody>
</table>
</div>
</div>
</div>
<!-- Right Column (35% -> 4 columns on 12-grid) -->
<div class="lg:col-span-4 flex flex-col space-y-8">
<!-- Recent Gifts Purchased -->
<div class="bg-surface-container-lowest rounded-xl p-6 shadow-sm">
<div class="flex items-center justify-between pb-4">
<div>
<span class="font-label-caps text-label-caps uppercase text-outline tracking-widest block mb-0.5">Lista de Desejos</span>
<h3 class="font-section-title text-section-title text-on-surface text-[22px]">Presentes Recentes</h3>
</div>
<span class="material-symbols-outlined text-secondary text-[22px]">featured_seasonal_and_gifts</span>
</div>
<div class="space-y-4 mt-2">
<!-- Gift Item 1 -->
<div class="p-3 rounded-lg bg-surface-container-low/70 flex items-center justify-between gap-3 hover:bg-surface-container-high transition-colors">
<div class="flex items-center gap-3 min-w-0">
<img class="w-12 h-12 rounded-lg object-cover flex-shrink-0" data-alt="A luxury champagne flutes set on a silk runner with delicate warm lighting and soft cream aesthetic" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBCliQNvAaQcxexLj3DdE1elO2hVPmjpCWQHmYzZeD8q96HMubmUu0U9LbxKpv_C6hE7fgHBmUWwl-vCkbJu74L30oO7eP0vOiRlVo73G2p07QiMVbhyHYWPnLDHldvqubPd5seFn-iFjNqwX1PhNVM5uN_F1x_ffD8boxENT3nDl1-9AV3P5BflsZ69qUi49XQg2lnHHHbQvlCY2dwxVZKnAehuvWbewb1VaH5uBRCaARepX68Xsm5"/>
<div class="min-w-0">
<span class="font-body-md text-body-md font-medium text-on-surface truncate block">Jogo Taças de Cristal Baccarat</span>
<span class="font-label-caps text-label-caps text-outline block truncate">Por: Helena &amp; Rodrigo S.</span>
</div>
</div>
<div class="text-right flex-shrink-0">
<span class="font-body-md text-body-md font-semibold text-secondary block">R$ 1.850</span>
<span class="inline-block px-1.5 py-0.5 rounded text-[10px] font-label-caps uppercase bg-primary-fixed/50 text-on-primary-fixed font-semibold">Enviado</span>
</div>
</div>
<!-- Gift Item 2 -->
<div class="p-3 rounded-lg bg-surface-container-low/70 flex items-center justify-between gap-3 hover:bg-surface-container-high transition-colors">
<div class="flex items-center gap-3 min-w-0">
<img class="w-12 h-12 rounded-lg object-cover flex-shrink-0" data-alt="A luxurious seaside resort terrace during sunset in Amalfi coast, editorial photography with taupe and golden tones" src="https://lh3.googleusercontent.com/aida-public/AB6AXuA_qVJNE-5Yr8rp5RU7QPJ04g_uWwow4dHZhJv_KgN3CXpWygYJkASj-QQpR0o73aT4Mz-lyMUPpxpta3Q6Q8BeeryeBI8pjfpslgZpCN86ytA_Mxyysn8k1W4YTsltxbiHPy8Nq8uorcQ_HIos_KL8HtvibB-PTAY_sYdh4cm5aZz3Q39rPnBioQRrlk8kNRDGxHtIAIGokuBGmn4FXOmGJrbodf-tw47kVRFg89eBHPXn2i3anXg_"/>
<div class="min-w-0">
<span class="font-body-md text-body-md font-medium text-on-surface truncate block">Cota Lua de Mel: Costa Amalfitana</span>
<span class="font-label-caps text-label-caps text-outline block truncate">Por: Beatriz Meneses</span>
</div>
</div>
<div class="text-right flex-shrink-0">
<span class="font-body-md text-body-md font-semibold text-secondary block">R$ 1.200</span>
<span class="inline-block px-1.5 py-0.5 rounded text-[10px] font-label-caps uppercase bg-secondary-fixed/50 text-on-secondary-fixed font-semibold">Pendente</span>
</div>
</div>
<!-- Gift Item 3 -->
<div class="p-3 rounded-lg bg-surface-container-low/70 flex items-center justify-between gap-3 hover:bg-surface-container-high transition-colors">
<div class="flex items-center gap-3 min-w-0">
<img class="w-12 h-12 rounded-lg object-cover flex-shrink-0" data-alt="An artisanal ceramic dinnerware set beautifully composed with linen napkins and subtle taupe reflections" src="https://lh3.googleusercontent.com/aida-public/AB6AXuDyWZuzRwme97HQ9E3bkIH_gybJ8pf-0qLz-R2RYw92vAwFdTvF84SPwy-fIa7-RCvT3FjkdG8pPitzY_x9pfJkm-HxgZkQE06qdSXjRYuOJvcLCYUvH36p5c8ZMFxq_I0_zUcIa2zr5VU4kMxp0vUjkOUVOXCPOE8Q_Ts0zr8xoq4iOgLmW5vmSIeeHlcqwPeKIVlSC1OV7pokpbrON6t2876Gwh0CPl7pQ_6UdwdoxcOdx7Jdv3nk"/>
<div class="min-w-0">
<span class="font-body-md text-body-md font-medium text-on-surface truncate block">Aparelho de Jantar Cerâmica Crua</span>
<span class="font-label-caps text-label-caps text-outline block truncate">Por: Marcelo Paiva</span>
</div>
</div>
<div class="text-right flex-shrink-0">
<span class="font-body-md text-body-md font-semibold text-secondary block">R$ 980</span>
<span class="inline-block px-1.5 py-0.5 rounded text-[10px] font-label-caps uppercase bg-primary-fixed/50 text-on-primary-fixed font-semibold">Enviado</span>
</div>
</div>
</div>
<button class="w-full mt-4 py-2.5 rounded-lg bg-surface-container text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high font-label-caps text-label-caps uppercase transition-colors" type="button">
          Gerenciar Lista Completa
        </button>
</div>
<!-- Quick System Audit Logs -->
<div class="bg-surface-container-lowest rounded-xl p-6 shadow-sm">
<div class="flex items-center justify-between pb-4">
<div>
<span class="font-label-caps text-label-caps uppercase text-outline tracking-widest block mb-0.5">Segurança &amp; Rastreio</span>
<h3 class="font-section-title text-section-title text-on-surface text-[22px]">Atividades Recentes</h3>
</div>
<span class="material-symbols-outlined text-outline text-[20px]">history</span>
</div>
<div class="space-y-4 mt-2">
<div class="flex items-start gap-3">
<div class="w-8 h-8 rounded-full bg-secondary-fixed/50 text-on-secondary-fixed flex items-center justify-center flex-shrink-0 mt-0.5">
<span class="material-symbols-outlined text-[16px]">paid</span>
</div>
<div class="min-w-0">
<p class="font-body-md text-body-md text-on-surface text-sm leading-snug">
                Novo presente recebido via PIX (<span class="font-medium text-secondary">R$ 1.850,00</span>)
              </p>
<span class="font-label-caps text-label-caps text-outline block mt-0.5">Hoje às 14:10 • Gateway Efí</span>
</div>
</div>
<div class="flex items-start gap-3">
<div class="w-8 h-8 rounded-full bg-primary-fixed/50 text-on-primary-fixed flex items-center justify-center flex-shrink-0 mt-0.5">
<span class="material-symbols-outlined text-[16px]">check_circle</span>
</div>
<div class="min-w-0">
<p class="font-body-md text-body-md text-on-surface text-sm leading-snug">
                Convidado <span class="font-medium text-on-surface">Lucas Silva</span> confirmou presença
              </p>
<span class="font-label-caps text-label-caps text-outline block mt-0.5">Hoje às 12:45 • RSVP Web</span>
</div>
</div>
<div class="flex items-start gap-3">
<div class="w-8 h-8 rounded-full bg-surface-container-high text-on-surface-variant flex items-center justify-center flex-shrink-0 mt-0.5">
<span class="material-symbols-outlined text-[16px]">edit</span>
</div>
<div class="min-w-0">
<p class="font-body-md text-body-md text-on-surface text-sm leading-snug">
                Atualização da lista de presentes por <span class="font-medium text-primary">Liandra</span>
</p>
<span class="font-label-caps text-label-caps text-outline block mt-0.5">Ontem às 22:30 • Sessão Admin</span>
</div>
</div>
</div>
</div>
<!-- Quick Toggles / Configuration Shortcuts -->
<div class="bg-surface-container-lowest rounded-xl p-6 shadow-sm">
<div class="flex items-center justify-between pb-3">
<span class="font-label-caps text-label-caps uppercase text-outline tracking-widest block">Atalhos de Configuração</span>
<span class="material-symbols-outlined text-outline text-[18px]">toggle_on</span>
</div>
<div class="divide-y divide-surface-container">
<!-- Toggle 1 -->
<div class="py-3 flex items-center justify-between">
<div>
<span class="font-body-md text-body-md font-medium text-on-surface block text-sm">Lista de Presentes Ativa</span>
<span class="font-label-caps text-label-caps text-outline">Visível aos convidados no site</span>
</div>
<label class="relative inline-flex items-center cursor-pointer">
<input checked="" class="sr-only peer" type="checkbox"/>
<div class="w-11 h-6 bg-surface-container-high peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-secondary"></div>
</label>
</div>
<!-- Toggle 2 -->
<div class="py-3 flex items-center justify-between">
<div>
<span class="font-body-md text-body-md font-medium text-on-surface block text-sm">RSVP Online Liberado</span>
<span class="font-label-caps text-label-caps text-outline">Recebendo respostas até 01/11</span>
</div>
<label class="relative inline-flex items-center cursor-pointer">
<input checked="" class="sr-only peer" type="checkbox"/>
<div class="w-11 h-6 bg-surface-container-high peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-secondary"></div>
</label>
</div>
<!-- Toggle 3 -->
<div class="py-3 flex items-center justify-between">
<div>
<span class="font-body-md text-body-md font-medium text-on-surface block text-sm">Notificações WhatsApp</span>
<span class="font-label-caps text-label-caps text-outline">Disparo automático aos noivos</span>
</div>
<label class="relative inline-flex items-center cursor-pointer">
<input checked="" class="sr-only peer" type="checkbox"/>
<div class="w-11 h-6 bg-surface-container-high peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-secondary"></div>
</label>
</div>
</div>
</div>
</div>
</div>
</div></main></div></body></html>