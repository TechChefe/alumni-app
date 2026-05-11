"""
Tiny dict -> XML serializer used for the JSON/XML content-negotiated
search endpoint.

We hand-roll this rather than pulling in a library: the data shapes are
fixed and small, and the assignment rewards understanding of what's
happening at every step.
"""
from xml.sax.saxutils import escape


def _emit(value, tag: str, parts: list) -> None:
    if value is None:
        parts.append(f"<{tag}/>")
        return
    if isinstance(value, dict):
        parts.append(f"<{tag}>")
        for k, v in value.items():
            _emit(v, str(k), parts)
        parts.append(f"</{tag}>")
        return
    if isinstance(value, (list, tuple)):
        parts.append(f"<{tag}>")
        for v in value:
            _emit(v, "item", parts)
        parts.append(f"</{tag}>")
        return
    if isinstance(value, bool):
        parts.append(f"<{tag}>{'true' if value else 'false'}</{tag}>")
        return
    parts.append(f"<{tag}>{escape(str(value))}</{tag}>")


def to_xml(data, root: str = "response") -> str:
    parts = ['<?xml version="1.0" encoding="UTF-8"?>']
    _emit(data, root, parts)
    return "".join(parts)
