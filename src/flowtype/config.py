from __future__ import annotations

import copy
import os
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover
    import tomli as tomllib

from flowtype.shortcuts import validate_shortcut_for_action


APP_NAME = "FlowType"

RECOMMENDED_SHORTCUTS: dict[str, str] = {
    "hold_to_talk": "ctrl+shift+space",
    "toggle_recording": "ctrl+alt+space",
    "cancel_recording": "escape",
    "repaste_last": "",
}

DEFAULT_CONFIG_TEXT = """[general]
log_level = "INFO"
hotkey = "ctrl+shift+space"

[shortcuts]
hold_to_talk = "ctrl+shift+space"
toggle_recording = "ctrl+alt+space"
cancel_recording = "escape"
repaste_last = ""

[mode]
active = "default"
custom_prompt = ""

[vocabulary]
entries = ""

[audio]
sample_rate = 16000
channels = 1
dtype = "int16"
max_duration_seconds = 300
min_duration_ms = 250

[transcription]
model_size = "base.en"
device = "auto"
compute_type = "auto"
language = "en"
beam_size = 1
vad_filter = true

[cleanup]
provider = "openrouter"
api_key = ""
model = "openai/gpt-5.4-mini"
temperature = 0.1
max_tokens = 1024
timeout_seconds = 8
max_retries = 1
retry_backoff_seconds = 1.0
min_word_count = 3
prompt = \"\"\"You clean dictated text.
Remove filler words such as um, uh, like, and you know only when they are verbal fillers.
Fix punctuation, capitalization, spacing, and grammar.
Do not change meaning, tone, intent, or factual content.
Do not summarize or add new information.
Return only the cleaned text.\"\"\"

[output]
paste_method = "ctrl_v"
paste_delay_ms = 80
restore_clipboard = false

[experience]
hud_style = "mini"
hud_position = "bottom"
show_idle_hud = false
idle_hud_user_set = false
onboarding_dismissed = false
close_to_tray = true
dark_mode = true

[startup]
launch_at_login = true
start_minimized = true
prompt_completed = false

[history]
max_items = 40
persist = true
"""

DEFAULT_CONFIG: dict[str, Any] = {
    "general": {
        "log_level": "INFO",
        "hotkey": "ctrl+shift+space",
    },
    "shortcuts": {
        "hold_to_talk": RECOMMENDED_SHORTCUTS["hold_to_talk"],
        "toggle_recording": RECOMMENDED_SHORTCUTS["toggle_recording"],
        "cancel_recording": RECOMMENDED_SHORTCUTS["cancel_recording"],
        "repaste_last": RECOMMENDED_SHORTCUTS["repaste_last"],
    },
    "mode": {
        "active": "default",
        "custom_prompt": "",
    },
    "vocabulary": {
        "entries": "",
    },
    "audio": {
        "sample_rate": 16000,
        "channels": 1,
        "dtype": "int16",
        "max_duration_seconds": 300,
        "min_duration_ms": 250,
    },
    "transcription": {
        "model_size": "base.en",
        "device": "auto",
        "compute_type": "auto",
        "language": "en",
        "beam_size": 1,
        "vad_filter": True,
    },
    "cleanup": {
        "provider": "openrouter",
        "api_key": "",
        "model": "openai/gpt-5.4-mini",
        "temperature": 0.1,
        "max_tokens": 1024,
        "timeout_seconds": 8,
        "max_retries": 1,
        "retry_backoff_seconds": 1.0,
        "min_word_count": 3,
        "prompt": (
            "You clean dictated text.\n"
            "Remove filler words such as um, uh, like, and you know only when they are verbal fillers.\n"
            "Fix punctuation, capitalization, spacing, and grammar.\n"
            "Do not change meaning, tone, intent, or factual content.\n"
            "Do not summarize or add new information.\n"
            "Return only the cleaned text."
        ),
    },
    "output": {
        "paste_method": "ctrl_v",
        "paste_delay_ms": 80,
        "restore_clipboard": False,
    },
    "experience": {
        "hud_style": "mini",
        "hud_position": "bottom",
        "show_idle_hud": False,
        "idle_hud_user_set": False,
        "onboarding_dismissed": False,
        "close_to_tray": True,
        "dark_mode": True,
    },
    "startup": {
        "launch_at_login": True,
        "start_minimized": True,
        "prompt_completed": False,
    },
    "history": {
        "max_items": 40,
        "persist": True,
    },
}


