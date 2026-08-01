/* See LICENSE file for copyright and license details. */

static int topbar     = 1;   /* -b: appear at bottom */
static int centered   = 1;   /* center on screen */
static int min_width  = 600; /* minimum width when centered */

static const char *fonts[] = { "JetBrainsMono Nerd Font Mono:size=10" };
static const char *prompt  = NULL;

/* Catppuccin Mocha */
static const char *colors[SchemeLast][2] = {
	/*     fg           bg       */
	[SchemeNorm] = { "#cdd6f4", "#1e1e2e" },
	[SchemeSel]  = { "#1e1e2e", "#cba6f7" },
	[SchemeOut]  = { "#1e1e2e", "#e78284" },
};

static unsigned int lines      = 10;   /* vertical list item count */
static unsigned int lineheight = 24;   /* row height (0 = font height + 2) */
static unsigned int border_width = 2;  /* border around the window */

static const char worddelimiters[] = " ";
