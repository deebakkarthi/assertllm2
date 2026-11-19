from __future__ import annotations

import html
import re
import subprocess
import zipfile
from pathlib import Path
from typing import Iterable


SPEC_INPUT_SOURCE_VALUES = ("spec_md", "raw")
RAW_SPEC_SUFFIXES = (".pdf", ".docx", ".odt", ".txt", ".md")
_RAW_SPEC_SUFFIX_RANK = {
    ".pdf": 0,
    ".docx": 1,
    ".odt": 2,
    ".txt": 3,
    ".md": 4,
}


def resolve_spec_input_source(spec_input_source: str | None) -> str:
    source = str(spec_input_source or "spec_md").strip().lower()
    if source not in SPEC_INPUT_SOURCE_VALUES:
        raise ValueError(
            "Invalid spec_input_source='{}'; supported values are {}".format(
                source,
                list(SPEC_INPUT_SOURCE_VALUES),
            )
        )
    return source


def _resolve_path(p: str | Path) -> Path:
    return Path(p).expanduser().resolve(strict=False)


def _raw_spec_sort_key(path: Path) -> tuple[int, str]:
    return (_RAW_SPEC_SUFFIX_RANK.get(path.suffix.lower(), 99), path.name.lower())


def _is_curated_spec_md(path: Path) -> bool:
    return path.name.lower() == "spec.md"


def apply_raw_spec_output_dir_segment(cfg: dict) -> None:
    out = cfg.get("output_dir")
    if not out:
        return
    p = Path(str(out))
    if p.name == "_pdf":
        return
    cfg["output_dir"] = str(p / "_pdf")


def resolve_raw_spec_files_from_config(cfg: dict) -> list[str]:
    spec_files = [
        str(p).strip()
        for p in (cfg.get("spec_file") or [])
        if str(p).strip()
    ]
    if not spec_files:
        raise ValueError("spec_input_source='raw' requires non-empty config spec_file")

    anchor = _resolve_path(spec_files[0])
    spec_dir = anchor.parent
    if not spec_dir.is_dir():
        raise FileNotFoundError(f"Raw spec directory does not exist: {spec_dir}")

    candidates = [
        p
        for p in spec_dir.iterdir()
        if p.is_file()
        and p.suffix.lower() in RAW_SPEC_SUFFIXES
        and not _is_curated_spec_md(p)
    ]
    if not candidates:
        raise FileNotFoundError(f"No raw spec files found under: {spec_dir}")

    return [str(p) for p in sorted(candidates, key=_raw_spec_sort_key)]


def _read_text_file_robust(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except Exception:
        return path.read_text(encoding="latin-1", errors="ignore")


def _extract_zip_xml_text(path: Path, inner_name: str) -> str:
    with zipfile.ZipFile(path) as zf:
        xml = zf.read(inner_name).decode("utf-8", errors="ignore")
    xml = re.sub(r"<w:tab\s*/>", "\t", xml, flags=re.IGNORECASE)
    xml = re.sub(r"<(?:w:br|br)\s*/>", "\n", xml, flags=re.IGNORECASE)
    xml = re.sub(r"</(?:w:p|w:tr|w:tbl|text:p|text:h)>", "\n", xml, flags=re.IGNORECASE)
    xml = re.sub(r"<[^>]+>", " ", xml)
    xml = html.unescape(xml)
    xml = re.sub(r"[ \t]+\n", "\n", xml)
    xml = re.sub(r"\n{3,}", "\n\n", xml)
    return xml.strip()


def _load_text_from_pdf(path: Path) -> str:
    try:
        import fitz  # type: ignore

        doc = fitz.open(path)
        try:
            text = "\n".join(page.get_text() for page in doc)
        finally:
            doc.close()
        if text.strip():
            return text
    except Exception:
        pass

    try:
        proc = subprocess.run(
            ["pdftotext", "-layout", str(path), "-"],
            check=False,
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            return proc.stdout
    except Exception:
        pass

    raw = path.read_bytes()
    return raw.decode("latin-1", errors="ignore")


def load_text_from_spec_path(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        return _load_text_from_pdf(path)
    if suffix == ".docx":
        return _extract_zip_xml_text(path, "word/document.xml")
    if suffix == ".odt":
        return _extract_zip_xml_text(path, "content.xml")
    return _read_text_file_robust(path)


def load_spec_text_from_paths(spec_paths: Iterable[str]) -> str:
    parts: list[str] = []
    for raw_path in spec_paths:
        if not str(raw_path).strip():
            continue
        path = Path(str(raw_path)).expanduser()
        if not path.exists():
            continue
        text = load_text_from_spec_path(path)
        if text and text.strip():
            parts.append(text.strip())
    return "\n\n---\n\n".join(parts) if parts else ""