@dataclass(slots=True, frozen=True)
class GeneralConfig:
    log_level: str
    app_dir: Path
    log_file: Path
    hotkey: str


@dataclass(slots=True, frozen=True)
class AudioConfig:
    sample_rate: int
    channels: int
    dtype: str
    max_duration_seconds: int
    min_duration_ms: int


@dataclass(slots=True, frozen=True)
class TranscriptionConfig:
    model_size: str
    device: str
    compute_type: str
    language: str
    beam_size: int
    vad_filter: bool
    model_cache_dir: Path


@dataclass(slots=True, frozen=True)
class CleanupConfig:
    provider: str
    api_key: str
    model: str
    prompt: str
    temperature: float
    max_tokens: int
    timeout_seconds: int
    max_retries: int
    retry_backoff_seconds: float
    min_word_count: int
    mode_name: str = "default"
    mode_prompt: str = ""
    vocabulary_entries: tuple[str, ...] = ()


@dataclass(slots=True, frozen=True)
class OutputConfig:
    paste_method: str
    paste_delay_ms: int
    restore_clipboard: bool


@dataclass(slots=True, frozen=True)
class ShortcutsConfig:
    hold_to_talk: str
    toggle_recording: str
    cancel_recording: str
    repaste_last: str


@dataclass(slots=True, frozen=True)
class ModeConfig:
    active: str
    custom_prompt: str


@dataclass(slots=True, frozen=True)
class VocabularyConfig:
    entries: tuple[str, ...]

    @property
    def text(self) -> str:
        return "\n".join(self.entries)


@dataclass(slots=True, frozen=True)
class ExperienceConfig:
    hud_style: str
    hud_position: str
    show_idle_hud: bool
    idle_hud_user_set: bool
    onboarding_dismissed: bool
    close_to_tray: bool
    dark_mode: bool


@dataclass(slots=True, frozen=True)
class StartupConfig:
    launch_at_login: bool
    start_minimized: bool
    prompt_completed: bool


@dataclass(slots=True, frozen=True)
class HistoryConfig:
    max_items: int
    persist: bool
    file_path: Path


@dataclass(slots=True, frozen=True)
class AppConfig:
    config_path: Path
    general: GeneralConfig
    shortcuts: ShortcutsConfig
    mode: ModeConfig
    vocabulary: VocabularyConfig
    audio: AudioConfig
    transcription: TranscriptionConfig
    cleanup: CleanupConfig
    output: OutputConfig
    experience: ExperienceConfig
    startup: StartupConfig
    history: HistoryConfig


def default_app_dir() -> Path:
    if os.name == "nt":
        appdata = os.getenv("APPDATA")
        if appdata:
            return Path(appdata) / APP_NAME
    return Path.home() / ".flowtype"


