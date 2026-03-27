from __future__ import annotations

import os
import subprocess
import sys
import tkinter as tk
import tkinter.font as tkfont
from pathlib import Path
from tkinter import messagebox

from flowtype.config import AppConfig, load_config, save_config_data


PALETTE = {
    "background": "#f4efe7",
    "surface": "#fffaf2",
    "surface_alt": "#f0e7db",
    "ink": "#18181b",
    "muted": "#5f6673",
    "accent": "#0f62fe",
    "accent_soft": "#dbe7ff",
    "success": "#177245",
    "warning": "#c97a00",
    "border": "#dfd3c2",
}

DEFAULT_MODEL_BY_PROVIDER = {
    "openrouter": "openai/gpt-4o-mini",
    "openai": "gpt-4o-mini",
    "anthropic": "claude-3-7-sonnet-latest",
    "gemini": "gemini-2.5-flash",
    "xai": "grok-3-fast",
    "groq": "llama-3.1-8b-instant",
    "ollama": "llama3.1:8b",
    "none": "",
}

PROVIDER_LABELS = {
    "openrouter": "OpenRouter",
    "openai": "OpenAI",
    "anthropic": "Claude",
    "gemini": "Gemini",
    "xai": "Grok",
    "groq": "Groq",
    "ollama": "Ollama",
    "none": "Raw Transcript",
}

PASTE_LABELS = {
    "ctrl_v": "Auto Paste",
    "clipboard_only": "Clipboard Only",
}


def build_settings_command(config_path: Path) -> list[str]:
    config_argument = str(config_path)
    if getattr(sys, "frozen", False):
        return [sys.executable, "--settings", "--config", config_argument]
    return [sys.executable, "-m", "flowtype", "--settings", "--config", config_argument]


def launch_settings_process(config_path: Path) -> None:
    subprocess.Popen(build_settings_command(config_path), close_fds=True)


def open_settings_window(config_path: str | Path | None = None) -> int:
    window = SettingsWindow(load_config(config_path))
    return window.run()


