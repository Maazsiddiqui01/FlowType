from __future__ import annotations

from dataclasses import asdict, dataclass


@dataclass(frozen=True, slots=True)
class ModePreset:
    identifier: str
    label: str
    summary: str
    accent: str
    instructions: str


@dataclass(frozen=True, slots=True)
class ProviderOption:
    identifier: str
    label: str
    summary: str
    accent: str
    badge: str
    badge_background: str
    badge_foreground: str
    key_env: str
    key_hint: str
    featured: bool = True


@dataclass(frozen=True, slots=True)
class CleanupModelOption:
    provider: str
    identifier: str
    label: str
    summary: str
    speed: str
    quality: str
    cost: str
    tags: tuple[str, ...]
    family: str


@dataclass(frozen=True, slots=True)
class LanguageOption:
    identifier: str
    code: str
    label: str
    summary: str


MODE_PRESETS: tuple[ModePreset, ...] = (
    ModePreset(
        identifier="default",
        label="Default",
        summary="Balanced cleanup for everyday dictation, messages, and notes.",
        accent="#7dd3fc",
        instructions="",
    ),
    ModePreset(
        identifier="focused",
        label="Focused Writing",
        summary="Sharper punctuation and paragraph structure for polished prose.",
        accent="#34d399",
        instructions=(
            "Prefer concise sentence structure and polished paragraph breaks while keeping the original meaning."
        ),
    ),
    ModePreset(
        identifier="meeting",
        label="Meetings",
        summary="Preserve dates, owners, and action items exactly as spoken.",
        accent="#f59e0b",
        instructions=(
            "Keep meeting-style structure clear. Preserve names, dates, action items, and commitments exactly."
        ),
    ),
    ModePreset(
        identifier="technical",
        label="Technical",
        summary="Protect commands, filenames, acronyms, and code-like wording.",
        accent="#a78bfa",
        instructions=(
            "Preserve technical terms, CLI flags, filenames, package names, acronyms, and code-like phrases exactly."
        ),
    ),
)


PROVIDER_OPTIONS: tuple[ProviderOption, ...] = (
    ProviderOption(
        identifier="openrouter",
        label="OpenRouter",
        summary="One key with current free and paid models across multiple providers.",
        accent="#7b92ff",
        badge="OR",
        badge_background="#14203a",
        badge_foreground="#dfe7ff",
        key_env="OPENROUTER_API_KEY",
        key_hint="One key, multiple providers, current free and paid model picks.",
    ),
    ProviderOption(
        identifier="openai",
        label="OpenAI",
        summary="Direct OpenAI cleanup with current GPT-5 and GPT-4.1 text models.",
        accent="#68d3b0",
        badge="OA",
        badge_background="#13241f",
        badge_foreground="#dff9ef",
        key_env="OPENAI_API_KEY",
        key_hint="Use your OpenAI API key directly.",
    ),
    ProviderOption(
        identifier="anthropic",
        label="Claude",
        summary="Direct Anthropic cleanup with current Claude 4.5 models and strong tone preservation.",
        accent="#f3bb8a",
        badge="CL",
        badge_background="#2a1d15",
        badge_foreground="#fff0e2",
        key_env="ANTHROPIC_API_KEY",
        key_hint="Claude models via Anthropic's native API.",
    ),
    ProviderOption(
        identifier="gemini",
        label="Gemini",
        summary="Direct Gemini cleanup with Gemini 3.1 and 2.5 model options.",
        accent="#71a7ff",
        badge="GM",
        badge_background="#14213a",
        badge_foreground="#e4eeff",
        key_env="GEMINI_API_KEY",
        key_hint="Supports GEMINI_API_KEY or GOOGLE_API_KEY.",
    ),
    ProviderOption(
        identifier="xai",
        label="Grok",
        summary="Direct xAI cleanup with current Grok 4 and Grok 3 options.",
        accent="#c8d2dc",
        badge="X",
        badge_background="#1a2026",
        badge_foreground="#f2f6fb",
        key_env="XAI_API_KEY",
        key_hint="Grok models through xAI's chat completions endpoint.",
    ),
    ProviderOption(
        identifier="groq",
        label="Groq",
        summary="Extremely fast hosted open models for experimental cleanup flows.",
        accent="#87df8f",
        badge="GQ",
        badge_background="#132218",
        badge_foreground="#e4f9e6",
        key_env="GROQ_API_KEY",
        key_hint="Low-latency hosted open models.",
        featured=False,
    ),
    ProviderOption(
        identifier="ollama",
        label="Ollama",
        summary="Local cleanup with no cloud dependency if you already run Ollama.",
        accent="#f4c56f",
        badge="OL",
        badge_background="#292012",
        badge_foreground="#fff2d8",
        key_env="",
        key_hint="Runs locally at http://localhost:11434 by default.",
        featured=False,
    ),
    ProviderOption(
        identifier="none",
        label="Local only",
        summary="Skip LLM cleanup and deliver the raw local transcript.",
        accent="#97a4b5",
        badge="FT",
        badge_background="#17202a",
        badge_foreground="#e5edf7",
        key_env="",
        key_hint="Fastest setup if you want to stay fully local for now.",
    ),
)