def write_default_config(destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(DEFAULT_CONFIG_TEXT, encoding="utf-8")


def seed_runtime_config(config_path: Path) -> None:
    if config_path.exists():
        return

    config_path.parent.mkdir(parents=True, exist_ok=True)
    repo_template = Path.cwd() / "config.toml"
    if repo_template.exists() and repo_template.resolve() != config_path.resolve():
        shutil.copyfile(repo_template, config_path)
        return
    write_default_config(config_path)


def discover_config_path(explicit_path: str | Path | None = None) -> Path:
    if explicit_path:
        return Path(explicit_path).expanduser().resolve()

    env_path = os.getenv("FLOWTYPE_CONFIG")
    if env_path:
        return Path(env_path).expanduser().resolve()

    return (default_app_dir() / "config.toml").resolve()


def load_config_data(explicit_path: str | Path | None = None) -> tuple[Path, dict[str, Any]]:
    config_path = discover_config_path(explicit_path)
    seed_runtime_config(config_path)
    raw_config = copy.deepcopy(DEFAULT_CONFIG)
    loaded = tomllib.loads(config_path.read_text(encoding="utf-8"))
    merged = deep_merge(raw_config, loaded)
    migrated = _normalize_cleanup_defaults(merged)
    experience = merged.setdefault("experience", {})
    experience_changed = False
    if not bool(experience.get("idle_hud_user_set", False)):
        if bool(experience.get("show_idle_hud", False)):
            experience_changed = True
        experience["show_idle_hud"] = False
    if migrated or experience_changed:
        config_path.write_text(render_config(merged), encoding="utf-8")
    return config_path, merged


def load_config(explicit_path: str | Path | None = None) -> AppConfig:
    from flowtype.catalog import mode_instructions

    config_path, merged = load_config_data(explicit_path)

    app_dir = config_path.parent
    
    # Backwards compatibility migration
    legacy_hotkey = ""
    if "hotkey" in merged["general"]:
        legacy_hotkey = str(merged["general"]["hotkey"]).strip()
        
    general = GeneralConfig(
        log_level=str(merged["general"]["log_level"]).upper().strip(),
        app_dir=app_dir,
        log_file=app_dir / "logs" / "flowtype.log",
        hotkey="",
    )
    
    shortcuts_data = merged.get("shortcuts", {})
    shortcuts = ShortcutsConfig(
        hold_to_talk=_safe_shortcut_value("hold_to_talk", str(shortcuts_data.get("hold_to_talk", legacy_hotkey)).strip()),
        toggle_recording=_safe_shortcut_value("toggle_recording", str(shortcuts_data.get("toggle_recording", "")).strip()),
        cancel_recording=_safe_shortcut_value("cancel_recording", str(shortcuts_data.get("cancel_recording", "")).strip()),
        repaste_last=_safe_shortcut_value("repaste_last", str(shortcuts_data.get("repaste_last", "")).strip()),
    )
    general = GeneralConfig(
        log_level=general.log_level,
        app_dir=general.app_dir,
        log_file=general.log_file,
        hotkey=shortcuts.hold_to_talk,
    )
    mode = ModeConfig(
        active=str(merged.get("mode", {}).get("active", "default")).strip() or "default",
        custom_prompt=str(merged.get("mode", {}).get("custom_prompt", "")).strip(),
    )
    vocabulary_text = str(merged.get("vocabulary", {}).get("entries", "")).replace("\r\n", "\n")
    vocabulary = VocabularyConfig(
        entries=tuple(line.strip() for line in vocabulary_text.splitlines() if line.strip()),
    )
    audio = AudioConfig(
        sample_rate=int(merged["audio"]["sample_rate"]),
        channels=int(merged["audio"]["channels"]),
        dtype=str(merged["audio"]["dtype"]).strip(),
        max_duration_seconds=int(merged["audio"]["max_duration_seconds"]),
        min_duration_ms=int(merged["audio"]["min_duration_ms"]),
    )
    transcription = TranscriptionConfig(
        model_size=str(merged["transcription"]["model_size"]).strip(),
        device=str(merged["transcription"]["device"]).strip().lower(),
        compute_type=str(merged["transcription"]["compute_type"]).strip().lower(),
        language=str(merged["transcription"]["language"]).strip().lower(),
        beam_size=int(merged["transcription"]["beam_size"]),
        vad_filter=bool(merged["transcription"]["vad_filter"]),
        model_cache_dir=app_dir / "models",
    )
    provider = str(merged["cleanup"]["provider"]).strip().lower()
    cleanup = CleanupConfig(
        provider=provider,
        api_key=resolve_api_key(provider, str(merged["cleanup"]["api_key"]).strip()),
        model=str(merged["cleanup"]["model"]).strip(),
        prompt=str(merged["cleanup"]["prompt"]).strip(),
        temperature=float(merged["cleanup"]["temperature"]),
        max_tokens=int(merged["cleanup"]["max_tokens"]),
        timeout_seconds=int(merged["cleanup"]["timeout_seconds"]),
        max_retries=int(merged["cleanup"]["max_retries"]),
        retry_backoff_seconds=float(merged["cleanup"]["retry_backoff_seconds"]),
        min_word_count=int(merged["cleanup"]["min_word_count"]),
        mode_name=mode.active,
        mode_prompt=mode_instructions(mode.active, mode.custom_prompt),
        vocabulary_entries=vocabulary.entries,
    )
    output = OutputConfig(
        paste_method=str(merged["output"]["paste_method"]).strip().lower(),
        paste_delay_ms=int(merged["output"]["paste_delay_ms"]),
        restore_clipboard=bool(merged["output"]["restore_clipboard"]),
    )
    experience = ExperienceConfig(
        hud_style=str(merged.get("experience", {}).get("hud_style", "mini")).strip().lower(),
        hud_position=str(merged.get("experience", {}).get("hud_position", "bottom")).strip().lower(),
        show_idle_hud=bool(merged.get("experience", {}).get("show_idle_hud", False)),
        idle_hud_user_set=bool(merged.get("experience", {}).get("idle_hud_user_set", False)),
        onboarding_dismissed=bool(merged.get("experience", {}).get("onboarding_dismissed", False)),
        close_to_tray=bool(merged.get("experience", {}).get("close_to_tray", True)),
        dark_mode=bool(merged.get("experience", {}).get("dark_mode", True)),
    )
    startup = StartupConfig(
        launch_at_login=bool(merged.get("startup", {}).get("launch_at_login", True)),
        start_minimized=bool(merged.get("startup", {}).get("start_minimized", True)),
        prompt_completed=bool(merged.get("startup", {}).get("prompt_completed", False)),
    )
    history = HistoryConfig(
        max_items=int(merged.get("history", {}).get("max_items", 40)),
        persist=bool(merged.get("history", {}).get("persist", True)),
        file_path=app_dir / "history.json",
    )

    config = AppConfig(
        config_path=config_path,
        general=general,
        shortcuts=shortcuts,
        mode=mode,
        vocabulary=vocabulary,
        audio=audio,
        transcription=transcription,
        cleanup=cleanup,
        output=output,
        experience=experience,
        startup=startup,
        history=history,
    )
    validate_config(config)
    return config


def save_config_data(config_path: str | Path, values: dict[str, Any]) -> Path:
    destination = Path(config_path).expanduser().resolve()
    merged = deep_merge(copy.deepcopy(DEFAULT_CONFIG), values)
    _normalize_cleanup_defaults(merged)
    general_hotkey = str(merged.get("general", {}).get("hotkey", "")).strip()
    shortcuts = merged.setdefault("shortcuts", {})
    raw_shortcuts = values.get("shortcuts", {})
    if general_hotkey and "hold_to_talk" not in raw_shortcuts:
        shortcuts["hold_to_talk"] = general_hotkey
    if str(shortcuts.get("hold_to_talk", "")).strip():
        merged.setdefault("general", {})
        merged["general"]["hotkey"] = str(shortcuts["hold_to_talk"]).strip()
    destination.parent.mkdir(parents=True, exist_ok=True)
    temp_path = destination.with_suffix(destination.suffix + ".tmp")
    temp_path.write_text(render_config(merged), encoding="utf-8")
    try:
        load_config(temp_path)
    except Exception:
        temp_path.unlink(missing_ok=True)
        raise
    temp_path.replace(destination)
    return destination


def resolve_api_key(provider: str, configured_value: str) -> str:
    if configured_value:
        return configured_value

    candidates = ["FLOWTYPE_API_KEY"]
    if provider == "openrouter":
        candidates.append("OPENROUTER_API_KEY")
    elif provider == "openai":
        candidates.append("OPENAI_API_KEY")
    elif provider == "anthropic":
        candidates.append("ANTHROPIC_API_KEY")
    elif provider == "gemini":
        candidates.extend(("GEMINI_API_KEY", "GOOGLE_API_KEY"))
    elif provider == "xai":
        candidates.append("XAI_API_KEY")
    elif provider == "groq":
        candidates.append("GROQ_API_KEY")

    for candidate in candidates:
        value = os.getenv(candidate, "").strip()
        if value:
            return value
    return ""


def validate_config(config: AppConfig) -> None:
    if not config.shortcuts.hold_to_talk and not config.shortcuts.toggle_recording:
        raise ValueError("At least one talk hotkey (hold or toggle) must be configured")
    for action, value in (
        ("hold_to_talk", config.shortcuts.hold_to_talk),
        ("toggle_recording", config.shortcuts.toggle_recording),
        ("cancel_recording", config.shortcuts.cancel_recording),
        ("repaste_last", config.shortcuts.repaste_last),
    ):
        validate_shortcut_for_action(action, value)
    if config.audio.sample_rate != 16000:
        raise ValueError("audio.sample_rate must be exactly 16000 for the current Whisper pipeline")
    if config.audio.channels <= 0:
        raise ValueError("audio.channels must be greater than zero")
    if config.audio.dtype != "int16":
        raise ValueError("audio.dtype must be int16 for the current Whisper pipeline")
    if config.audio.max_duration_seconds <= 0:
        raise ValueError("audio.max_duration_seconds must be greater than zero")
    if config.audio.min_duration_ms < 0:
        raise ValueError("audio.min_duration_ms must be zero or greater")
    if config.transcription.device not in {"auto", "cpu", "cuda"}:
        raise ValueError("transcription.device must be auto, cpu, or cuda")
    if config.transcription.compute_type not in {"auto", "int8", "float16", "float32"}:
        raise ValueError("transcription.compute_type must be auto, int8, float16, or float32")
    if config.cleanup.provider not in {"openrouter", "openai", "anthropic", "gemini", "xai", "groq", "ollama", "none"}:
        raise ValueError("cleanup.provider must be openrouter, openai, anthropic, gemini, xai, groq, ollama, or none")
    if config.cleanup.timeout_seconds <= 0:
        raise ValueError("cleanup.timeout_seconds must be greater than zero")
    if config.cleanup.max_retries <= 0:
        raise ValueError("cleanup.max_retries must be greater than zero")
    if config.output.paste_method not in {"ctrl_v", "clipboard_only"}:
        raise ValueError("output.paste_method must be ctrl_v or clipboard_only")
    if config.experience.hud_style not in {"classic", "mini"}:
        raise ValueError("experience.hud_style must be classic or mini")
    if config.experience.hud_position not in {"top", "bottom"}:
        raise ValueError("experience.hud_position must be top or bottom")
    if config.history.max_items <= 0:
        raise ValueError("history.max_items must be greater than zero")


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base


def render_config(values: dict[str, Any]) -> str:
    cleanup_prompt = _escape_multiline_string(str(values["cleanup"]["prompt"]))
    vocabulary_entries = _escape_multiline_string(str(values.get("vocabulary", {}).get("entries", "")))
    custom_mode_prompt = _escape_multiline_string(str(values.get("mode", {}).get("custom_prompt", "")))
    lines = [
        "[general]",
        f'log_level = "{_escape_basic_string(str(values["general"]["log_level"]).upper())}"',
        f'hotkey = "{_escape_basic_string(str(values["general"].get("hotkey") or values["shortcuts"]["hold_to_talk"]))}"',
        "",
        "[shortcuts]",
        f'hold_to_talk = "{_escape_basic_string(str(values["shortcuts"]["hold_to_talk"]))}"',
        f'toggle_recording = "{_escape_basic_string(str(values["shortcuts"]["toggle_recording"]))}"',
        f'cancel_recording = "{_escape_basic_string(str(values["shortcuts"]["cancel_recording"]))}"',
        f'repaste_last = "{_escape_basic_string(str(values["shortcuts"]["repaste_last"]))}"',
        "",
        "[mode]",
        f'active = "{_escape_basic_string(str(values.get("mode", {}).get("active", "default")))}"',
        f"custom_prompt = {custom_mode_prompt}",
        "",
        "[vocabulary]",
        f"entries = {vocabulary_entries}",
        "",
        "[audio]",
        f'sample_rate = {int(values["audio"]["sample_rate"])}',
        f'channels = {int(values["audio"]["channels"])}',
        f'dtype = "{_escape_basic_string(str(values["audio"]["dtype"]))}"',
        f'max_duration_seconds = {int(values["audio"]["max_duration_seconds"])}',
        f'min_duration_ms = {int(values["audio"]["min_duration_ms"])}',
        "",
        "[transcription]",
        f'model_size = "{_escape_basic_string(str(values["transcription"]["model_size"]))}"',
        f'device = "{_escape_basic_string(str(values["transcription"]["device"]))}"',
        f'compute_type = "{_escape_basic_string(str(values["transcription"]["compute_type"]))}"',
        f'language = "{_escape_basic_string(str(values["transcription"]["language"]))}"',
        f'beam_size = {int(values["transcription"]["beam_size"])}',
        f'vad_filter = {_toml_bool(values["transcription"]["vad_filter"])}',
        "",
        "[cleanup]",
        f'provider = "{_escape_basic_string(str(values["cleanup"]["provider"]))}"',
        f'api_key = "{_escape_basic_string(str(values["cleanup"]["api_key"]))}"',
        f'model = "{_escape_basic_string(str(values["cleanup"]["model"]))}"',
        f'temperature = {float(values["cleanup"]["temperature"])}',
        f'max_tokens = {int(values["cleanup"]["max_tokens"])}',
        f'timeout_seconds = {int(values["cleanup"]["timeout_seconds"])}',
        f'max_retries = {int(values["cleanup"]["max_retries"])}',
        f'retry_backoff_seconds = {float(values["cleanup"]["retry_backoff_seconds"])}',
        f'min_word_count = {int(values["cleanup"]["min_word_count"])}',
        f"prompt = {cleanup_prompt}",
        "",
        "[output]",
        f'paste_method = "{_escape_basic_string(str(values["output"]["paste_method"]))}"',
        f'paste_delay_ms = {int(values["output"]["paste_delay_ms"])}',
        f'restore_clipboard = {_toml_bool(values["output"]["restore_clipboard"])}',
        "",
        "[experience]",
        f'hud_style = "{_escape_basic_string(str(values.get("experience", {}).get("hud_style", "mini")))}"',
        f'hud_position = "{_escape_basic_string(str(values.get("experience", {}).get("hud_position", "bottom")))}"',
        f'show_idle_hud = {_toml_bool(values.get("experience", {}).get("show_idle_hud", False))}',
        f'idle_hud_user_set = {_toml_bool(values.get("experience", {}).get("idle_hud_user_set", False))}',
        f'onboarding_dismissed = {_toml_bool(values.get("experience", {}).get("onboarding_dismissed", False))}',
        f'close_to_tray = {_toml_bool(values.get("experience", {}).get("close_to_tray", True))}',
        f'dark_mode = {_toml_bool(values.get("experience", {}).get("dark_mode", True))}',
        "",
        "[startup]",
        f'launch_at_login = {_toml_bool(values.get("startup", {}).get("launch_at_login", True))}',
        f'start_minimized = {_toml_bool(values.get("startup", {}).get("start_minimized", True))}',
        f'prompt_completed = {_toml_bool(values.get("startup", {}).get("prompt_completed", False))}',
        "",
        "[history]",
        f'max_items = {int(values.get("history", {}).get("max_items", 40))}',
        f'persist = {_toml_bool(values.get("history", {}).get("persist", True))}',
        "",
    ]
    return "\n".join(lines)


def _escape_basic_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _escape_multiline_string(value: str) -> str:
    escaped = value.replace('"""', '\\"\\"\\"').rstrip()
    return f'"""{escaped}"""'


def _toml_bool(value: Any) -> str:
    return "true" if bool(value) else "false"


def _safe_shortcut_value(action: str, value: str) -> str:
    try:
        return validate_shortcut_for_action(action, value)
    except ValueError:
        if action == "repaste_last":
            return RECOMMENDED_SHORTCUTS["repaste_last"]
        return RECOMMENDED_SHORTCUTS[action]


def _normalize_cleanup_defaults(merged: dict[str, Any]) -> bool:
    cleanup = merged.setdefault("cleanup", {})
    provider = str(cleanup.get("provider", "none")).strip().lower()
    model = str(cleanup.get("model", "")).strip()
    if provider in {"none", "ollama"}:
        return False

    from flowtype.catalog import cleanup_model_cards

    model_cards = cleanup_model_cards(provider)
    if not model_cards:
        return False

    preferred_identifier = ""
    if provider == "openrouter":
        for card in model_cards:
            if card.get("identifier") != "openrouter/free":
                preferred_identifier = str(card.get("identifier", "")).strip()
                break
    if not preferred_identifier:
        preferred_identifier = str(model_cards[0].get("identifier", "")).strip()

    if not model or (provider == "openrouter" and model == "openrouter/free"):
        cleanup["model"] = preferred_identifier
        return True
    return False