class SettingsWindow:
    def __init__(self, config: AppConfig) -> None:
        self.config = config
        self.root = tk.Tk()
        self.root.title("FlowType Settings")
        self.root.geometry("1040x680")
        self.root.minsize(980, 640)
        self.root.configure(bg=PALETTE["background"])
        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_columnconfigure(1, weight=1)
        self.root.grid_rowconfigure(0, weight=1)

        self._result = 0
        self._fonts = {}
        self._provider_buttons: dict[str, tk.Button] = {}
        self._paste_buttons: dict[str, tk.Button] = {}
        self._hero_value_labels: dict[str, tk.Label] = {}

        self.provider_var = tk.StringVar(value=config.cleanup.provider)
        self.api_key_var = tk.StringVar(value=config.cleanup.api_key)
        self.model_var = tk.StringVar(value=config.cleanup.model)
        self.hotkey_var = tk.StringVar(value=config.general.hotkey)
        self.paste_method_var = tk.StringVar(value=config.output.paste_method)
        self.restore_clipboard_var = tk.BooleanVar(value=config.output.restore_clipboard)
        self.notice_var = tk.StringVar(value=self._build_notice_text())
        self.status_title_var = tk.StringVar(value=self._build_status_title())
        self.api_key_visible = False

        self.api_key_var.trace_add("write", self._handle_api_key_change)
        self.hotkey_var.trace_add("write", self._handle_hotkey_change)
        self.model_var.trace_add("write", self._handle_model_change)

        self._build_fonts()
        self._build_layout()
        self._center_window()
        self._sync_provider_state()
        self._sync_paste_state()

    def run(self) -> int:
        self.root.mainloop()
        return self._result

    def _build_fonts(self) -> None:
        families = set(tkfont.families())

        def pick(*choices: str) -> str:
            for choice in choices:
                if choice in families:
                    return choice
            return "Segoe UI"

        heading_family = pick("Aptos Display", "Bahnschrift SemiBold", "Segoe UI Semibold")
        body_family = pick("Aptos", "Segoe UI Variable Text", "Segoe UI")

        self._fonts["hero"] = tkfont.Font(family=heading_family, size=30, weight="bold")
        self._fonts["section"] = tkfont.Font(family=heading_family, size=16, weight="bold")
        self._fonts["body"] = tkfont.Font(family=body_family, size=11)
        self._fonts["small"] = tkfont.Font(family=body_family, size=10)
        self._fonts["button"] = tkfont.Font(family=body_family, size=11, weight="bold")
        self._fonts["chip"] = tkfont.Font(family=body_family, size=10, weight="bold")

    def _build_layout(self) -> None:
        left = tk.Frame(self.root, bg=PALETTE["background"], padx=30, pady=30)
        left.grid(row=0, column=0, sticky="nsew")
        left.grid_columnconfigure(0, weight=1)

        right = tk.Frame(self.root, bg=PALETTE["surface"], padx=30, pady=30, highlightthickness=1)
        right.grid(row=0, column=1, sticky="nsew", padx=(0, 24), pady=24)
        right.configure(highlightbackground=PALETTE["border"])
        right.grid_columnconfigure(0, weight=1)

        self._build_hero(left)
        self._build_form(right)

    def _build_hero(self, parent: tk.Frame) -> None:
        status_card = tk.Frame(parent, bg=PALETTE["surface_alt"], padx=24, pady=24)
        status_card.grid(row=0, column=0, sticky="ew")
        status_card.grid_columnconfigure(0, weight=1)

        tk.Label(
            status_card,
            text="FlowType",
            bg=PALETTE["surface_alt"],
            fg=PALETTE["ink"],
            font=self._fonts["section"],
        ).grid(row=0, column=0, sticky="w")

        self.status_title_label = tk.Label(
            status_card,
            textvariable=self.status_title_var,
            bg=PALETTE["surface_alt"],
            fg=PALETTE["warning"] if self._needs_api_key() else PALETTE["success"],
            font=self._fonts["chip"],
        )
        self.status_title_label.grid(row=1, column=0, sticky="w", pady=(10, 0))

        tk.Label(
            status_card,
            text="Your voice, cleaned and ready everywhere.",
            bg=PALETTE["surface_alt"],
            fg=PALETTE["ink"],
            font=self._fonts["hero"],
            wraplength=380,
            justify="left",
        ).grid(row=2, column=0, sticky="w", pady=(16, 0))

        tk.Label(
            status_card,
            text=(
                "Inspired by the compact, menu-first setups in apps like Wispr Flow and "
                "Superwhisper: quick access, low friction, and one focused settings surface."
            ),
            bg=PALETTE["surface_alt"],
            fg=PALETTE["muted"],
            font=self._fonts["body"],
            wraplength=380,
            justify="left",
        ).grid(row=3, column=0, sticky="w", pady=(16, 0))

        chips = tk.Frame(parent, bg=PALETTE["background"])
        chips.grid(row=1, column=0, sticky="ew", pady=(20, 0))
        chips.grid_columnconfigure((0, 1), weight=1)

        self._hero_chip(chips, 0, 0, "Hotkey", self.hotkey_var.get(), "hotkey")
        self._hero_chip(chips, 0, 1, "Local Model", self.config.transcription.model_size, "model")
        self._hero_chip(chips, 1, 0, "Cleanup", PROVIDER_LABELS[self.provider_var.get()], "cleanup")
        self._hero_chip(chips, 1, 1, "Paste", PASTE_LABELS[self.paste_method_var.get()], "paste")

        steps = tk.Frame(parent, bg=PALETTE["background"], pady=18)
        steps.grid(row=2, column=0, sticky="ew")
        steps.grid_columnconfigure(0, weight=1)

        tk.Label(
            steps,
            text="How it feels",
            bg=PALETTE["background"],
            fg=PALETTE["ink"],
            font=self._fonts["section"],
        ).grid(row=0, column=0, sticky="w", pady=(16, 10))

        for index, line in enumerate(
            [
                "1. Hold your global hotkey to start dictation.",
                "2. Speak naturally while Faster-Whisper runs locally.",
                "3. Release to clean, punctuate, and paste into the active app.",
            ],
            start=1,
        ):
            card = tk.Frame(parent, bg=PALETTE["surface"], padx=18, pady=16, highlightthickness=1)
            card.configure(highlightbackground=PALETTE["border"])
            card.grid(row=2 + index, column=0, sticky="ew", pady=(0, 12))
            tk.Label(
                card,
                text=line,
                bg=PALETTE["surface"],
                fg=PALETTE["ink"],
                font=self._fonts["body"],
                wraplength=380,
                justify="left",
            ).pack(anchor="w")

    def _build_form(self, parent: tk.Frame) -> None:
        tk.Label(
            parent,
            text="Settings",
            bg=PALETTE["surface"],
            fg=PALETTE["ink"],
            font=self._fonts["section"],
        ).grid(row=0, column=0, sticky="w")

        tk.Label(
            parent,
            textvariable=self.notice_var,
            bg=PALETTE["surface"],
            fg=PALETTE["muted"],
            font=self._fonts["body"],
            wraplength=430,
            justify="left",
        ).grid(row=1, column=0, sticky="w", pady=(8, 24))

        self._build_provider_section(parent, row=2)
        self._build_entry_row(parent, row=3, label="API key", variable=self.api_key_var, masked=True)
        self._build_entry_row(parent, row=4, label="Model", variable=self.model_var)
        self._build_entry_row(parent, row=5, label="Hotkey", variable=self.hotkey_var)
        self._build_paste_section(parent, row=6)
        self._build_restore_toggle(parent, row=7)
        self._build_actions(parent, row=8)

    def _build_provider_section(self, parent: tk.Frame, row: int) -> None:
        self._section_label(parent, row, "Cleanup provider")
        bar = tk.Frame(parent, bg=PALETTE["surface"])
        bar.grid(row=row, column=0, sticky="ew", pady=(28, 0))
        bar.grid_columnconfigure((0, 1, 2), weight=1)

        for column, value in enumerate(("openrouter", "openai", "none")):
            button = tk.Button(
                bar,
                text=PROVIDER_LABELS[value],
                command=lambda selected=value: self._select_provider(selected),
                relief="flat",
                bd=0,
                padx=14,
                pady=12,
                cursor="hand2",
                font=self._fonts["button"],
            )
            button.grid(row=0, column=column, sticky="ew", padx=(0 if column == 0 else 8, 0))
            self._provider_buttons[value] = button

        tk.Label(
            parent,
            text="Choose a cleanup provider or stay fully local with raw transcript mode.",
            bg=PALETTE["surface"],
            fg=PALETTE["muted"],
            font=self._fonts["small"],
        ).grid(row=row, column=0, sticky="w", pady=(78, 0))

    def _build_entry_row(
        self,
        parent: tk.Frame,
        row: int,
        label: str,
        variable: tk.StringVar,
        masked: bool = False,
    ) -> None:
        frame = tk.Frame(parent, bg=PALETTE["surface"])
        frame.grid(row=row, column=0, sticky="ew", pady=(18, 0))
        frame.grid_columnconfigure(0, weight=1)

        tk.Label(
            frame,
            text=label,
            bg=PALETTE["surface"],
            fg=PALETTE["ink"],
            font=self._fonts["chip"],
        ).grid(row=0, column=0, sticky="w", pady=(0, 8))

        entry_frame = tk.Frame(
            frame,
            bg=PALETTE["surface_alt"],
            padx=12,
            pady=10,
            highlightthickness=1,
            highlightbackground=PALETTE["border"],
        )
        entry_frame.grid(row=1, column=0, sticky="ew")
        entry_frame.grid_columnconfigure(0, weight=1)

        entry = tk.Entry(
            entry_frame,
            textvariable=variable,
            relief="flat",
            bd=0,
            bg=PALETTE["surface_alt"],
            fg=PALETTE["ink"],
            insertbackground=PALETTE["ink"],
            font=self._fonts["body"],
            show="*" if masked and not self.api_key_visible else "",
        )
        entry.grid(row=0, column=0, sticky="ew")

        if masked:
            self.api_key_entry = entry
            toggle = tk.Button(
                entry_frame,
                text="Show",
                command=self._toggle_api_key_visibility,
                relief="flat",
                bd=0,
                bg=PALETTE["surface_alt"],
                fg=PALETTE["accent"],
                activebackground=PALETTE["surface_alt"],
                activeforeground=PALETTE["accent"],
                cursor="hand2",
                font=self._fonts["chip"],
            )
            toggle.grid(row=0, column=1, padx=(10, 0))
        elif label == "Model":
            self.model_entry = entry

    def _build_paste_section(self, parent: tk.Frame, row: int) -> None:
        self._section_label(parent, row, "Delivery mode")
        bar = tk.Frame(parent, bg=PALETTE["surface"])
        bar.grid(row=row, column=0, sticky="ew", pady=(28, 0))
        bar.grid_columnconfigure((0, 1), weight=1)

        for column, value in enumerate(("ctrl_v", "clipboard_only")):
            button = tk.Button(
                bar,
                text=PASTE_LABELS[value],
                command=lambda selected=value: self._select_paste_mode(selected),
                relief="flat",
                bd=0,
                padx=14,
                pady=12,
                cursor="hand2",
                font=self._fonts["button"],
            )
            button.grid(row=0, column=column, sticky="ew", padx=(0 if column == 0 else 8, 0))
            self._paste_buttons[value] = button

    def _build_restore_toggle(self, parent: tk.Frame, row: int) -> None:
        frame = tk.Frame(parent, bg=PALETTE["surface"], pady=18)
        frame.grid(row=row, column=0, sticky="ew")

        checkbox = tk.Checkbutton(
            frame,
            text="Restore previous clipboard after pasting",
            variable=self.restore_clipboard_var,
            onvalue=True,
            offvalue=False,
            bg=PALETTE["surface"],
            fg=PALETTE["ink"],
            activebackground=PALETTE["surface"],
            activeforeground=PALETTE["ink"],
            selectcolor=PALETTE["surface"],
            font=self._fonts["body"],
        )
        checkbox.pack(anchor="w")

        tk.Label(
            frame,
            text="This waits a little longer before restoring clipboard content for safer pastes in heavier apps.",
            bg=PALETTE["surface"],
            fg=PALETTE["muted"],
            font=self._fonts["small"],
            wraplength=430,
            justify="left",
        ).pack(anchor="w", pady=(6, 0))

    def _build_actions(self, parent: tk.Frame, row: int) -> None:
        frame = tk.Frame(parent, bg=PALETTE["surface"], pady=18)
        frame.grid(row=row, column=0, sticky="ew")
        frame.grid_columnconfigure(0, weight=1)

        button_row = tk.Frame(frame, bg=PALETTE["surface"])
        button_row.pack(anchor="w")

        save_button = tk.Button(
            button_row,
            text="Save Settings",
            command=self._save,
            relief="flat",
            bd=0,
            bg=PALETTE["accent"],
            fg="white",
            activebackground=PALETTE["accent"],
            activeforeground="white",
            cursor="hand2",
            padx=20,
            pady=12,
            font=self._fonts["button"],
        )
        save_button.pack(side="left")

        close_button = tk.Button(
            button_row,
            text="Save and Close",
            command=self._save_and_close,
            relief="flat",
            bd=0,
            bg=PALETTE["surface_alt"],
            fg=PALETTE["ink"],
            activebackground=PALETTE["surface_alt"],
            activeforeground=PALETTE["ink"],
            cursor="hand2",
            padx=18,
            pady=12,
            font=self._fonts["button"],
        )
        close_button.pack(side="left", padx=(10, 0))

        utility_row = tk.Frame(frame, bg=PALETTE["surface"])
        utility_row.pack(anchor="w", pady=(18, 0))

        for label, callback in (
            ("Open App Folder", lambda: self._open_path(self.config.general.app_dir)),
            ("Open Logs", lambda: self._open_path(self.config.general.log_file.parent)),
            ("Open Config File", lambda: self._open_path(self.config.config_path)),
        ):
            button = tk.Button(
                utility_row,
                text=label,
                command=callback,
                relief="flat",
                bd=0,
                bg=PALETTE["surface"],
                fg=PALETTE["accent"],
                activebackground=PALETTE["surface"],
                activeforeground=PALETTE["accent"],
                cursor="hand2",
                padx=0,
                pady=4,
                font=self._fonts["chip"],
            )
            button.pack(side="left", padx=(0, 18))

    def _section_label(self, parent: tk.Frame, row: int, text: str) -> None:
        tk.Label(
            parent,
            text=text,
            bg=PALETTE["surface"],
            fg=PALETTE["ink"],
            font=self._fonts["chip"],
        ).grid(row=row, column=0, sticky="w")

    def _hero_chip(
        self,
        parent: tk.Frame,
        row: int,
        column: int,
        title: str,
        value: str,
        key: str,
    ) -> None:
        card = tk.Frame(parent, bg=PALETTE["surface"], padx=16, pady=14, highlightthickness=1)
        card.configure(highlightbackground=PALETTE["border"])
        card.grid(row=row, column=column, sticky="ew", padx=(0 if column == 0 else 8, 0), pady=(0, 8))

        tk.Label(
            card,
            text=title,
            bg=PALETTE["surface"],
            fg=PALETTE["muted"],
            font=self._fonts["small"],
        ).pack(anchor="w")
        value_label = tk.Label(
            card,
            text=value,
            bg=PALETTE["surface"],
            fg=PALETTE["ink"],
            font=self._fonts["chip"],
        )
        value_label.pack(anchor="w", pady=(6, 0))
        self._hero_value_labels[key] = value_label

    def _select_provider(self, provider: str) -> None:
        self.provider_var.set(provider)
        current_model = self.model_var.get().strip()
        if not current_model or current_model in DEFAULT_MODEL_BY_PROVIDER.values():
            self.model_var.set(DEFAULT_MODEL_BY_PROVIDER[provider])
        self.notice_var.set(self._build_notice_text())
        self._refresh_status_title()
        self._sync_provider_state()
        if cleanup_label := self._hero_value_labels.get("cleanup"):
            cleanup_label.configure(text=PROVIDER_LABELS[provider])

    def _select_paste_mode(self, mode: str) -> None:
        self.paste_method_var.set(mode)
        self.notice_var.set(self._build_notice_text())
        self._sync_paste_state()
        if paste_label := self._hero_value_labels.get("paste"):
            paste_label.configure(text=PASTE_LABELS[mode])

    def _handle_api_key_change(self, *_args) -> None:
        self.notice_var.set(self._build_notice_text())
        self._refresh_status_title()

    def _handle_hotkey_change(self, *_args) -> None:
        if hotkey_label := self._hero_value_labels.get("hotkey"):
            hotkey_label.configure(text=self.hotkey_var.get().strip() or "Not set")

    def _handle_model_change(self, *_args) -> None:
        if model_label := self._hero_value_labels.get("model"):
            model_label.configure(text=self.model_var.get().strip() or "Default")

    def _sync_provider_state(self) -> None:
        active = self.provider_var.get()
        for value, button in self._provider_buttons.items():
            is_active = value == active
            button.configure(
                bg=PALETTE["accent"] if is_active else PALETTE["surface_alt"],
                fg="white" if is_active else PALETTE["ink"],
                activebackground=PALETTE["accent"] if is_active else PALETTE["surface_alt"],
                activeforeground="white" if is_active else PALETTE["ink"],
            )

        is_none = active == "none"
        state = "disabled" if is_none else "normal"
        self.api_key_entry.configure(state=state)
        self.model_entry.configure(state=state)

    def _sync_paste_state(self) -> None:
        active = self.paste_method_var.get()
        for value, button in self._paste_buttons.items():
            is_active = value == active
            button.configure(
                bg=PALETTE["accent_soft"] if is_active else PALETTE["surface_alt"],
                fg=PALETTE["accent"] if is_active else PALETTE["ink"],
                activebackground=PALETTE["accent_soft"] if is_active else PALETTE["surface_alt"],
                activeforeground=PALETTE["accent"] if is_active else PALETTE["ink"],
            )

    def _toggle_api_key_visibility(self) -> None:
        self.api_key_visible = not self.api_key_visible
        self.api_key_entry.configure(show="" if self.api_key_visible else "*")

    def _save(self) -> None:
        provider = self.provider_var.get().strip()
        api_key = self.api_key_var.get().strip()
        model = self.model_var.get().strip() or DEFAULT_MODEL_BY_PROVIDER.get(provider, "")
        hotkey = self.hotkey_var.get().strip()

        if not hotkey:
            messagebox.showerror("Missing hotkey", "Please enter a hotkey such as ctrl+shift+space.")
            return

        if provider != "none" and not api_key:
            confirmed = messagebox.askyesno(
                "Save without API key?",
                "No API key is set. FlowType will still work, but it will paste the raw transcript. Save anyway?",
            )
            if not confirmed:
                return

        values = {
            "general": {
                "hotkey": hotkey,
                "log_level": self.config.general.log_level,
            },
            "shortcuts": {
                "hold_to_talk": hotkey,
                "toggle_recording": self.config.shortcuts.toggle_recording,
                "cancel_recording": self.config.shortcuts.cancel_recording,
                "repaste_last": self.config.shortcuts.repaste_last,
            },
            "mode": {
                "active": self.config.mode.active,
                "custom_prompt": self.config.mode.custom_prompt,
            },
            "vocabulary": {
                "entries": self.config.vocabulary.text,
            },
            "audio": {
                "sample_rate": self.config.audio.sample_rate,
                "channels": self.config.audio.channels,
                "dtype": self.config.audio.dtype,
                "max_duration_seconds": self.config.audio.max_duration_seconds,
                "min_duration_ms": self.config.audio.min_duration_ms,
            },
            "transcription": {
                "model_size": self.config.transcription.model_size,
                "device": self.config.transcription.device,
                "compute_type": self.config.transcription.compute_type,
                "language": self.config.transcription.language,
                "beam_size": self.config.transcription.beam_size,
                "vad_filter": self.config.transcription.vad_filter,
            },
            "cleanup": {
                "provider": provider,
                "api_key": api_key,
                "model": model,
                "temperature": self.config.cleanup.temperature,
                "max_tokens": self.config.cleanup.max_tokens,
                "timeout_seconds": self.config.cleanup.timeout_seconds,
                "max_retries": self.config.cleanup.max_retries,
                "retry_backoff_seconds": self.config.cleanup.retry_backoff_seconds,
                "min_word_count": self.config.cleanup.min_word_count,
                "prompt": self.config.cleanup.prompt,
            },
            "output": {
                "paste_method": self.paste_method_var.get().strip(),
                "paste_delay_ms": self.config.output.paste_delay_ms,
                "restore_clipboard": bool(self.restore_clipboard_var.get()),
            },
            "experience": {
                "hud_style": self.config.experience.hud_style,
                "show_idle_hud": self.config.experience.show_idle_hud,
                "close_to_tray": self.config.experience.close_to_tray,
                "onboarding_dismissed": self.config.experience.onboarding_dismissed,
            },
            "startup": {
                "launch_at_login": self.config.startup.launch_at_login,
                "start_minimized": self.config.startup.start_minimized,
                "prompt_completed": self.config.startup.prompt_completed,
            },
            "history": {
                "max_items": self.config.history.max_items,
                "persist": self.config.history.persist,
            },
        }

        try:
            save_config_data(self.config.config_path, values)
            self.config = load_config(self.config.config_path)
            self.notice_var.set("Saved. The running app will reload these settings automatically.")
            self._refresh_status_title()
            if hotkey_label := self._hero_value_labels.get("hotkey"):
                hotkey_label.configure(text=hotkey)
        except Exception as exc:
            messagebox.showerror("Save failed", str(exc))
            return

    def _save_and_close(self) -> None:
        self._save()
        if self.notice_var.get().startswith("Saved."):
            self.root.destroy()

    def _build_status_title(self) -> str:
        if self._needs_api_key():
            return "Needs cleanup key"
        if self.provider_var.get() == "none":
            return "Local-only mode"
        return "Ready for dictated cleanup"

    def _build_notice_text(self) -> str:
        if self._needs_api_key():
            return "Add an API key here to enable cleanup, punctuation, and filler-word removal."
        if self.provider_var.get() == "none":
            return "FlowType will stay local and paste the raw Faster-Whisper transcript."
        return "Settings save directly to your FlowType config. The running app can reload them without editing TOML."

    def _needs_api_key(self) -> bool:
        return self.provider_var.get() != "none" and not self.api_key_var.get().strip()

    def _refresh_status_title(self) -> None:
        self.status_title_var.set(self._build_status_title())
        self.status_title_label.configure(
            fg=PALETTE["warning"] if self._needs_api_key() else PALETTE["success"]
        )

    def _center_window(self) -> None:
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() - width) // 2
        y = (self.root.winfo_screenheight() - height) // 3
        self.root.geometry(f"{width}x{height}+{x}+{y}")

    def _open_path(self, path: Path) -> None:
        try:
            os.startfile(str(path))  # type: ignore[attr-defined]
        except Exception as exc:
            messagebox.showerror("Open failed", f"Could not open {path}: {exc}")