MODEL_FAMILY_META: dict[str, dict[str, str]] = {
    "openrouter": {
        "label": "OpenRouter",
        "badge": "OR",
        "accent": "#7b92ff",
        "badgeBackground": "#14203a",
        "badgeForeground": "#dfe7ff",
    },
    "openai": {
        "label": "OpenAI",
        "badge": "OA",
        "accent": "#68d3b0",
        "badgeBackground": "#13241f",
        "badgeForeground": "#dff9ef",
    },
    "anthropic": {
        "label": "Claude",
        "badge": "CL",
        "accent": "#f3bb8a",
        "badgeBackground": "#2a1d15",
        "badgeForeground": "#fff0e2",
    },
    "gemini": {
        "label": "Gemini",
        "badge": "GM",
        "accent": "#71a7ff",
        "badgeBackground": "#14213a",
        "badgeForeground": "#e4eeff",
    },
    "xai": {
        "label": "Grok",
        "badge": "X",
        "accent": "#c8d2dc",
        "badgeBackground": "#1a2026",
        "badgeForeground": "#f2f6fb",
    },
    "deepseek": {
        "label": "DeepSeek",
        "badge": "DS",
        "accent": "#6f8cff",
        "badgeBackground": "#15203a",
        "badgeForeground": "#e7edff",
    },
    "qwen": {
        "label": "Qwen",
        "badge": "QW",
        "accent": "#8b5cf6",
        "badgeBackground": "#22163d",
        "badgeForeground": "#efe7ff",
    },
    "meta": {
        "label": "Llama",
        "badge": "LL",
        "accent": "#5b8cff",
        "badgeBackground": "#15233e",
        "badgeForeground": "#e6efff",
    },
    "google": {
        "label": "Google",
        "badge": "GG",
        "accent": "#5b8cff",
        "badgeBackground": "#16233c",
        "badgeForeground": "#e8efff",
    },
    "groq": {
        "label": "Groq",
        "badge": "GQ",
        "accent": "#87df8f",
        "badgeBackground": "#132218",
        "badgeForeground": "#e4f9e6",
    },
    "ollama": {
        "label": "Ollama",
        "badge": "OL",
        "accent": "#f4c56f",
        "badgeBackground": "#292012",
        "badgeForeground": "#fff2d8",
    },
}


def _model(
    provider: str,
    identifier: str,
    label: str,
    summary: str,
    speed: str,
    quality: str,
    cost: str,
    tags: tuple[str, ...],
    family: str,
) -> CleanupModelOption:
    return CleanupModelOption(
        provider=provider,
        identifier=identifier,
        label=label,
        summary=summary,
        speed=speed,
        quality=quality,
        cost=cost,
        tags=tags,
        family=family,
    )


