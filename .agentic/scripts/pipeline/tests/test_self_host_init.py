"""Unit testy self_host_init.py — deterministický seed PRODUCT vrstvy (self-host).

Generovaný project-config MUSÍ projít structure_check (skript a validátor jsou inverze)."""
import self_host_init as shi
import structure_check as sc
from graph import Graph, make_node


def _graph() -> Graph:
    nodes = {
        "product": make_node("product", {"type": "agent", "agent": "vision-po"}),
        "intake": make_node("intake", {"type": "router"}),          # bez agenta → ne role
        "backend": make_node("backend", {"type": "agent", "agent": "bob"}),
        "qa": make_node("qa", {"type": "gate", "agent": "joey"}),   # gate s agentem → role
    }
    return Graph(nodes, [], {}, {})


def test_derive_roles_only_agent_nodes():
    assert set(shi.derive_roles(_graph())) == {"product", "backend", "qa"}   # intake (router) vyřazen


def test_generated_config_passes_section_check():
    secs = sc.parse_sections(shi.project_config_md("x", ["product", "backend"]))
    assert sc.check_sections(secs) == []          # všechny required sekce přítomné


def test_generated_config_self_host_type():
    secs = sc.parse_sections(shi.project_config_md("x", ["product"]))
    assert sc.section(secs, "Projekt")["project_type"] == "self-host"


def test_generated_config_active_roles_passes_s4():
    secs = sc.parse_sections(shi.project_config_md("x", ["product", "backend"]))
    assert sc.check_active_roles(secs, _graph()) == []   # role ∈ graf, stav active


def test_generated_config_paths_keys_present():
    secs = sc.parse_sections(shi.project_config_md("x", ["product"]))
    paths = sc.section(secs, "Fyzické cesty")
    for key in sc.REQUIRED_PATHS:
        assert key in paths


def test_generated_constitution_has_vize_section():
    assert "## Vize a mise" in shi.project_constitution_md("x")