CURATED_MODELS: tuple[CleanupModelOption, ...] = (
    _model(
        "openrouter",
        "openrouter/free",
        "OpenRouter free router",
        "Lets OpenRouter route cleanup through currently supported free models automatically.",
        "Balanced",
        "Mixed",
        "Free",
        ("Free", "Router"),
        "openrouter",
    ),
    _model(
        "openrouter",
        "openai/gpt-5.4-mini",
        "GPT-5.4 Mini",
        "Current OpenAI sweet spot for fast, high-quality cleanup through one router key.",
        "Fast",
        "High",
        "Medium",
        ("Recommended", "Paid"),
        "openai",
    ),
    _model(
        "openrouter",
        "openai/gpt-5.4",
        "GPT-5.4",
        "Newest premium OpenAI option when cleanup quality matters most.",
        "Balanced",
        "Best",
        "Premium",
        ("Latest", "Paid"),
        "openai",
    ),
    _model(
        "openrouter",
        "openai/gpt-5.4-nano",
        "GPT-5.4 Nano",
        "Low-cost OpenAI option for quick cleanup passes with lighter reasoning.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget", "Paid"),
        "openai",
    ),
    _model(
        "openrouter",
        "anthropic/claude-sonnet-4.6",
        "Claude Sonnet 4.6",
        "Current Claude all-rounder with strong tone preservation and careful cleanup.",
        "Balanced",
        "Best",
        "High",
        ("Latest", "Paid"),
        "anthropic",
    ),
    _model(
        "openrouter",
        "anthropic/claude-haiku-4.5",
        "Claude Haiku 4.5",
        "Fast Claude option when you want cleaner wording without much latency overhead.",
        "Fast",
        "High",
        "Medium",
        ("Fast", "Paid"),
        "anthropic",
    ),
    _model(
        "openrouter",
        "anthropic/claude-opus-4.6",
        "Claude Opus 4.6",
        "Highest-end Claude option in the router list for premium cleanup quality.",
        "Balanced",
        "Best",
        "Premium",
        ("Premium", "Paid"),
        "anthropic",
    ),
    _model(
        "openrouter",
        "google/gemini-3.1-pro-preview",
        "Gemini 3.1 Pro Preview",
        "Current higher-end Gemini option for polished cleanup and good context handling.",
        "Balanced",
        "High",
        "High",
        ("Preview", "Paid"),
        "gemini",
    ),
    _model(
        "openrouter",
        "google/gemini-3-flash-preview",
        "Gemini 3 Flash Preview",
        "Fast current Gemini option when you want low latency with modern Google models.",
        "Fast",
        "High",
        "Medium",
        ("Preview", "Paid"),
        "gemini",
    ),
    _model(
        "openrouter",
        "google/gemini-3.1-flash-lite-preview",
        "Gemini 3.1 Flash Lite Preview",
        "Lowest-cost current Gemini preview option for routine cleanup tasks.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget", "Paid"),
        "gemini",
    ),
    _model(
        "openrouter",
        "deepseek/deepseek-v3.2",
        "DeepSeek V3.2",
        "Strong value model for cleanup when you want modern reasoning at lower cost.",
        "Fast",
        "High",
        "Low",
        ("Value", "Paid"),
        "deepseek",
    ),
    _model(
        "openrouter",
        "deepseek/deepseek-r1-0528",
        "DeepSeek R1 0528",
        "Reasoning-heavy cleanup option when transcripts need more interpretation.",
        "Balanced",
        "High",
        "Medium",
        ("Reasoning", "Paid"),
        "deepseek",
    ),
    _model(
        "openrouter",
        "openai/gpt-oss-20b:free",
        "GPT OSS 20B",
        "Free open-weight option for quick cleanup when you do not want paid routing.",
        "Fast",
        "Balanced",
        "Free",
        ("Free", "Open"),
        "openai",
    ),
    _model(
        "openrouter",
        "openai/gpt-oss-120b:free",
        "GPT OSS 120B",
        "Free larger open-weight option with better cleanup quality than the smaller OSS tier.",
        "Balanced",
        "High",
        "Free",
        ("Free", "Open"),
        "openai",
    ),
    _model(
        "openrouter",
        "meta-llama/llama-3.3-70b-instruct:free",
        "Llama 3.3 70B Instruct",
        "Popular free route for decent cleanup quality without paying for a hosted frontier model.",
        "Balanced",
        "High",
        "Free",
        ("Free", "Open"),
        "meta",
    ),
    _model(
        "openrouter",
        "qwen/qwen3-next-80b-a3b-instruct:free",
        "Qwen3 Next 80B",
        "Current free Qwen option with stronger editing quality than many smaller open models.",
        "Balanced",
        "High",
        "Free",
        ("Free", "Open"),
        "qwen",
    ),
    _model(
        "openrouter",
        "qwen/qwen3-coder:free",
        "Qwen3 Coder",
        "Free option that is especially good when dictated text includes technical wording or commands.",
        "Balanced",
        "High",
        "Free",
        ("Free", "Technical"),
        "qwen",
    ),
    _model(
        "openrouter",
        "google/gemma-3-27b-it:free",
        "Gemma 3 27B",
        "Free Google open-weight option with a good quality-to-cost profile for cleanup.",
        "Balanced",
        "Balanced",
        "Free",
        ("Free", "Open"),
        "google",
    ),
    _model(
        "openai",
        "gpt-5.4-mini",
        "GPT-5.4 Mini",
        "Current best default for OpenAI cleanup when you want speed and strong formatting.",
        "Fast",
        "High",
        "Medium",
        ("Recommended", "Current"),
        "openai",
    ),
    _model(
        "openai",
        "gpt-5.4",
        "GPT-5.4",
        "Newest higher-end OpenAI model for premium cleanup quality.",
        "Balanced",
        "Best",
        "Premium",
        ("Latest",),
        "openai",
    ),
    _model(
        "openai",
        "gpt-5.4-nano",
        "GPT-5.4 Nano",
        "Fastest lower-cost GPT-5.4 family option for short cleanup loops.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget",),
        "openai",
    ),
    _model(
        "openai",
        "gpt-5.2",
        "GPT-5.2",
        "Solid current GPT-5 tier when you want more headroom than the mini model.",
        "Balanced",
        "High",
        "High",
        ("Current",),
        "openai",
    ),
    _model(
        "openai",
        "gpt-4.1",
        "GPT-4.1",
        "Stable high-quality option if you prefer the GPT-4.1 family over GPT-5.",
        "Balanced",
        "High",
        "Medium",
        ("Stable",),
        "openai",
    ),
    _model(
        "openai",
        "gpt-4.1-mini",
        "GPT-4.1 Mini",
        "Cheaper stable option with good cleanup quality for everyday dictation.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget", "Stable"),
        "openai",
    ),
    _model(
        "anthropic",
        "claude-sonnet-4-5",
        "Claude Sonnet 4.5",
        "Current Anthropic default for high-quality cleanup and strong tone preservation.",
        "Balanced",
        "Best",
        "High",
        ("Recommended", "Current"),
        "anthropic",
    ),
    _model(
        "anthropic",
        "claude-haiku-4-5",
        "Claude Haiku 4.5",
        "Fastest current Claude option when latency matters most.",
        "Fast",
        "High",
        "Medium",
        ("Fast", "Current"),
        "anthropic",
    ),
    _model(
        "anthropic",
        "claude-opus-4-5",
        "Claude Opus 4.5",
        "Premium Claude choice when cleanup quality matters more than speed or cost.",
        "Balanced",
        "Best",
        "Premium",
        ("Premium", "Current"),
        "anthropic",
    ),
    _model(
        "gemini",
        "gemini-3.1-pro-preview",
        "Gemini 3.1 Pro Preview",
        "Newest higher-end Gemini option in the direct list.",
        "Balanced",
        "High",
        "High",
        ("Latest", "Preview"),
        "gemini",
    ),
    _model(
        "gemini",
        "gemini-3-flash-preview",
        "Gemini 3 Flash Preview",
        "Fast current Gemini model with strong everyday cleanup performance.",
        "Fast",
        "High",
        "Medium",
        ("Current", "Preview"),
        "gemini",
    ),
    _model(
        "gemini",
        "gemini-3.1-flash-lite-preview",
        "Gemini 3.1 Flash Lite Preview",
        "Fastest current Gemini option for low-cost cleanup loops.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget", "Preview"),
        "gemini",
    ),
    _model(
        "gemini",
        "gemini-2.5-pro",
        "Gemini 2.5 Pro",
        "Stable higher-quality Gemini fallback if you want to avoid preview models.",
        "Balanced",
        "High",
        "High",
        ("Stable",),
        "gemini",
    ),
    _model(
        "gemini",
        "gemini-2.5-flash",
        "Gemini 2.5 Flash",
        "Good stable balance of speed and quality for daily cleanup.",
        "Fast",
        "High",
        "Medium",
        ("Stable",),
        "gemini",
    ),
    _model(
        "gemini",
        "gemini-2.5-flash-lite",
        "Gemini 2.5 Flash Lite",
        "Lowest-cost stable Gemini option when speed matters more than polish.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget", "Stable"),
        "gemini",
    ),
    _model(
        "xai",
        "grok-4.20-beta",
        "Grok 4.20 Beta",
        "Current higher-end xAI option when you want the newest Grok cleanup behavior.",
        "Balanced",
        "High",
        "High",
        ("Latest", "Beta"),
        "xai",
    ),
    _model(
        "xai",
        "grok-4.1-fast",
        "Grok 4.1 Fast",
        "Best current low-latency Grok option for short cleanup passes.",
        "Fast",
        "High",
        "Medium",
        ("Recommended",),
        "xai",
    ),
    _model(
        "xai",
        "grok-4",
        "Grok 4",
        "Stable high-quality Grok option for everyday cleanup.",
        "Balanced",
        "High",
        "High",
        ("Stable",),
        "xai",
    ),
    _model(
        "xai",
        "grok-3",
        "Grok 3",
        "Older Grok fallback if you prefer a stable non-4-series model.",
        "Balanced",
        "Balanced",
        "Medium",
        ("Legacy",),
        "xai",
    ),
    _model(
        "xai",
        "grok-3-mini-beta",
        "Grok 3 Mini Beta",
        "Low-cost xAI option when you want faster responses than the larger Grok models.",
        "Fast",
        "Balanced",
        "Low",
        ("Budget", "Beta"),
        "xai",
    ),
    _model(
        "groq",
        "llama-3.1-8b-instant",
        "Llama 3.1 8B Instant",
        "Very fast hosted open model with lower cleanup quality but great latency.",
        "Fast",
        "Balanced",
        "Low",
        ("Fast",),
        "groq",
    ),
    _model(
        "groq",
        "llama-3.3-70b-versatile",
        "Llama 3.3 70B Versatile",
        "Stronger Groq choice when you want better cleanup quality from open models.",
        "Fast",
        "High",
        "Medium",
        ("Balanced",),
        "groq",
    ),
    _model(
        "groq",
        "openai/gpt-oss-20b",
        "GPT OSS 20B",
        "Fast hosted open-weight option for experimental cleanup flows.",
        "Fast",
        "Balanced",
        "Low",
        ("Open",),
        "groq",
    ),
    _model(
        "ollama",
        "llama3.1:8b",
        "Llama 3.1 8B",
        "Private local cleanup with reasonable quality on modest hardware.",
        "Balanced",
        "Balanced",
        "Local",
        ("Local",),
        "ollama",
    ),
    _model(
        "ollama",
        "qwen2.5:7b",
        "Qwen 2.5 7B",
        "Solid local option if you want a sharper editor than smaller Llama variants.",
        "Balanced",
        "Balanced",
        "Local",
        ("Local",),
        "ollama",
    ),
)


LANGUAGE_OPTIONS: tuple[LanguageOption, ...] = (
    LanguageOption(
        identifier="english",
        code="en",
        label="English",
        summary="Fastest and most reliable when you mainly dictate in English.",
    ),
    LanguageOption(
        identifier="urdu",
        code="ur",
        label="Urdu",
        summary="Use when you want Whisper to stay anchored to Urdu rather than guessing.",
    ),
    LanguageOption(
        identifier="arabic",
        code="ar",
        label="Arabic",
        summary="Useful when dictation is primarily Arabic and you want less language drift.",
    ),
    LanguageOption(
        identifier="hindi",
        code="hi",
        label="Hindi",
        summary="Keeps cleanup and transcription aligned for Hindi dictation.",
    ),
    LanguageOption(
        identifier="auto",
        code="auto",
        label="Auto detect",
        summary="Lets Whisper detect the spoken language, better for mixed-language use.",
    ),
)


def mode_preset_map() -> dict[str, ModePreset]:
    return {preset.identifier: preset for preset in MODE_PRESETS}


def provider_option_map() -> dict[str, ProviderOption]:
    return {provider.identifier: provider for provider in PROVIDER_OPTIONS}


def provider_display_name(identifier: str) -> str:
    provider = provider_option_map().get(identifier)
    if provider is None:
        return identifier.title()
    return provider.label


def mode_instructions(mode_identifier: str, custom_prompt: str) -> str:
    preset = mode_preset_map().get(mode_identifier, mode_preset_map()["default"])
    prompt_parts = [preset.instructions.strip(), custom_prompt.strip()]
    return "\n\n".join(part for part in prompt_parts if part)


def mode_cards() -> list[dict[str, str]]:
    return [asdict(preset) for preset in MODE_PRESETS]


def cleanup_provider_cards(featured_only: bool = False) -> list[dict[str, object]]:
    providers: list[dict[str, object]] = []
    for option in PROVIDER_OPTIONS:
        if featured_only and not option.featured:
            continue
        option_dict = asdict(option)
        option_dict["badgeBackground"] = option.badge_background
        option_dict["badgeForeground"] = option.badge_foreground
        option_dict["keyEnv"] = option.key_env
        option_dict["keyHint"] = option.key_hint
        providers.append(option_dict)
    return providers


def cleanup_model_cards(provider: str) -> list[dict[str, object]]:
    if provider == "none":
        return []

    cards = []
    for option in CURATED_MODELS:
        if option.provider != provider:
            continue
        family = MODEL_FAMILY_META.get(option.family)
        option_dict = asdict(option)
        option_dict["familyLabel"] = family["label"] if family else option.family.title()
        option_dict["familyBadge"] = family["badge"] if family else option.family[:2].upper()
        option_dict["familyAccent"] = family["accent"] if family else "#5b6b80"
        option_dict["familyBadgeBackground"] = family["badgeBackground"] if family else "#17202a"
        option_dict["familyBadgeForeground"] = family["badgeForeground"] if family else "#e5edf7"
        cards.append(option_dict)
    return cards


def transcription_language_cards() -> list[dict[str, str]]:
    return [asdict(option) for option in LANGUAGE_OPTIONS]
